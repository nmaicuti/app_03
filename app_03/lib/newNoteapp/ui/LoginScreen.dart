import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/NoteAccountDatabaseHelper.dart';
import 'NoteListScreen.dart';
import 'RegisterScreen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final bool isDarkMode;
  final Function(BuildContext) onLogout;

  const LoginScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
    required this.onLogout,
  });

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final account = await NoteAccountDatabaseHelper.instance.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (account != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', account.userId);
          await prefs.setInt('accountId', account.id!);
          await prefs.setString('username', account.username);
          await prefs.setBool('isLoggedIn', true);

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => NoteListScreen(
                  onThemeChanged: widget.onThemeChanged,
                  isDarkMode: widget.isDarkMode,
                  onLogout: widget.onLogout,
                ),
              ),
            );
          }
        } else {
          _showErrorSnackBar('Incorrect username or password.');
        }
      } catch (e) {
        _showErrorSnackBar('Login error: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFF4D4D), // Vibrant red for errors
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _loadLottie() async {
    try {
      await DefaultAssetBundle.of(context).loadString('assets/animations/note_login.json');
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final primaryGradient = LinearGradient(
      colors: isDarkMode
          ? [const Color(0xFF00DDEB), const Color(0xFF8B5CF6)] // Cyan to electric purple
          : [const Color(0xFFFF6B6B), const Color(0xFF4ECDC4)], // Coral to teal
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF0F172A), const Color(0xFF1E3A8A)] // Slate to deep blue
                : [const Color(0xFFF1F5F9), const Color(0xFFE0F2FE)], // Light gray to sky blue
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? const Color(0xFF8B5CF6).withOpacity(0.5)
                                : const Color(0xFFFF6B6B).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: FutureBuilder<bool>(
                          future: _loadLottie(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done &&
                                snapshot.hasData &&
                                snapshot.data == true) {
                              return Lottie.asset(
                                'assets/animations/note_login.json',
                                fit: BoxFit.contain,
                              );
                            }
                            return const Icon(
                              Icons.note_alt,
                              size: 60,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _usernameController,
                              label: 'Username',
                              icon: Icons.person,
                              validator: (value) =>
                              value!.isEmpty ? 'Please enter your username' : null,
                            ).animate().fadeIn(delay: const Duration(milliseconds: 800)),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFFFF6B6B),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) =>
                              value!.isEmpty ? 'Please enter your password' : null,
                            ).animate().fadeIn(delay: const Duration(milliseconds: 1000)),
                            const SizedBox(height: 24),
                            _buildActionButton(
                              label: 'Sign In',
                              gradient: primaryGradient,
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _login,
                            ).animate().fadeIn(delay: const Duration(milliseconds: 1200)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextButton(
                      label: "Don't have an account? Register",
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(
                              onThemeChanged: widget.onThemeChanged,
                              isDarkMode: widget.isDarkMode,
                              onLogout: widget.onLogout,
                            ),
                          ),
                        );
                      },
                    ).animate().fadeIn(delay: const Duration(milliseconds: 1400)),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      label: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                      icon: isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                      color: isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFFFF6B6B),
                      onPressed: widget.onThemeChanged,
                    ).animate().fadeIn(delay: const Duration(milliseconds: 1600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = widget.isDarkMode;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFFFF6B6B),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFFFF6B6B),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF4D4D), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF4D4D), width: 2),
        ),
        errorStyle: GoogleFonts.poppins(
          color: const Color(0xFFFF4D4D),
          fontWeight: FontWeight.w500,
        ),
      ),
      style: GoogleFonts.poppins(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      validator: validator,
    );
  }

  Widget _buildActionButton({
    required String label,
    IconData? icon,
    Color? color,
    LinearGradient? gradient,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (color ?? (widget.isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFFFF6B6B)))
                  .withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    final isDarkMode = widget.isDarkMode;
    return GestureDetector(
      onTap: onPressed,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFFFF6B6B),
        ),
      ),
    );
  }
}