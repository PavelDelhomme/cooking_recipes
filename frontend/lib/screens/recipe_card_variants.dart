import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/translation_service.dart';
import '../widgets/translation_builder.dart';
import '../widgets/locale_notifier.dart';

/// 5 variantes différentes de cartes pour les suggestions de recettes
class RecipeCardVariants {
  // Variante 1: Carte compacte avec image en haut, titre et badges en bas
  static Widget variant1(Recipe recipe, BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Image
          if (recipe.image != null)
            Image.network(
              recipe.image!,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              cacheWidth: 300,
            )
          else
            Container(
              width: double.infinity,
              height: 120,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Icon(Icons.restaurant, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          // Contenu
          Padding(
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
                    if (recipe.prepTimeMinutes != null)
                      Chip(
                        label: Text('${recipe.prepTimeMinutes}m', style: TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (recipe.cookTimeMinutes != null)
                      Chip(
                        label: Text('${recipe.cookTimeMinutes}m', style: TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
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
      child: SizedBox.expand(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Image à gauche
          if (recipe.image != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
              child: Image.network(recipe.image!, width: 100, height: 100, fit: BoxFit.cover, cacheWidth: 200),
            )
          else
            Container(
              width: 100,
              height: 100,
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
                  Row(
                    children: [
                      if (recipe.prepTimeMinutes != null)
                        Icon(Icons.timer, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      if (recipe.prepTimeMinutes != null) ...[
                        const SizedBox(width: 4),
                        Text('${recipe.prepTimeMinutes}m', style: TextStyle(fontSize: 11)),
                      ],
                      if (recipe.cookTimeMinutes != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.local_fire_department, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${recipe.cookTimeMinutes}m', style: TextStyle(fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
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
      child: SizedBox.expand(
        child: Stack(
          children: [
          // Image en arrière-plan
          if (recipe.image != null)
            Image.network(recipe.image!, width: double.infinity, height: 140, fit: BoxFit.cover, cacheWidth: 300)
          else
            Container(
              width: double.infinity,
              height: 140,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Icon(Icons.restaurant, size: 50, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          // Overlay sombre
          Container(
            width: double.infinity,
            height: 140,
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
                  if (recipe.readyInMinutes != null) ...[
                    const SizedBox(height: 4),
                    Text('${recipe.readyInMinutes} min', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ],
              ),
            ),
          ),
        ],
        ),
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
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Image avec badges
          Stack(
            children: [
              if (recipe.image != null)
                Image.network(recipe.image!, width: double.infinity, height: 110, fit: BoxFit.cover, cacheWidth: 300)
              else
                Container(
                  width: double.infinity,
                  height: 110,
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
                    if (recipe.prepTimeMinutes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${recipe.prepTimeMinutes}m', style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    if (recipe.cookTimeMinutes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${recipe.cookTimeMinutes}m', style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Titre
          Padding(
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
        ],
        ),
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
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Image
          if (recipe.image != null)
            Image.network(recipe.image!, width: double.infinity, height: 100, fit: BoxFit.cover, cacheWidth: 300)
          else
            Container(
              width: double.infinity,
              height: 100,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Icon(Icons.restaurant, size: 35, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          // Contenu compact
          Padding(
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
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (recipe.prepTimeMinutes != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('${recipe.prepTimeMinutes}m', style: TextStyle(fontSize: 10)),
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
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

