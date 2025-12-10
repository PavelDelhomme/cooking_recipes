import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/translation_service.dart';
import '../widgets/translation_builder.dart';

/// 5 variantes différentes de cartes pour les suggestions de recettes
class RecipeCardVariants {
  // Variante 1: Carte compacte avec image en haut, titre et badges en bas
  static Widget variant1(Recipe recipe, BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            // Image
            if (recipe.image != null)
              Image.network(
                recipe.image!,
                width: double.infinity,
                height: constraints.maxHeight * 0.6,
                fit: BoxFit.cover,
                cacheWidth: 300,
              )
            else
              Container(
                width: double.infinity,
                height: constraints.maxHeight * 0.6,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Icon(Icons.restaurant, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                TranslationBuilder(
                  builder: (context) => Text(
                    TranslationService.translateRecipeNameSync(recipe.title),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (recipe.readyInMinutes != null)
                      Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 12, color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 4),
                            Text('${recipe.readyInMinutes} min', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (recipe.prepTimeMinutes != null)
                      Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant_outlined, size: 12, color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 4),
                            Text('Prép: ${recipe.prepTimeMinutes}m', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (recipe.cookTimeMinutes != null)
                      Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department_outlined, size: 12, color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 4),
                            Text('Cuisson: ${recipe.cookTimeMinutes}m', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (recipe.servings != null)
                      Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 12, color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 4),
                            Text('${recipe.servings} pers.', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
              ),
            ),
          ],
          );
        },
      ),
    );
  }

  // Variante 2: Carte avec image à gauche, titre et infos à droite (horizontal)
  static Widget variant2(Recipe recipe, BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Image à gauche
            if (recipe.image != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                child: Image.network(recipe.image!, width: constraints.maxHeight, height: constraints.maxHeight, fit: BoxFit.cover, cacheWidth: 200),
              )
            else
              Container(
                width: constraints.maxHeight,
                height: constraints.maxHeight,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Icon(Icons.restaurant, size: 30, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            // Contenu à droite
            Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TranslationBuilder(
                    builder: (context) => Text(
                      TranslationService.translateRecipeNameSync(recipe.title),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (recipe.readyInMinutes != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 4),
                            Text('${recipe.readyInMinutes} min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      if (recipe.prepTimeMinutes != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('Prép: ${recipe.prepTimeMinutes}m', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      if (recipe.cookTimeMinutes != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('Cuisson: ${recipe.cookTimeMinutes}m', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      if (recipe.servings != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('${recipe.servings} pers.', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ],
          );
        },
      ),
    );
  }

  // Variante 3: Carte avec overlay de texte sur l'image
  static Widget variant3(Recipe recipe, BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
            // Image en arrière-plan
            if (recipe.image != null)
              Image.network(recipe.image!, width: double.infinity, height: constraints.maxHeight, fit: BoxFit.cover, cacheWidth: 300)
            else
              Container(
                width: double.infinity,
                height: constraints.maxHeight,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Icon(Icons.restaurant, size: 50, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            // Overlay sombre
            Container(
              width: double.infinity,
              height: constraints.maxHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
          // Texte en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TranslationBuilder(
                    builder: (context) => Text(
                      TranslationService.translateRecipeNameSync(recipe.title),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (recipe.readyInMinutes != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('${recipe.readyInMinutes} min', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      if (recipe.prepTimeMinutes != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.restaurant_outlined, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text('Prép: ${recipe.prepTimeMinutes}m', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                      if (recipe.cookTimeMinutes != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_outlined, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text('Cuisson: ${recipe.cookTimeMinutes}m', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                      if (recipe.servings != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text('${recipe.servings} pers.', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ],
          );
        },
      ),
    );
  }

  // Variante 4: Carte avec badges colorés en haut de l'image
  static Widget variant4(Recipe recipe, BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            // Image avec badges
            Stack(
              children: [
                if (recipe.image != null)
                  Image.network(recipe.image!, width: double.infinity, height: constraints.maxHeight * 0.65, fit: BoxFit.cover, cacheWidth: 300)
                else
                  Container(
                    width: double.infinity,
                    height: constraints.maxHeight * 0.65,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Icon(Icons.restaurant, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
              // Badges en haut à droite
              Positioned(
                top: 8,
                right: 8,
                child: Wrap(
                  spacing: 4,
                  direction: Axis.vertical,
                  children: [
                    if (recipe.readyInMinutes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('${recipe.readyInMinutes} min', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    if (recipe.prepTimeMinutes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.restaurant_outlined, size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('Prép: ${recipe.prepTimeMinutes}m', style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ],
                        ),
                      ),
                    if (recipe.cookTimeMinutes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_outlined, size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('Cuisson: ${recipe.cookTimeMinutes}m', style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ],
                        ),
                      ),
                    if (recipe.servings != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('${recipe.servings} pers.', style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Titre
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: TranslationBuilder(
                builder: (context) => Text(
                  TranslationService.translateRecipeNameSync(recipe.title),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          ],
          );
        },
      ),
    );
  }

  // Variante 5: Carte minimaliste avec bordure colorée
  static Widget variant5(Recipe recipe, BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            // Image
            if (recipe.image != null)
              Image.network(recipe.image!, width: double.infinity, height: constraints.maxHeight * 0.6, fit: BoxFit.cover, cacheWidth: 300)
            else
              Container(
                width: double.infinity,
                height: constraints.maxHeight * 0.6,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Icon(Icons.restaurant, size: 35, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            // Contenu compact
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                TranslationBuilder(
                  builder: (context) => Text(
                    TranslationService.translateRecipeNameSync(recipe.title),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (recipe.readyInMinutes != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 12, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text('${recipe.readyInMinutes} min', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    if (recipe.prepTimeMinutes != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant_outlined, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('Prép: ${recipe.prepTimeMinutes}m', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    if (recipe.cookTimeMinutes != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_outlined, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('Cuisson: ${recipe.cookTimeMinutes}m', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    if (recipe.servings != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('${recipe.servings} pers.', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
              ),
            ),
          ],
          );
        },
      ),
    );
  }

  // Variante 6: Carte détaillée avec liste d'ingrédients et début d'instructions
  static Widget variant6(Recipe recipe, BuildContext context) {
    // Extraire SEULEMENT le premier ingrédient principal
    final firstIngredient = recipe.ingredients.isNotEmpty ? recipe.ingredients.first : null;
    // Extraire le début des instructions (première phrase ou 60 caractères) - traduit
    String? instructionsPreview;
    if (recipe.instructions.isNotEmpty) {
      final instructionText = TranslationService.cleanAndTranslate(recipe.instructions.first);
      final sentences = instructionText.split('.');
      if (sentences.isNotEmpty && sentences.first.trim().isNotEmpty) {
        final firstSentence = sentences.first.trim() + '.';
        // Limiter à 60 caractères pour éviter les dépassements
        instructionsPreview = firstSentence.length > 60
            ? firstSentence.substring(0, 60) + '...'
            : firstSentence;
      } else {
        // Limiter à 60 caractères max
        instructionsPreview = instructionText.length > 60
            ? instructionText.substring(0, 60) + '...'
            : instructionText;
      }
    }
    // Extraire le début du résumé si disponible - traduit
    String? summaryPreview;
    if (recipe.summary != null && recipe.summary!.isNotEmpty) {
      // Nettoyer les balises HTML d'abord
      final cleanSummary = recipe.summary!.replaceAll(RegExp(r'<[^>]*>'), '');
      final translatedSummary = TranslationService.cleanAndTranslate(cleanSummary);
      if (translatedSummary.length > 100) {
        summaryPreview = '${translatedSummary.substring(0, 100)}...';
      } else {
        summaryPreview = translatedSummary;
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0, // Pas d'élévation par défaut
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Plus arrondi
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Gérer les contraintes infinies dans GridView
          final cardHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
              ? constraints.maxHeight
              : 500.0; // Hauteur par défaut augmentée pour contenir plus de contenu
          final imageHeight = cardHeight * 0.35; // Réduire la hauteur de l'image pour laisser plus de place au contenu
          final contentHeight = cardHeight - imageHeight; // Hauteur restante pour le contenu
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image (40% de la hauteur)
              if (recipe.image != null)
                Image.network(
                  recipe.image!,
                  width: double.infinity,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                )
              else
                Container(
                  width: double.infinity,
                  height: imageHeight,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Icon(Icons.restaurant, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              // Contenu fixe (non scrollable) - 65% de la hauteur restante
              SizedBox(
                height: contentHeight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        // Titre
                        TranslationBuilder(
                          builder: (context) => Text(
                            TranslationService.translateRecipeNameSync(recipe.title),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Informations rapides (temps et portions)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (recipe.readyInMinutes != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_outlined, size: 14, color: Theme.of(context).colorScheme.onPrimaryContainer),
                                    const SizedBox(width: 4),
                                    Text('${recipe.readyInMinutes} min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                                  ],
                                ),
                              ),
                            if (recipe.prepTimeMinutes != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.restaurant_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text('Prép: ${recipe.prepTimeMinutes}m', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            if (recipe.cookTimeMinutes != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_fire_department_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text('Cuisson: ${recipe.cookTimeMinutes}m', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            if (recipe.servings != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_outline, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text('${recipe.servings} pers.', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Résumé si disponible
                        if (summaryPreview != null) ...[
                          Flexible(
                            child: Text(
                              summaryPreview,
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Premier ingrédient principal seulement - Style amélioré
                        if (firstIngredient != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.restaurant_menu,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TranslationBuilder(
                                      builder: (context) => Text(
                                        TranslationService.translateIngredientSync(firstIngredient.name),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (recipe.ingredients.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: TranslationBuilder(
                                          builder: (context) {
                                            final remaining = recipe.ingredients.length - 1;
                                            final text = TranslationService.currentLanguageStatic == 'fr'
                                                ? 'et $remaining autres...'
                                                : TranslationService.currentLanguageStatic == 'es'
                                                    ? 'y $remaining más...'
                                                    : 'and $remaining more...';
                                            return Text(
                                              text,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontStyle: FontStyle.italic,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Début des instructions - Mieux limité
                        if (instructionsPreview != null) ...[
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.list_alt,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    TranslationBuilder(
                                      builder: (context) => Text(
                                        'Instructions:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                TranslationBuilder(
                                  builder: (context) => Text(
                                    instructionsPreview!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Variante 7: Carte compacte avec aperçu des ingrédients en badges
  static Widget variant7(Recipe recipe, BuildContext context) {
    // Extraire les 3 premiers ingrédients pour les badges
    final topIngredients = recipe.ingredients.take(3).toList();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image avec overlay d'informations
              Stack(
                children: [
                  if (recipe.image != null)
                    Image.network(
                      recipe.image!,
                      width: double.infinity,
                      height: constraints.maxHeight * 0.55,
                      fit: BoxFit.cover,
                      cacheWidth: 350,
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: constraints.maxHeight * 0.55,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Icon(Icons.restaurant, size: 45, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  // Overlay avec temps total
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          if (recipe.readyInMinutes != null)
                            Text('${recipe.readyInMinutes} min', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Titre
                      TranslationBuilder(
                        builder: (context) => Text(
                          TranslationService.translateRecipeNameSync(recipe.title),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Informations rapides
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (recipe.prepTimeMinutes != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.restaurant_outlined, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text('${recipe.prepTimeMinutes}m', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          if (recipe.cookTimeMinutes != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_fire_department_outlined, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text('${recipe.cookTimeMinutes}m', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          if (recipe.servings != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text('${recipe.servings}', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Badges d'ingrédients principaux
                      if (topIngredients.isNotEmpty) ...[
                        Text(
                          'Ingrédients:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: topIngredients.map((ingredient) => Chip(
                            label: Text(
                              ingredient.name,
                              style: TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          )).toList(),
                        ),
                        if (recipe.ingredients.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+ ${recipe.ingredients.length - 3} autres',
                              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

