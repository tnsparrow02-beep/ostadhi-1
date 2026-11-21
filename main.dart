import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'account_gate.dart';
import 'app_state.dart';
import 'calendar_notes_screen.dart';
import 'classes_screen.dart';
import 'library_screens.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';
import 'strings.dart';
import 'timetable_screen.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // calendar + date names in ar / fr / en
  await AppState.load(); // saved language + active class
  runApp(const MathTeacherApp());
}

class MathTeacherApp extends StatelessWidget {
  const MathTeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppState.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Ostadhi',
          locale: locale, // Arabic => automatic RTL layout
          supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: _buildTheme(),
          home: const SplashScreen(next: AccountGate(child: HomeShell())),
        );
      },
    );
  }
}

ThemeData _buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    brightness: Brightness.light,
  ).copyWith(secondary: AppColors.amber, tertiary: AppColors.emerald);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.indigo,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.amber.withValues(alpha: 0.35),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.amber,
      foregroundColor: AppColors.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = <Widget>[
    QuizScreen(),
    ClassesScreen(),
    TimetableScreen(),
    CalendarNotesScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final titles = [
      context.t('navQuiz'),
      context.t('navClasses'),
      context.t('navTimetable'),
      context.t('navCalendar'),
      context.t('navLibrary'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            tooltip: context.t('settings'),
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const _LanguageMenu(),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        ),
        // A new key per tab => the screen reloads fresh data from the database.
        // The epoch changes after a restore / full erase: every screen reloads from the database.
        child: ValueListenableBuilder<int>(
          key: ValueKey(_index),
          valueListenable: AppState.dataEpoch,
          builder: (context, epoch, _) => KeyedSubtree(key: ValueKey(epoch), child: _pages[_index]),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.quiz_outlined),
            selectedIcon: const Icon(Icons.quiz_rounded),
            label: titles[0],
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
            label: titles[1],
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: titles[2],
          ),
          NavigationDestination(
            icon: const Icon(Icons.edit_calendar_outlined),
            selectedIcon: const Icon(Icons.edit_calendar_rounded),
            label: titles[3],
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_copy_outlined),
            selectedIcon: const Icon(Icons.folder_copy_rounded),
            label: titles[4],
          ),
        ],
      ),
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu();

  @override
  Widget build(BuildContext context) {
    final current = context.lang;
    const options = {'ar': 'العربية', 'fr': 'Français', 'en': 'English'};

    return PopupMenuButton<String>(
      icon: const Icon(Icons.translate_rounded),
      tooltip: 'Language',
      onSelected: AppState.setLocale,
      itemBuilder: (_) => [
        for (final e in options.entries)
          PopupMenuItem<String>(
            value: e.key,
            child: Row(
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: e.key == current ? AppColors.emerald : Colors.transparent,
                ),
                const SizedBox(width: 8),
                Text(e.value),
              ],
            ),
          ),
      ],
    );
  }
}
