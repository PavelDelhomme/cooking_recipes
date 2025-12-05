import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'screens/pantry_screen.dart' show PantryScreen, PantryScreenState;
import 'screens/recipes_screen.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/shopping_list_screen.dart' show ShoppingListScreen, ShoppingListScreenState;
import 'screens/profile_screen.dart';
import 'screens/recipe_card_test_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/recipe_history_screen.dart';
import 'services/profile_service.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'services/app_localizations.dart';
import 'services/translation_service.dart';
import 'models/user_profile.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'widgets/locale_notifier.dart';

// Widget pour exposer le callback de changement de thème
class ThemeNotifier extends InheritedWidget {
  final VoidCallback toggleTheme;

  const ThemeNotifier({
    required this.toggleTheme,
    required super.child,
  });

  static ThemeNotifier? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeNotifier>();
  }

  @override
  bool updateShouldNotify(ThemeNotifier oldWidget) {
    return toggleTheme != oldWidget.toggleTheme;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialiser la locale française
  // Note: L'avertissement "Intl.v8BreakIterator is deprecated" est normal
  // car flutter_localizations dépend de intl 0.19.0 qui utilise encore cette API.
  // Cela sera corrigé dans une future version de Flutter et n'affecte pas le fonctionnement.
  Intl.defaultLocale = 'fr_FR';
  
  // Démarrer le monitoring mémoire en mode debug
  if (kDebugMode) {
    // Le monitoring mémoire sera démarré automatiquement si nécessaire
    // Voir MemoryMonitor pour plus de détails
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService();
  bool _isDarkMode = true; // Mode sombre par défaut
  Locale _locale = const Locale('fr', 'FR');

  @override
  void initState() {
    super.initState();
    // Charger le thème et la locale en parallèle pour optimiser
    _loadThemeAndLocale();
  }

  Future<void> _loadThemeAndLocale() async {
    // Charger en parallèle pour optimiser
    final results = await Future.wait([
      _themeService.isDarkMode(),
      LocaleService.getLocale(),
      TranslationService.initStatic(),
    ]);
    
    if (mounted) {
      setState(() {
        _isDarkMode = results[0] as bool;
        _locale = results[1] as Locale;
      });
    }
  }

  Future<void> _loadLocale() async {
    final locale = await LocaleService.getLocale();
    if (mounted) {
      setState(() => _locale = locale);
    }
  }

  void _changeLocale(Locale newLocale) async {
    await LocaleService.setLocale(newLocale);
    TranslationService.setLanguageStatic(newLocale.languageCode);
    if (mounted) {
      setState(() => _locale = newLocale);
    }
  }

  void _toggleTheme() async {
    final newValue = !_isDarkMode;
    // Mettre à jour l'état immédiatement pour une réponse rapide
    if (mounted) {
      setState(() {
        _isDarkMode = newValue;
      });
    }
    // Sauvegarder en arrière-plan (non bloquant)
    _themeService.setDarkMode(newValue).catchError((e) {
      if (kDebugMode) print('Erreur sauvegarde thème: $e');
    });
  }
  
  // Méthode publique pour permettre aux écrans enfants de changer le thème
  void toggleThemeFromChild() {
    _toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser un key qui change seulement pour la langue, pas pour le thème
    // Le thème change via themeMode qui est réactif au setState
    return MaterialApp(
      key: ValueKey('locale_${_locale.languageCode}'), // Force la reconstruction seulement quand la langue change
      title: 'Cooking Recipes',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // Exposer le callback de changement de thème et la locale via des InheritedWidgets
      builder: (context, child) {
        return LocaleNotifier(
          locale: _locale,
          onLocaleChange: _changeLocale,
          child: ThemeNotifier(
            toggleTheme: _toggleTheme,
            child: child ?? const SizedBox(),
          ),
        );
      },
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleService.supportedLocales,
      home: Builder(
        builder: (context) => AuthWrapper(
          onThemeToggle: () {
            _toggleTheme();
            // Forcer la reconstruction de l'app
            setState(() {});
          },
          onLocaleChange: _changeLocale,
          currentLocale: _locale,
          isDarkMode: _isDarkMode,
        ),
      ),
      routes: {
        '/home': (context) => MainScreen(
          onThemeToggle: () {
            _toggleTheme();
            setState(() {});
          },
          onLocaleChange: _changeLocale,
          currentLocale: _locale,
          isDarkMode: _isDarkMode,
        ),
        '/auth': (context) => const AuthScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final Function(Locale)? onLocaleChange;
  final Locale? currentLocale;
  final bool isDarkMode;

  const AuthWrapper({
    super.key,
    this.onThemeToggle,
    this.onLocaleChange,
    this.currentLocale,
    this.isDarkMode = false,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    // Vérifier périodiquement l'authentification
    _startAuthCheck();
  }

  void _startAuthCheck() {
    // Vérifier l'authentification toutes les 10 secondes (moins agressif)
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isAuthenticated) {
        // Vérifier seulement si on pense être authentifié
        _checkAuth();
        _startAuthCheck(); // Continuer à vérifier
      }
    });
  }

  Future<void> _checkAuth() async {
    final isAuth = await _authService.isAuthenticated();
    if (mounted) {
      final wasAuthenticated = _isAuthenticated;
      setState(() {
        _isAuthenticated = isAuth;
        _isLoading = false;
      });
      // Si l'utilisateur était connecté et ne l'est plus, forcer la reconstruction
      if (wasAuthenticated && !isAuth) {
        // L'utilisateur s'est déconnecté, l'écran sera reconstruit automatiquement
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isAuthenticated) {
      return MainScreen(
        key: ValueKey(_isAuthenticated), // Force la reconstruction si l'auth change
        onThemeToggle: widget.onThemeToggle,
        onLocaleChange: widget.onLocaleChange,
        currentLocale: widget.currentLocale,
        isDarkMode: widget.isDarkMode,
        onLogout: () async {
          // Quand l'utilisateur se déconnecte, mettre à jour l'état
          if (mounted) {
            setState(() {
              _isAuthenticated = false;
            });
            // Vérifier immédiatement pour forcer la redirection
            await _checkAuth();
          }
        },
      );
    }

    return const AuthScreen(
      key: ValueKey('auth_screen'), // Force la reconstruction
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final Function(Locale)? onLocaleChange;
  final Locale? currentLocale;
  final bool isDarkMode;
  final VoidCallback? onLogout;

  const MainScreen({
    super.key,
    this.onThemeToggle,
    this.onLocaleChange,
    this.currentLocale,
    this.isDarkMode = false,
    this.onLogout,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final ProfileService _profileService = ProfileService();
  UserProfile? _currentProfile;
  
  // GlobalKeys pour pouvoir recharger les écrans
  final GlobalKey<PantryScreenState> _pantryScreenKey = GlobalKey<PantryScreenState>();
  final GlobalKey<ShoppingListScreenState> _shoppingListScreenKey = GlobalKey<ShoppingListScreenState>();

  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Initialiser les écrans avec les keys
    _screens = [
      const RecipesScreen(),
      PantryScreen(key: _pantryScreenKey),
      ShoppingListScreen(key: _shoppingListScreenKey),
      const MealPlanScreen(),
      const ProfileScreen(),
    ];
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getCurrentProfile();
    if (mounted) {
      setState(() => _currentProfile = profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final localizations = AppLocalizations.of(context);
          return NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
              // Recharger le profil quand on change d'onglet
              _loadProfile();
              // Recharger le placard si on y accède
              if (index == 1 && _pantryScreenKey.currentState != null) {
                _pantryScreenKey.currentState!.loadItems();
              }
              // Recharger la liste de courses si on y accède
              if (index == 2 && _shoppingListScreenKey.currentState != null) {
                _shoppingListScreenKey.currentState!.loadItems();
              }
            },
            elevation: 8,
            height: 70,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.restaurant_menu_outlined),
                selectedIcon: const Icon(Icons.restaurant_menu),
                label: localizations?.recipes ?? 'Recettes',
              ),
              NavigationDestination(
                icon: const Icon(Icons.kitchen_outlined),
                selectedIcon: const Icon(Icons.kitchen),
                label: localizations?.pantry ?? 'Placard',
              ),
              NavigationDestination(
                icon: const Icon(Icons.shopping_cart_outlined),
                selectedIcon: const Icon(Icons.shopping_cart),
                label: localizations?.shoppingList ?? 'Courses',
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_today_outlined),
                selectedIcon: const Icon(Icons.calendar_today),
                label: localizations?.mealPlan ?? 'Planning',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: localizations?.profile ?? 'Profil',
              ),
            ],
          );
        },
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: Row(
          children: [
            // Image de l'application
            Image.asset(
              'assets/images/app_logo.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                // Fallback vers l'icône si l'image n'existe pas
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cooking Recipes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_currentProfile != null)
                    Text(
                      '${_currentProfile!.name} - ${_currentProfile!.numberOfPeople} ${_currentProfile!.numberOfPeople > 1 ? 'personnes' : 'personne'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 28,
            ),
            tooltip: widget.isDarkMode ? 'Mode clair' : 'Mode sombre',
            onPressed: () => widget.onThemeToggle?.call(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person, size: 28),
            tooltip: 'Profil',
            onPressed: () {
              setState(() => _selectedIndex = 4);
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.logout,
              size: 28,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'Déconnexion',
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // En-tête du drawer avec profil
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Image de l'application
                Image.asset(
                  'assets/images/app_logo.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback vers l'icône si l'image n'existe pas
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 48,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cooking Recipes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentProfile != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_currentProfile!.name} - ${_currentProfile!.numberOfPeople} ${_currentProfile!.numberOfPeople > 1 ? 'personnes' : 'personne'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Navigation
          ListTile(
            leading: Icon(
              Icons.restaurant_menu,
              color: _selectedIndex == 0
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(AppLocalizations.of(context)?.recipes ?? 'Recettes'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
              _loadProfile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.view_module),
            title: const Text('Test Variantes Cartes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecipeCardTestScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.kitchen,
              color: _selectedIndex == 1
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(AppLocalizations.of(context)?.pantry ?? 'Placard'),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
              _loadProfile();
              // Recharger le placard quand on y accède
              if (_pantryScreenKey.currentState != null) {
                _pantryScreenKey.currentState!.loadItems();
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.shopping_cart,
              color: _selectedIndex == 2
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(AppLocalizations.of(context)?.shoppingList ?? 'Courses'),
            selected: _selectedIndex == 2,
            onTap: () {
              setState(() => _selectedIndex = 2);
              Navigator.pop(context);
              _loadProfile();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.calendar_today,
              color: _selectedIndex == 3
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(AppLocalizations.of(context)?.mealPlan ?? 'Planning'),
            selected: _selectedIndex == 3,
            onTap: () {
              setState(() => _selectedIndex = 3);
              Navigator.pop(context);
              _loadProfile();
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.person,
              color: _selectedIndex == 4
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(AppLocalizations.of(context)?.profile ?? 'Profil'),
            selected: _selectedIndex == 4,
            onTap: () {
              setState(() => _selectedIndex = 4);
              Navigator.pop(context);
              _loadProfile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Mes Favoris'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historique'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecipeHistoryScreen()),
              );
            },
          ),
          const Divider(),
          // Sélection de la langue
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context)?.language ?? 'Langue'),
            subtitle: Text(
              LocaleService.languageNames[widget.currentLocale?.languageCode ?? 'fr'] ?? 'Français',
            ),
            onTap: () {
              _showLanguageDialog(context);
            },
          ),
          // Mode sombre/clair
          ListTile(
            leading: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            title: Text(
              widget.isDarkMode 
                ? (AppLocalizations.of(context)?.lightMode ?? 'Mode clair')
                : (AppLocalizations.of(context)?.darkMode ?? 'Mode sombre'),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: widget.isDarkMode,
                  onChanged: (_) => widget.onThemeToggle?.call(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    setState(() => _selectedIndex = 4);
                    Navigator.pop(context);
                  },
                  tooltip: 'Profil',
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _handleLogout(context),
                  tooltip: 'Déconnexion',
                ),
              ],
            ),
            onTap: () => widget.onThemeToggle?.call(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onLogout != null) {
      widget.onLogout!();
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.language ?? 'Langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleService.supportedLocales.map((locale) {
            final isSelected = locale.languageCode == widget.currentLocale?.languageCode;
            return RadioListTile<Locale>(
              title: Text(LocaleService.languageNames[locale.languageCode] ?? locale.languageCode),
              value: locale,
              groupValue: widget.currentLocale,
              onChanged: (value) {
                if (value != null && widget.onLocaleChange != null) {
                  widget.onLocaleChange!(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Annuler'),
          ),
        ],
      ),
    );
  }
}
