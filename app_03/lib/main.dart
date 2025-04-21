import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_02/newNoteapp/ui/LoginScreen.dart';
import 'package:app_02/newNoteapp/ui/NoteListScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // Tải trạng thái chủ đề từ SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      });
    } catch (e) {
      debugPrint('Lỗi khi tải chủ đề: $e');
    }
  }

  // Lưu trạng thái chủ đề vào SharedPreferences
  Future<void> _saveTheme(bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', isDarkMode);
    } catch (e) {
      debugPrint('Lỗi khi lưu chủ đề: $e');
    }
  }

  // Chuyển đổi giữa chế độ sáng và tối
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _saveTheme(_isDarkMode);
    });
  }

  // Phương thức đăng xuất
  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              onThemeChanged: _toggleTheme,
              isDarkMode: _isDarkMode,
              onLogout: _logout,
            ),
          ),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi đăng xuất: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đăng xuất: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Ghi Chú',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: const CardTheme(
          color: Colors.white,
          elevation: 2,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        cardTheme: CardTheme(
          color: Colors.grey[800],
          elevation: 2,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AuthCheckWidget(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
        onLogout: _logout,
      ),
    );
  }
}

class AuthCheckWidget extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;
  final Function(BuildContext) onLogout;

  const AuthCheckWidget({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          debugPrint('Lỗi khi tải SharedPreferences: ${snapshot.error}');
          return LoginScreen(
            onThemeChanged: onThemeChanged,
            isDarkMode: isDarkMode,
            onLogout: onLogout,
          );
        }

        final prefs = snapshot.data!;
        final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

        return isLoggedIn
            ? NoteListScreen(
          onThemeChanged: onThemeChanged,
          isDarkMode: isDarkMode,
          onLogout: onLogout,
        )
            : LoginScreen(
          onThemeChanged: onThemeChanged,
          isDarkMode: isDarkMode,
          onLogout: onLogout,
        );
      },
    );
  }
}