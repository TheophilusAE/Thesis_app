import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_text_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      final msg = authProvider.lastMessage ?? 'Login gagal. Silakan coba lagi.';
      setState(() => _errorMessage = msg);
      if (mounted) _showErrorSnackBar(context, msg);
    }
    // On success, _AuthGate in main.dart automatically switches to HomeScreen
  }

  Future<void> _forgotPassword() async {
    setState(() => _errorMessage = null);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Masukkan email Anda terlebih dahulu untuk reset password.';
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.forgotPassword(email);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Tautan reset kata sandi telah dikirim ke email Anda.')),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      final msg = authProvider.lastMessage ?? 'Gagal mengirim email reset kata sandi.';
      setState(() => _errorMessage = msg);
      if (mounted) _showErrorSnackBar(context, msg);
    }
  }

  Future<void> _resendConfirmation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Masukkan alamat email Anda untuk mengirim ulang konfirmasi.';
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resendConfirmationEmail(email);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Email konfirmasi baru telah dikirim. Silakan periksa kotak masuk Anda.')),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      final msg = authProvider.lastMessage ?? 'Gagal mengirim ulang email konfirmasi.';
      setState(() => _errorMessage = msg);
      if (mounted) _showErrorSnackBar(context, msg);
    }
  }

  bool get _isEmailConfirmationError =>
      _errorMessage?.toLowerCase().contains('dikonfirmasi') == true ||
      _errorMessage?.toLowerCase().contains('email_not_confirmed') == true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 720;
    final hPad = mediaQuery.size.width < 380 ? 18.0 : 24.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141214) : AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, isCompact ? 16 : 28, hPad, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - (isCompact ? 40 : 52)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Church Logo
                        Center(
                          child: Container(
                            width: isCompact ? 80 : 92,
                            height: isCompact ? 80 : 92,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1C1F) : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2E2B30) : const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.08),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.church,
                                size: 52,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isCompact ? 16 : 22),
                        // Title & Subtitle
                        Text(
                          'Selamat Datang',
                          style: TextStyle(
                            fontSize: isCompact ? 24 : 28,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFF5F3F6) : AppTheme.textColor,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Masuk untuk melanjutkan ke akun jemaat Anda',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: isDark ? const Color(0xFFA5A1A8) : AppTheme.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isCompact ? 22 : 32),

                        // Form Card
                        AppCard(
                          padding: const EdgeInsets.all(22),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Inline error notice
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.errorColor.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: AppTheme.errorColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: const TextStyle(
                                                  color: AppTheme.errorColor,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_isEmailConfirmationError) ...[
                                          const SizedBox(height: 10),
                                          InkWell(
                                            onTap: _resendConfirmation,
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'Kirim ulang email konfirmasi',
                                                    style: TextStyle(
                                                      color: AppTheme.primary,
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.w700,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primary),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                ],

                                // Email Input
                                AppTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hintText: 'nama@email.com',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Email tidak boleh kosong';
                                    }
                                    if (!v.contains('@') || !v.contains('.')) {
                                      return 'Format email tidak valid';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Password Input with Forgot Password Action
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Kata Sandi',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFF5F3F6) : AppTheme.textColor,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _forgotPassword,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Lupa Kata Sandi?',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                AppTextField(
                                  controller: _passwordController,
                                  hintText: '••••••••',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _login(),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Kata sandi tidak boleh kosong';
                                    }
                                    if (v.length < 6) {
                                      return 'Kata sandi minimal 6 karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 26),

                                // Submit Button
                                Consumer<AuthProvider>(
                                  builder: (context, auth, _) => AppButton.primary(
                                    label: 'Masuk',
                                    isLoading: auth.isLoading,
                                    onPressed: auth.isLoading ? null : _login,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Register Link
                    Padding(
                      padding: EdgeInsets.only(top: isCompact ? 16 : 24, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFA5A1A8) : AppTheme.secondaryText,
                              fontSize: 14.5,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(
                                'Daftar Sekarang',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
