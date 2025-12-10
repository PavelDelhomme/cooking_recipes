import 'ingredient_cleaner.dart';

class IngredientSuggestions {
  // Suggestions d'unités basées sur le nom de l'ingrédient
  static List<String> getSuggestedUnits(String ingredientName) {
    final name = ingredientName.toLowerCase();
    
    // Viandes et poissons
    if (name.contains('steak') || 
        name.contains('viande') || 
        name.contains('poulet') || 
        name.contains('boeuf') ||
        name.contains('porc') ||
        name.contains('poisson') ||
        name.contains('saumon') ||
        name.contains('thon')) {
      return ['pièce', 'g', 'kg', 'tranche', 'portion'];
    }
    
    // Pâtes, riz, céréales
    if (name.contains('pâte') || 
        name.contains('riz') || 
        name.contains('quinoa') ||
        name.contains('couscous') ||
        name.contains('boulgour') ||
        name.contains('semoule')) {
      return ['g', 'kg', 'paquet', 'portion'];
    }
    
    // Légumes
    if (name.contains('tomate') || 
        name.contains('carotte') || 
        name.contains('oignon') ||
        name.contains('poivron') ||
        name.contains('courgette') ||
        name.contains('aubergine') ||
        name.contains('pomme de terre')) {
      return ['pièce', 'g', 'kg', 'unité'];
    }
    
    // Fruits
    if (name.contains('pomme') || 
        name.contains('banane') || 
        name.contains('orange') ||
        name.contains('citron') ||
        name.contains('fraise') ||
        name.contains('fruit')) {
      return ['pièce', 'g', 'kg', 'unité'];
    }
    
    // Produits laitiers
    if (name.contains('lait') || 
        name.contains('crème') || 
        name.contains('yaourt') ||
        name.contains('fromage') ||
        name.contains('beurre')) {
      return ['ml', 'l', 'cl', 'g', 'kg', 'pot', 'tranche', 'portion'];
    }
    
    // Épices et herbes
    if (name.contains('sel') || 
        name.contains('poivre') || 
        name.contains('herbe') ||
        name.contains('épice') ||
        name.contains('ail') ||
        name.contains('oignon') ||
        name.contains('échalote')) {
      return ['pincée', 'cuillère à café', 'cuillère à soupe', 'gousse', 'tête', 'branche'];
    }
    
    // Farine, sucre, etc.
    if (name.contains('farine') || 
        name.contains('sucre') || 
        name.contains('sel') ||
        name.contains('levure')) {
      return ['g', 'kg', 'cuillère à soupe', 'cuillère à café'];
    }
    
    // Huiles et vinaigres
    if (name.contains('huile') || 
        name.contains('vinaigre')) {
      return ['ml', 'cl', 'l', 'cuillère à soupe', 'cuillère à café'];
    }
    
    // Œufs
    if (name.contains('œuf') || name.contains('oeuf')) {
      return ['pièce', 'unité'];
    }
    
    // Pain
    if (name.contains('pain') || name.contains('baguette')) {
      return ['tranche', 'pièce', 'unité'];
    }
    
    // Conserves
    if (name.contains('boîte') || 
        name.contains('conserve') ||
        name.contains('sachet') ||
        name.contains('paquet')) {
      return ['boîte', 'sachet', 'paquet', 'unité'];
    }
    
    // Par défaut, retourner les unités communes
    return ['unité', 'g', 'kg', 'ml', 'l', 'pièce', 'portion'];
  }
  
  // Suggestions de noms d'ingrédients courants (nettoyés automatiquement)
  static List<String> getCommonIngredients() {
    final rawIngredients = [
      'Steak haché',
      'Pâtes',
      'Riz',
      'Tomates',
      'Oignons',
      'Ail',
      'Huile d\'olive',
      'Beurre',
      'Lait',
      'Œufs',
      'Farine',
      'Sucre',
      'Sel',
      'Poivre',
      'Poulet',
      'Saumon',
      'Fromage',
      'Pain',
      'Carottes',
      'Courgettes',
    ];
    
    // Nettoyer tous les ingrédients avant de les retourner
    return IngredientCleaner.cleanIngredientList(rawIngredients);
  }
  
  // Suggestions filtrées et nettoyées basées sur une requête
  static List<String> getFilteredSuggestions(String query) {
    final allIngredients = getCommonIngredients();
    final lowerQuery = query.trim().toLowerCase();
    
    if (lowerQuery.isEmpty) {
      return allIngredients;
    }
    
    // Filtrer et nettoyer les suggestions
    return allIngredients
        .where((ingredient) => 
            ingredient.toLowerCase().contains(lowerQuery))
        .map((ingredient) => IngredientCleaner.cleanIngredientName(ingredient))
        .where((ingredient) => ingredient.isNotEmpty)
        .toSet() // Supprimer les doublons
        .toList();
  }
}

