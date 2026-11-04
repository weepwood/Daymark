import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import 'data/prefs_task_repository.dart';
import 'state/app_settings.dart';
import 'state/task_controller.dart';
import 'theme/app_theme.dart';
import 'ui/task_home_page.dart';

class DaymarkApp extends StatefulWidget {
  const DaymarkApp({super.key});

  @override
  State<DaymarkApp> createState() => _DaymarkAppState();
}

class _DaymarkAppState extends State<DaymarkApp> with WidgetsBindingObserver {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  late final AppSettings _settings;
  late final TaskController _controller;
  bool _darkMode = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = AppSettings(_preferences);
    _controller = TaskController(PrefsTaskRepository(_preferences));
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _controller.load();
    _darkMode = await _settings.readDarkMode();
    if (mounted) setState(() => _ready = true);
  }

  void _toggleTheme() {
    setState(() => _darkMode = !_darkMode);
    unawaited(_settings.writeDarkMode(_darkMode));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_controller.flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Daymark · 任务管理',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
        home: _ready
            ? TaskHomePage(
                controller: _controller,
                isDark: _darkMode,
                onThemeToggle: _toggleTheme,
              )
            : const _SplashScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
