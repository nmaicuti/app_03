import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:particles_flutter/particles_flutter.dart';
import 'dart:ui';
import '../db/NoteAccountDatabaseHelper.dart';
import 'NoteListScreen.dart';
import 'LoginScreen.dart';
import 'package:app_02/newNoteapp/model/NoteAccount.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final bool isDarkMode;
  final Function(BuildContext) onLogout;

  const RegisterScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
    required this.onLogout,
  });

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final username = _usernameController.text.trim();
        final password = _passwordController.text;

        final usernameExists = await NoteAccountDatabaseHelper.instance.isUsernameExists(username);
        if (usernameExists) {
          _showErrorSnackBar('Username already exists. Please choose another.');
          return;
        }

        final accountCount = await NoteAccountDatabaseHelper.instance.countAccounts();
        final newUserId = accountCount + 1;

        final now = DateTime.now().toIso8601String();
        final newAccount = NoteAccount(
          userId: newUserId,
          username: username,
          password: password,
          status: 'active',
          lastLogin: now,
          createdAt: now,
        );

        final createdAccount = await NoteAccountDatabaseHelper.instance.createAccount(newAccount);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', createdAccount.userId);
        await prefs.setInt('accountId', createdAccount.id!);
        await prefs.setString('username', createdAccount.username);
        await prefs.setBool('isLoggedIn', true);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => NoteListScreen(
                onThemeChanged: widget.onThemeChanged,
                isDarkMode: widget.isDarkMode,
                onLogout: widget.onLogout,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar('Registration failed: $e');
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
        backgroundColor: const Color(0xFFEC4899),
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
          ? [const Color(0xFF6B46C1), const Color(0xFFED64A6)]
          : [const Color(0xFFF472B6), const Color(0xFF60A5FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CircularParticle(
              key: UniqueKey(),
              awayRadius: 150,
              numberOfParticles: 60,
              speedOfParticles: 0.8,
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              onTapAnimation: true,
              particleColor: isDarkMode
                  ? Colors.white.withOpacity(0.4)
                  : const Color(0xFF60A5FA).withOpacity(0.4),
              awayAnimationDuration: const Duration(milliseconds: 800),
              maxParticleSize: 5,
              isRandSize: true,
              isRandomColor: false,
              connectDots: false,
              awayAnimationCurve: Curves.easeInOut,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [const Color(0xFF1A1036), const Color(0xFF2D1B5E)]
                    : [const Color(0xFFF3E8FF), const Color(0xFFDBEAFE)],
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
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? const Color(0xFFED64A6).withOpacity(0.5)
                                      : const Color(0xFFF472B6).withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
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
                                    Icons.person_add_alt_1,
                                    size: 80,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                        const SizedBox(height: 24),
                        Text(
                          'Join NoteApp',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            shadows: [
                              Shadow(
                                color: isDarkMode
                                    ? const Color(0xFFED64A6).withOpacity(0.3)
                                    : const Color(0xFFF472B6).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: const Duration(milliseconds: 400)).slideY(begin: 0.2),
                        const SizedBox(height: 8),
                        Text(
                          'Create your account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ).animate().fadeIn(delay: const Duration(milliseconds: 600)).slideY(begin: 0.2),
                        const SizedBox(height: 40),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                            border: Border.all(
                              color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        controller: _usernameController,
                                        label: 'Username',
                                        icon: Icons.person,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your username';
                                          }
                                          if (value.length < 3) {
                                            return 'Username must be at least 3 characters';
                                          }
                                          return null;
                                        },
                                      ).animate().fadeIn(delay: const Duration(milliseconds: 800)).slideX(begin: -0.2),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        icon: Icons.lock,
                                        obscureText: _obscurePassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                            color: isDarkMode ? const Color(0xFFF687B3) : const Color(0xFFEC4899),
                                          ),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ).animate().fadeIn(delay: const Duration(milliseconds: 1000)).slideX(begin: -0.2),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _confirmPasswordController,
                                        label: 'Confirm Password',
                                        icon: Icons.lock,
                                        obscureText: _obscureConfirmPassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                            color: isDarkMode ? const Color(0xFFF687B3) : const Color(0xFFEC4899),
                                          ),
                                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please confirm your password';
                                          }
                                          if (value != _passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ).animate().fadeIn(delay: const Duration(milliseconds: 1200)).slideX(begin: -0.2),
                                      const SizedBox(height: 24),
                                      _buildActionButton(
                                        label: 'Sign Up',
                                        gradient: primaryGradient,
                                        isLoading: _isLoading,
                                        onPressed: _isLoading ? null : _register,
                                        neonBorder: isDarkMode,
                                      ).animate().fadeIn(delay: const Duration(milliseconds: 1400)).scale(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTextButton(
                              label: 'Already have an account?',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => LoginScreen(
                                      onThemeChanged: widget.onThemeChanged,
                                      isDarkMode: widget.isDarkMode,
                                      onLogout: widget.onLogout,
                                    ),
                                  ),
                                );
                              },
                            ).animate().fadeIn(delay: const Duration(milliseconds: 1600)),
                            const SizedBox(width: 16),
                            _buildTextButton(
                              label: 'Sign In',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => LoginScreen(
                                      onThemeChanged: widget.onThemeChanged,
                                      isDarkMode: widget.isDarkMode,
                                      onLogout: widget.onLogout,
                                    ),
                                  ),
                                );
                              },
                            ).animate().fadeIn(delay: const Duration(milliseconds: 1800)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildActionButton(
                          label: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                          icon: isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                          color: isDarkMode ? const Color(0xFFF687B3) : const Color(0xFFEC4899),
                          onPressed: widget.onThemeChanged,
                        ).animate().fadeIn(delay: const Duration(milliseconds: 2000)).scale(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
          color: isDarkMode ? const Color(0xFFF687B3) : const Color(0xFFEC4899),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode ? const Color(0xFFF687B3) : const Color(0xFFEC4899),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEC4899), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEC4899), width: 2),
        ),
        errorStyle: GoogleFonts.poppins(
          color: const Color(0xFFEC4899),
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
    bool neonBorder = false,
  }) {
    final isDarkMode = widget.isDarkMode;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (color ?? (isDarkMode ? const Color(0xFFF687B3) : const Color(0xFFEC4899))).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 5,
            ),
            if (neonBorder)
              BoxShadow(
                color: const Color(0xFFED64A6).withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
          border: neonBorder
              ? Border.all(
            color: const Color(0xFFED64A6).withOpacity(0.8),
            width: 2,
          )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: color ?? Colors.white,
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
    ).animate().scale(duration: const Duration(milliseconds: 200));
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
          color: isDarkMode ? const Color(0xFFF687B3) : const Color(0xFFEC4899),
        ),
      ),
    ).animate().scale(duration: const Duration(milliseconds: 200));
  }
}