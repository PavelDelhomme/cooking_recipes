/// Service pour nettoyer et normaliser les noms d'ingrédients
/// Détecte et corrige automatiquement les problèmes courants
class IngredientCleaner {
  /// Nettoie et normalise un nom d'ingrédient
  static String cleanIngredientName(String name) {
    if (name.isEmpty) return name;
    
    // 1. Nettoyer les espaces multiples
    String cleaned = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // 2. Détecter et corriger les doublons de mots
    cleaned = _removeDuplicateWords(cleaned);
    
    // 3. Corriger la casse (première lettre en majuscule, reste en minuscule)
    cleaned = _fixCapitalization(cleaned);
    
    // 4. Corriger les variations communes
    cleaned = _fixCommonVariations(cleaned);
    
    // 5. Supprimer les mots redondants
    cleaned = _removeRedundantWords(cleaned);
    
    // 6. Normaliser les caractères spéciaux
    cleaned = _normalizeSpecialChars(cleaned);
    
    return cleaned.trim();
  }
  
  /// Détecte si un nom d'ingrédient semble incorrect
  static bool isLikelyIncorrect(String name) {
    if (name.isEmpty) return false;
    
    final lower = name.toLowerCase();
    
    // Détecter les doublons de mots
    final words = lower.split(' ');
    final uniqueWords = words.toSet();
    if (words.length != uniqueWords.length) {
      return true; // Mots dupliqués
    }
    
    // Détecter les patterns suspects
    if (RegExp(r'\b(oeuf|œuf|egg)\s+(oeuf|œuf|egg)', caseSensitive: false).hasMatch(lower)) {
      return true; // "Oeuf Oeuf" ou similaire
    }
    
    // Détecter les majuscules incorrectes (trop de majuscules au milieu)
    final midChars = name.substring(1, name.length > 2 ? name.length - 1 : name.length);
    final upperCount = midChars.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).length;
    if (upperCount > name.length * 0.3) {
      return true; // Trop de majuscules
    }
    
    // Détecter les mots redondants courants
    if (RegExp(r'\b(de|du|des|le|la|les)\s+(de|du|des|le|la|les)\b', caseSensitive: false).hasMatch(lower)) {
      return true; // Articles dupliqués
    }
    
    return false;
  }
  
  /// Supprime les mots dupliqués
  static String _removeDuplicateWords(String text) {
    final words = text.split(' ');
    final seen = <String>{};
    final cleaned = <String>[];
    
    for (var word in words) {
      final lower = word.toLowerCase();
      if (!seen.contains(lower)) {
        seen.add(lower);
        cleaned.add(word);
      }
    }
    
    return cleaned.join(' ');
  }
  
  /// Corrige la capitalisation (première lettre en majuscule)
  static String _fixCapitalization(String text) {
    if (text.isEmpty) return text;
    
    // Mots à garder en minuscules (articles, prépositions)
    const lowercaseWords = {
      'de', 'du', 'des', 'le', 'la', 'les', 'un', 'une',
      'et', 'ou', 'à', 'au', 'aux', 'en', 'dans', 'sur', 'sous'
    };
    
    final words = text.split(' ');
    final fixed = <String>[];
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) {
        fixed.add(word);
        continue;
      }
      
      final lower = word.toLowerCase();
      
      // Premier mot : toujours majuscule
      if (i == 0) {
        fixed.add(word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : ''));
      }
      // Mots suivants : minuscule sauf si c'est un nom propre ou un mot important
      else if (lowercaseWords.contains(lower)) {
        fixed.add(lower);
      }
      // Sinon, première lettre en majuscule
      else {
        fixed.add(word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : ''));
      }
    }
    
    return fixed.join(' ');
  }
  
  /// Corrige les variations communes
  static String _fixCommonVariations(String text) {
    String cleaned = text;
    
    // Normaliser les variations d'œuf
    cleaned = cleaned.replaceAll(RegExp(r'\b(OEuf|Oeuf|OEUF)\b', caseSensitive: false), 'Œuf');
    cleaned = cleaned.replaceAll(RegExp(r'\b(OEufs|Oeufs|OEUFS)\b', caseSensitive: false), 'Œufs');
    
    // Normaliser les variations de bœuf
    cleaned = cleaned.replaceAll(RegExp(r'\b(BOeuf|Boeuf|BOEUF)\b', caseSensitive: false), 'Bœuf');
    
    // Corriger "De Poulet" -> "de poulet" (article en minuscule)
    cleaned = cleaned.replaceAll(RegExp(r'\bDe\s+(Poulet|Poulets)\b'), 'de Poulet');
    
    // Supprimer les répétitions comme "Oeuf Oeufs"
    cleaned = cleaned.replaceAll(RegExp(r'\b(Œuf|Oeuf)\s+(Œufs|Oeufs)\b', caseSensitive: false), 'Œufs');
    cleaned = cleaned.replaceAll(RegExp(r'\b(Œufs|Oeufs)\s+(Œuf|Oeuf)\b', caseSensitive: false), 'Œufs');
    
    // Corriger "Poulet Poulet" -> "Poulet"
    cleaned = cleaned.replaceAllMapped(RegExp(r'\b(Poulet|Poulets)\s+\1\b', caseSensitive: false), (match) {
      return match.group(1)!;
    });
    
    return cleaned;
  }
  
  /// Supprime les mots redondants
  static String _removeRedundantWords(String text) {
    String cleaned = text;
    
    // Supprimer les articles redondants
    cleaned = cleaned.replaceAllMapped(RegExp(r'\b(De|Du|Des|Le|La|Les)\s+(De|Du|Des|Le|La|Les)\b', caseSensitive: false), (match) {
      return match.group(1)!; // Garder seulement le premier
    });
    
    // Supprimer "De Poulet" après "Œufs" (ex: "Œufs De Poulet" -> "Œufs")
    cleaned = cleaned.replaceAll(RegExp(r'\b(Œufs|Oeufs)\s+De\s+Poulet\b', caseSensitive: false), 'Œufs');
    
    // Supprimer les répétitions de mots identiques
    final words = cleaned.split(' ');
    final cleanedWords = <String>[];
    String? lastWord;
    
    for (var word in words) {
      if (word.toLowerCase() != lastWord?.toLowerCase()) {
        cleanedWords.add(word);
        lastWord = word;
      }
    }
    
    return cleanedWords.join(' ');
  }
  
  /// Normalise les caractères spéciaux
  static String _normalizeSpecialChars(String text) {
    // Normaliser les espaces insécables
    return text.replaceAll('\u00A0', ' ').replaceAll('\u2009', ' ');
  }
  
  /// Nettoie une liste de noms d'ingrédients
  static List<String> cleanIngredientList(List<String> ingredients) {
    return ingredients
        .map((ingredient) => cleanIngredientName(ingredient))
        .where((ingredient) => ingredient.isNotEmpty)
        .toSet() // Supprimer les doublons après nettoyage
        .toList();
  }
  
  /// Suggère une correction pour un nom d'ingrédient incorrect
  static String? suggestCorrection(String name) {
    if (!isLikelyIncorrect(name)) {
      return null; // Pas de correction nécessaire
    }
    
    final cleaned = cleanIngredientName(name);
    if (cleaned != name) {
      return cleaned;
    }
    
    return null;
  }
}

