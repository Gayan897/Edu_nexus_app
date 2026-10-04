import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_provider.dart';
import '../i18n/strings.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialUsername;
  const ForgotPasswordScreen({super.key, this.initialUsername});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Step tracker: 1 = Enter Username, 2 = Enter OTP, 3 = Reset Password, 4 = Success
  int _currentStep = 1;

  final _usernameCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // 6 individual OTP digit controllers & FocusNodes
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _localError;

  // Countdown timer for Resend OTP
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUsername != null && widget.initialUsername!.isNotEmpty) {
      _usernameCtrl.text = widget.initialUsername!;
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _usernameCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 1) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _canResend = true;
          _resendCountdown = 0;
        });
      }
    });
  }

  String get _enteredOtp =>
      _otpControllers.map((c) => c.text).join();

  Future<void> _handleSendOtp() async {
    setState(() => _localError = null);
    final provider = context.read<AppProvider>();
    final username = _usernameCtrl.text.trim();

    if (username.isEmpty) {
      setState(() => _localError = 'Please enter your username');
      return;
    }

    final success = await provider.sendPasswordResetOtp(username);
    if (success && mounted) {
      for (final c in _otpControllers) {
        c.clear();
      }
      setState(() {
        _currentStep = 2;
        _localError = null;
      });
      _startResendTimer();
      _otpFocusNodes[0].requestFocus();
    }
  }

  void _handleVerifyOtp() {
    setState(() => _localError = null);
    final provider = context.read<AppProvider>();
    final otp = _enteredOtp;

    if (otp.length < 6) {
      setState(() => _localError = 'Please enter the complete 6-digit OTP code.');
      return;
    }

    final isValid = provider.verifyResetOtp(otp);
    if (isValid && mounted) {
      setState(() {
        _currentStep = 3;
        _localError = null;
      });
    }
  }

  Future<void> _handleResetPassword() async {
    setState(() => _localError = null);
    final provider = context.read<AppProvider>();
    final newPass = _newPasswordCtrl.text;
    final confirmPass = _confirmPasswordCtrl.text;

    if (newPass.length < 6) {
      setState(() => _localError = SAMSStrings.passwordTooShort);
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _localError = SAMSStrings.passwordsDoNotMatch);
      return;
    }

    final username = _usernameCtrl.text.trim();
    final success = await provider.resetPassword(
      username: username,
      newPassword: newPass,
    );

    if (success && mounted) {
      setState(() {
        _currentStep = 4;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    final displayError = _localError ?? provider.error;

    return Scaffold(
      backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Back button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SAMSColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SAMSColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 14, color: SAMSColors.primaryLight),
                        const SizedBox(width: 6),
                        Text(
                          'Step $_currentStep of 3',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: SAMSColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.35), width: 1.5),
                      ),
                      child: Icon(
                        _currentStep == 1
                            ? Icons.lock_reset_rounded
                            : _currentStep == 2
                                ? Icons.mark_email_read_rounded
                                : _currentStep == 3
                                    ? Icons.password_rounded
                                    : Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentStep == 1
                                ? SAMSStrings.forgotPasswordTitle
                                : _currentStep == 2
                                    ? SAMSStrings.verifyOtp
                                    : _currentStep == 3
                                        ? SAMSStrings.newPassword
                                        : 'Password Reset',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _currentStep == 1
                                ? 'Verify via registered phone'
                                : _currentStep == 2
                                    ? '6-digit SMS verification code'
                                    : _currentStep == 3
                                        ? 'Set your new strong password'
                                        : 'Account updated successfully',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error banner if any
              if (displayError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: SAMSColors.absent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: SAMSColors.absent.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: SAMSColors.absent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayError,
                          style: const TextStyle(
                            color: SAMSColors.absent,
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ─── STEP 1: Enter Username ──────────────────────────────────────
              if (_currentStep == 1) ...[
                Text(
                  SAMSStrings.forgotPasswordSub,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    height: 1.45,
                    color: isDark
                        ? SAMSColors.textDarkSub
                        : SAMSColors.textLightSub,
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _usernameCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSendOtp(),
                  decoration: InputDecoration(
                    labelText: SAMSStrings.username,
                    hintText: 'e.g. gayanpp or student ID',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 22),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _handleSendOtp,
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(SAMSStrings.sendOtp),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
              ],

              // ─── STEP 2: Enter & Verify OTP ──────────────────────────────────
              if (_currentStep == 2) ...[
                // Info Box with Masked Phone
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? SAMSColors.bgDarkCard
                        : SAMSColors.bgLightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_android_rounded,
                              size: 18, color: SAMSColors.primaryLight),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              SAMSStrings.otpSentTo,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: isDark
                                    ? SAMSColors.textDarkSub
                                    : SAMSColors.textLightSub,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        provider.resetMaskedPhone ?? 'Registered Contact',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Simulated SMS Notification Card (Realistic SMS Delivery Simulation)
                if (provider.resetOtp != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: SAMSColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SAMSColors.primary.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SAMSColors.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sms_rounded,
                              color: SAMSColors.primaryLight, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SMS Notification (Demo/Dev preview):',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: SAMSColors.primaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SAMS OTP: ${provider.resetOtp}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final code = provider.resetOtp;
                            if (code != null && code.length == 6) {
                              for (int i = 0; i < 6; i++) {
                                _otpControllers[i].text = code[i];
                              }
                              _handleVerifyOtp();
                            }
                          },
                          child: const Text('Auto-Fill', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 6-digit OTP Box Inputs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: isDark
                              ? SAMSColors.bgDarkCard
                              : SAMSColors.bgLightCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: SAMSColors.primaryLight,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            if (index < 5) {
                              _otpFocusNodes[index + 1].requestFocus();
                            } else {
                              _otpFocusNodes[index].unfocus();
                              _handleVerifyOtp();
                            }
                          } else {
                            if (index > 0) {
                              _otpFocusNodes[index - 1].requestFocus();
                            }
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleVerifyOtp,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(SAMSStrings.verifyOtp),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Resend OTP & Change Username Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentStep = 1;
                          _localError = null;
                        });
                      },
                      child: Text(
                        'Change Username',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: isDark
                              ? SAMSColors.textDarkSub
                              : SAMSColors.textLightSub,
                        ),
                      ),
                    ),
                    _canResend
                        ? TextButton(
                            onPressed: _handleSendOtp,
                            child: Text(
                              SAMSStrings.resendOtp,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SAMSColors.primaryLight,
                              ),
                            ),
                          )
                        : Text(
                            '${SAMSStrings.resendIn} ${_resendCountdown}s',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              color: isDark
                                  ? SAMSColors.textDarkSub
                                  : SAMSColors.textLightSub,
                            ),
                          ),
                  ],
                ),
              ],

              // ─── STEP 3: Reset Password ──────────────────────────────────────
              if (_currentStep == 3) ...[
                Text(
                  'Create a new password for username "${_usernameCtrl.text.trim()}".',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    color: isDark
                        ? SAMSColors.textDarkSub
                        : SAMSColors.textLightSub,
                  ),
                ),
                const SizedBox(height: 20),

                // New Password
                TextField(
                  controller: _newPasswordCtrl,
                  obscureText: !_showNewPassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: SAMSStrings.newPassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNewPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _showNewPassword = !_showNewPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm Password
                TextField(
                  controller: _confirmPasswordCtrl,
                  obscureText: !_showConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleResetPassword(),
                  decoration: InputDecoration(
                    labelText: SAMSStrings.confirmNewPassword,
                    prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        provider.isLoading ? null : _handleResetPassword,
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(SAMSStrings.resetPasswordButton),
                  ),
                ),
              ],

              // ─── STEP 4: Success Screen ──────────────────────────────────────
              if (_currentStep == 4) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? SAMSColors.bgDarkCard
                        : SAMSColors.bgLightCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: SAMSColors.present.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: SAMSColors.present.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: SAMSColors.present,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Password Reset Complete!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        SAMSStrings.passwordResetSuccess,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? SAMSColors.textDarkSub
                              : SAMSColors.textLightSub,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(_usernameCtrl.text.trim());
                          },
                          child: Text(SAMSStrings.backToLogin),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
