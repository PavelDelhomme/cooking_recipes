import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'screens/pantry_screen.dart' show PantryScreen, PantryScreenState;
import 'screens/recipes_screen.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/shopping_list_screen.dart' show ShoppingListScreen, ShoppingListScreenState;
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';
import 'services/profile_service.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'services/app_localizations.dart';
import 'services/translation_service.dart';
import 'models/user_profile.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';

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
  Intl.defaultLocale = 'fr_FR';
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
    _loadTheme();
    _loadLocale();
  }

  Future<void> _loadTheme() async {
    final isDark = await _themeService.isDarkMode();
    setState(() => _isDarkMode = isDark);
  }

  Future<void> _loadLocale() async {
    final locale = await LocaleService.getLocale();
    await TranslationService.init();
    if (mounted) {
      setState(() => _locale = locale);
    }
  }

  void _changeLocale(Locale newLocale) async {
    await LocaleService.setLocale(newLocale);
    TranslationService.setLanguage(newLocale.languageCode);
    if (mounted) {
      setState(() => _locale = newLocale);
    }
  }

  void _toggleTheme() async {
    final newValue = !_isDarkMode;
    await _themeService.setDarkMode(newValue);
    if (mounted) {
      // Mettre à jour le thème sans reconstruire toute l'app
      // Le MaterialApp se mettra à jour automatiquement grâce à themeMode
      setState(() {
        _isDarkMode = newValue;
      });
    }
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
      // Exposer le callback de changement de thème via un InheritedWidget
      builder: (context, child) {
        return ThemeNotifier(
          toggleTheme: _toggleTheme,
          child: child ?? const SizedBox(),
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
  }

  Future<void> _checkAuth() async {
    final isAuth = await _authService.isAuthenticated();
    setState(() {
      _isAuthenticated = isAuth;
      _isLoading = false;
    });
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
        onThemeToggle: widget.onThemeToggle,
        onLocaleChange: widget.onLocaleChange,
        currentLocale: widget.currentLocale,
        isDarkMode: widget.isDarkMode,
      );
    }

    return const AuthScreen();
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final Function(Locale)? onLocaleChange;
  final Locale? currentLocale;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    this.onThemeToggle,
    this.onLocaleChange,
    this.currentLocale,
    this.isDarkMode = false,
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
        title: Column(
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
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
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
                  Text(
                    '${_currentProfile!.name} - ${_currentProfile!.numberOfPeople} ${_currentProfile!.numberOfPeople > 1 ? 'personnes' : 'personne'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
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
            title: Text(AppLocalizations.of(context)?.shoppingList ?? 'Liste de courses'),
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
            trailing: Switch(
              value: widget.isDarkMode,
              onChanged: (_) => widget.onThemeToggle?.call(),
            ),
            onTap: () => widget.onThemeToggle?.call(),
          ),
        ],
      ),
    );
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
