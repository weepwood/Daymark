import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/task_repository.dart';
import 'state/task_controller.dart';
import 'ui/task_home_page.dart';

class DaymarkApp extends StatefulWidget {
  const DaymarkApp({super.key});

  @override
  State<DaymarkApp> createState() => _DaymarkAppState();
}

class _DaymarkAppState extends State<DaymarkApp> {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  late final TaskController _controller;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _controller = TaskController(TaskRepository(_preferences));
    unawaited(_controller.load());
    unawaited(_loadTheme());
  }

  Future<void> _loadTheme() async {
    try {
      final value = await _preferences.getBool('daymark.dark_mode') ?? false;
      if (mounted) setState(() => _darkMode = value);
    } catch (_) {
      // The app remains usable with its default light theme.
    }
  }

  void _toggleTheme() {
    setState(() => _darkMode = !_darkMode);
    unawaited(_preferences.setBool('daymark.dark_mode', _darkMode));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF675AF0);
    ThemeData theme(Brightness brightness) {
      final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
      return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: brightness == Brightness.light
            ? const Color(0xFFF7F8FC)
            : const Color(0xFF11131B),
        fontFamily: null,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerLowest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
        cardTheme: CardThemeData(
          color: scheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }

    return MaterialApp(
      title: 'Daymark · 任务管理',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: TaskHomePage(
        controller: _controller,
        isDark: _darkMode,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}
