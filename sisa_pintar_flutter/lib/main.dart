import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'database/hive_db_helper.dart';
import 'screens/home_screen.dart';
import 'screens/expiry_tracker_screen.dart';
import 'screens/recipe_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive storage
  await HiveDbHelper.init();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppThemeProvider(),
      child: const SisaPintarApp(),
    ),
  );
}

class AppThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class SisaPintarApp extends StatelessWidget {
  const SisaPintarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<AppThemeProvider>(context);

    return MaterialApp(
      title: 'SisaPintar',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
          primary: const Color(0xFF2E7D32),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF212121),
          elevation: 0.5,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 1,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
          primary: const Color(0xFF4CAF50),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0.5,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E1E),
          elevation: 1,
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<AppThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final toggle = themeProvider.toggleTheme;

    final List<Widget> screens = [
      HomeScreen(
        isDarkMode: isDark,
        onToggleDarkMode: toggle,
        onNavigateToTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      RecipeScreen(isDarkMode: isDark, onToggleDarkMode: toggle),
      ExpiryTrackerScreen(),
      DashboardScreen(isDarkMode: isDark, onToggleDarkMode: toggle),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            activeIcon: Icon(LucideIcons.home, color: Color(0xFF2E7D32)),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.chefHat),
            activeIcon: Icon(LucideIcons.chefHat, color: Color(0xFF2E7D32)),
            label: 'Resep',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.calendar),
            activeIcon: Icon(LucideIcons.calendar, color: Color(0xFF2E7D32)),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.barChart2),
            activeIcon: Icon(LucideIcons.barChart2, color: Color(0xFF2E7D32)),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}
