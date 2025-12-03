import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'locale_notifier.dart';

/// Widget helper pour écouter les changements de langue et retraduire dynamiquement
class TranslationBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) builder;

  const TranslationBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    // Écouter à la fois LocaleNotifier (pour la reconstruction) et TranslationService (pour les notifications)
    return ListenableBuilder(
      listenable: TranslationService(),
      builder: (context, _) {
        // Écouter aussi LocaleNotifier pour forcer la reconstruction
        LocaleNotifier.of(context);
        return builder(context);
      },
    );
  }
}

