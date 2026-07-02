import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'database/hive_db_helper.dart';
import 'services/notification_service.dart';
import 'services/localization_service.dart';
import 'screens/home_screen.dart';
import 'screens/expiry_tracker_screen.dart';
import 'screens/recipe_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');

  // Initialize timezone - MUST be done before using tz.local
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  // Initialize Hive storage first so we can read settings in AppSettingsProvider
  await HiveDbHelper.init();

  // Initialize Notification Service
  await NotificationService().initialize();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppSettingsProvider(),
      child: const SisaPintarApp(),
    ),
  );
}

class AppSettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _currentLanguage = 'id';

  bool get isDarkMode => _isDarkMode;
  String get currentLanguage => _currentLanguage;

  AppSettingsProvider() {
    _isDarkMode = HiveDbHelper.getDarkTheme();
    _currentLanguage = HiveDbHelper.getAppLanguage();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    HiveDbHelper.saveDarkTheme(_isDarkMode);
    notifyListeners();
  }

  void setLanguage(String lang) {
    _currentLanguage = lang;
    HiveDbHelper.saveAppLanguage(lang);
    notifyListeners();
  }
}

class SisaPintarApp extends StatelessWidget {
  const SisaPintarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<AppSettingsProvider>(context);

    return MaterialApp(
      title: 'SisaPintar',
      debugShowCheckedModeBanner: false,
      themeMode: settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(settingsProvider.currentLanguage),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('id'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<AppSettingsProvider>(context);
    final isDark = settingsProvider.isDarkMode;
    final toggle = settingsProvider.toggleTheme;
    final lang = settingsProvider.currentLanguage;

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
      const ExpiryTrackerScreen(),
      DashboardScreen(isDarkMode: isDark, onToggleDarkMode: toggle),
      const SettingsScreen(),
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.home),
            activeIcon: const Icon(LucideIcons.home, color: Color(0xFF2E7D32)),
            label: LocalizationService.get(lang, 'home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.chefHat),
            activeIcon: const Icon(LucideIcons.chefHat, color: Color(0xFF2E7D32)),
            label: LocalizationService.get(lang, 'recipe'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.calendar),
            activeIcon: const Icon(LucideIcons.calendar, color: Color(0xFF2E7D32)),
            label: LocalizationService.get(lang, 'tracker'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.barChart2),
            activeIcon: const Icon(LucideIcons.barChart2, color: Color(0xFF2E7D32)),
            label: LocalizationService.get(lang, 'dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.settings),
            activeIcon: const Icon(LucideIcons.settings, color: Color(0xFF2E7D32)),
            label: LocalizationService.get(lang, 'settings'),
          ),
        ],
      ),
    );
  }
}
