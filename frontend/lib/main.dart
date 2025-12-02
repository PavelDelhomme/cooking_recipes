import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'screens/pantry_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';
import 'services/profile_service.dart';
import 'services/auth_service.dart';
import 'models/user_profile.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await _themeService.isDarkMode();
    setState(() => _isDarkMode = isDark);
  }

  void _toggleTheme() async {
    final newValue = !_isDarkMode;
    await _themeService.setDarkMode(newValue);
    if (mounted) {
      setState(() {
        _isDarkMode = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey(_isDarkMode), // Force la reconstruction quand le thème change
      title: 'Cooking Recipes',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('fr', 'FR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      home: Builder(
        builder: (context) => AuthWrapper(
          onThemeToggle: () {
            _toggleTheme();
            // Forcer la reconstruction de l'app
            setState(() {});
          },
          isDarkMode: _isDarkMode,
        ),
      ),
      routes: {
        '/home': (context) => MainScreen(
          onThemeToggle: () {
            _toggleTheme();
            setState(() {});
          },
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
  final bool isDarkMode;

  const AuthWrapper({
    super.key,
    this.onThemeToggle,
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
        isDarkMode: widget.isDarkMode,
      );
    }

    return const AuthScreen();
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    this.onThemeToggle,
    this.isDarkMode = false,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final ProfileService _profileService = ProfileService();
  UserProfile? _currentProfile;

  final List<Widget> _screens = [
    const RecipesScreen(),
    const PantryScreen(),
    const ShoppingListScreen(),
    const MealPlanScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Recharger le profil quand on change d'onglet
          _loadProfile();
        },
        elevation: 8,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu_outlined),
            selectedIcon: const Icon(Icons.restaurant_menu),
            label: 'Recettes',
          ),
          NavigationDestination(
            icon: const Icon(Icons.kitchen_outlined),
            selectedIcon: const Icon(Icons.kitchen),
            label: 'Placard',
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: 'Planning',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: 'Profil',
          ),
        ],
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
            title: const Text('Recettes'),
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
            title: const Text('Placard'),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
              _loadProfile();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.shopping_cart,
              color: _selectedIndex == 2
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: const Text('Liste de courses'),
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
            title: const Text('Planning'),
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
            title: const Text('Profil'),
            selected: _selectedIndex == 4,
            onTap: () {
              setState(() => _selectedIndex = 4);
              Navigator.pop(context);
              _loadProfile();
            },
          ),
          const Divider(),
          // Mode sombre/clair
          ListTile(
            leading: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            title: Text(widget.isDarkMode ? 'Mode clair' : 'Mode sombre'),
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
}
