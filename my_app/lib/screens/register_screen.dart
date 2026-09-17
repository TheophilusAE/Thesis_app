import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _identityNumberController = TextEditingController();
  final _familyGroupController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  String _baptismStatus = 'Belum';
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _identityNumberController.dispose();
    _familyGroupController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      identityNumber: _identityNumberController.text.trim(),
      familyGroup: _familyGroupController.text.trim(),
      address: _addressController.text.trim(),
      baptismDate: _baptismStatus,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Pendaftaran berhasil! Akun Anda akan diverifikasi oleh admin gereja.'),
              ),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    final msg = authProvider.lastMessage ?? 'Pendaftaran gagal. Silakan periksa data Anda.';
    setState(() => _errorMessage = msg);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(msg, style: const TextStyle(fontSize: 13.5))),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141214) : AppTheme.background,
      appBar: AppBar(
        title: const Text('Pendaftaran Jemaat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Kembali',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcoming Header
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1C1F) : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      size: 38,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Daftar Akun Baru',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF5F3F6) : AppTheme.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Lengkapi data diri Anda untuk terdaftar dalam basis data jemaat GPDI',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: isDark ? const Color(0xFFA5A1A8) : AppTheme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // Info verification banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.infoLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppTheme.infoColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Setelah mendaftar, akun Anda akan diverifikasi oleh admin gereja sebelum seluruh fitur jemaat dapat diakses.',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF2C3E50) : const Color(0xFF1E3A5F),
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Error message banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.errorColor, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Section 1: Data Kontak & Akun
                _buildSectionCard(
                  title: 'Data Kontak & Akun',
                  icon: Icons.badge_outlined,
                  isDark: isDark,
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      hintText: 'Nama lengkap sesuai KTP',
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Nama tidak boleh kosong';
                        if (v.trim().length < 3) return 'Nama minimal 3 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _emailController,
                      label: 'Alamat Email',
                      hintText: 'nama@email.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
                        if (!v.contains('@') || !v.contains('.')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Nomor WhatsApp / HP',
                      hintText: '08xxxxxxxxxx',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Nomor HP tidak boleh kosong';
                        if (v.trim().length < 9) return 'Nomor HP minimal 9 digit';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Kata Sandi Akun',
                      hintText: 'Minimal 6 karakter',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Kata sandi tidak boleh kosong';
                        if (v.length < 6) return 'Kata sandi minimal 6 karakter';
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 2: Data Jemaat & Domisili
                _buildSectionCard(
                  title: 'Data Jemaat & Domisili',
                  icon: Icons.church_outlined,
                  isDark: isDark,
                  children: [
                    AppTextField(
                      controller: _identityNumberController,
                      label: 'Nomor Identitas (NIK / KTP)',
                      hintText: '16 digit NIK (opsional)',
                      prefixIcon: Icons.credit_card_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _familyGroupController,
                      label: 'Kelompok Keluarga / Komsel',
                      hintText: 'Nama KK atau wilayah komsel (opsional)',
                      prefixIcon: Icons.groups_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Baptism Status Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Baptis Selam',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFF5F3F6) : AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1C1F) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _baptismStatus,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Belum',
                                  child: Text('Belum Dibaptis Selam'),
                                ),
                                DropdownMenuItem(
                                  value: 'Sudah',
                                  child: Text('Sudah Dibaptis Selam'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _baptismStatus = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _addressController,
                      label: 'Alamat Domisili',
                      hintText: 'Alamat tempat tinggal saat ini (opsional)',
                      prefixIcon: Icons.home_outlined,
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Submit Button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => AppButton.primary(
                    label: 'Daftar Sebagai Jemaat',
                    isLoading: auth.isLoading,
                    onPressed: auth.isLoading ? null : _register,
                  ),
                ),
                const SizedBox(height: 20),

                // Back to Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFA5A1A8) : AppTheme.secondaryText,
                        fontSize: 14.5,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(
                          'Masuk di Sini',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262328) : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF5F3F6) : AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
