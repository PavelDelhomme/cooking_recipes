import 'package:flutter/material.dart';

/// Widget pour exposer la locale actuelle et notifier les changements
class LocaleNotifier extends InheritedWidget {
  final Locale locale;
  final VoidCallback? onLocaleChange;

  const LocaleNotifier({
    required this.locale,
    this.onLocaleChange,
    required super.child,
  });

  static LocaleNotifier? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleNotifier>();
  }

  @override
  bool updateShouldNotify(LocaleNotifier oldWidget) {
    return locale != oldWidget.locale;
  }
}

