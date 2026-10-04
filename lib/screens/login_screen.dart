import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_provider.dart';
import '../i18n/strings.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final provider = context.read<AppProvider>();
    await provider.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
    if (provider.isLoggedIn && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
      body: SingleChildScrollView(
        child: SizedBox(
          height: h,
          child: Column(
            children: [
              // ── Hero section ─────────────────────────────────────────────
              Container(
                height: h * 0.42,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E1B4B),
                      Color(0xFF312E81),
                      Color(0xFF4F46E5)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background circles
                    Positioned(
                        top: -60,
                        right: -60,
                        child: _heroBubble(200, opacity: 0.07)),
                    Positioned(
                        bottom: -40,
                        left: -40,
                        child: _heroBubble(160, opacity: 0.05)),
                    Positioned(
                        top: 80,
                        left: 40,
                        child: _heroBubble(80, opacity: 0.08)),
                    // Content
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2),
                              ),
                              child: const Icon(Icons.school_rounded,
                                  color: Colors.white, size: 40),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              SAMSStrings.appName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              SAMSStrings.sriLanka,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Language switcher
                            _LanguagePills(provider: provider),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form section ──────────────────────────────────────────────
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            SAMSStrings.loginTitle,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Parent & Student Portal',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: isDark
                                  ? SAMSColors.textDarkSub
                                  : SAMSColors.textLightSub,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Error banner
                          if (provider.error != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: SAMSColors.absent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: SAMSColors.absent.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: SAMSColors.absent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      provider.error!,
                                      style: const TextStyle(
                                          color: SAMSColors.absent,
                                          fontSize: 13,
                                          fontFamily: 'Inter'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Username
                          TextField(
                            controller: _usernameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: SAMSStrings.username,
                              prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextField(
                            controller: _passwordCtrl,
                            obscureText: !_showPassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              labelText: SAMSStrings.password,
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _showPassword = !_showPassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Forgot Password link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                final result = await Navigator.of(context).push<String>(
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => ForgotPasswordScreen(
                                      initialUsername: _usernameCtrl.text.trim(),
                                    ),
                                    transitionsBuilder: (_, anim, __, child) =>
                                        FadeTransition(opacity: anim, child: child),
                                    transitionDuration: const Duration(milliseconds: 300),
                                  ),
                                );
                                if (result != null && result.isNotEmpty && mounted) {
                                  _usernameCtrl.text = result;
                                  _passwordCtrl.clear();
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                SAMSStrings.forgotPassword,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: SAMSColors.primaryLight,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  provider.isLoading ? null : _handleLogin,
                              child: provider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(SAMSStrings.login),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Don't have an account? Register
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) =>
                                        const RegisterScreen(),
                                    transitionsBuilder: (_, anim, __, child) =>
                                        FadeTransition(
                                            opacity: anim, child: child),
                                    transitionDuration:
                                        const Duration(milliseconds: 300),
                                  ),
                                );
                              },
                              child: Text(
                                SAMSStrings.dontHaveAccount,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: SAMSColors.primaryLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } 

  Widget _heroBubble(double size, {double opacity = 0.1}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _LanguagePills extends StatelessWidget {
  final AppProvider provider;
  const _LanguagePills({required this.provider});

  @override
  Widget build(BuildContext context) {
    final langs = [
      (AppLanguage.english, 'EN', 'English'),
      (AppLanguage.sinhala, 'SI', 'සිංහල'),
      (AppLanguage.tamil, 'TA', 'தமிழ்'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: langs.map((l) {
        final isActive = provider.language == l.$1;
        return GestureDetector(
          onTap: () => provider.setLanguage(l.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l.$3,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? SAMSColors.primary : Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
