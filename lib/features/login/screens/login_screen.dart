import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/kl_skyline.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onAdminPortal;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onAdminPortal,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _showPassword = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;
    final availH = screenH - topPad - MediaQuery.of(context).padding.bottom;
    // ~44% of available height for the hero
    final heroH = availH * 0.44;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Gradient Hero (behind status bar) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroH + topPad,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.gradientHeader,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System status bar spacer
                  SizedBox(height: topPad + 8),
                  // Logo row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppShadows.cardLg,
                          ),
                          child: const Icon(
                            Icons.train_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SmartRoute',
                                style: AppTypography.logo.copyWith(
                                    color: Colors.white)),
                            Text(
                              'KLANG VALLEY TRANSIT',
                              style: AppTypography.logoSubtitle.copyWith(
                                color: AppColors.white55,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // KL Skyline fills remaining hero space
                  const Expanded(child: KLSkyline(height: 128)),
                  // Tagline
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Smart Transit\nCompanion',
                          style: AppTypography.headlineLarge.copyWith(
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LRT · MRT · Bus · BRT · Monorail',
                          style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.white55),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── White Card (overlaps hero by 12px) ──
          Positioned(
            top: heroH + topPad - 12,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xxl),
                  topRight: Radius.circular(AppRadius.xxl),
                ),
                boxShadow: AppShadows.loginCard,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xxl),
                  topRight: Radius.circular(AppRadius.xxl),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    children: [
                      // ── Tab Toggle ──
                      _buildTabToggle(),
                      const SizedBox(height: 20),

                      // ── Full Name (register only) ──
                      if (!_isLogin) ...[
                        _buildField(
                          label: 'FULL NAME',
                          icon: Icons.person_outline_rounded,
                          controller: _nameController,
                          hint: 'Yih Loong',
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Email ──
                      _buildField(
                        label: 'EMAIL ADDRESS',
                        icon: Icons.mail_outline_rounded,
                        controller: _emailController,
                        hint: 'yih.loong@gmail.com',
                      ),
                      const SizedBox(height: 16),

                      // ── Password ──
                      _buildField(
                        label: 'PASSWORD',
                        icon: Icons.shield_outlined,
                        controller: _passwordController,
                        hint: '••••••••',
                        obscure: !_showPassword,
                        suffix: GestureDetector(
                          onTap: () =>
                              setState(() => _showPassword = !_showPassword),
                          child: Icon(
                            _showPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 16,
                            color: AppColors.iconGray,
                          ),
                        ),
                      ),

                      // ── Forgot Password ──
                      if (_isLogin) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Forgot password?',
                              style: AppTypography.captionBold.copyWith(
                                  color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ] else
                        const SizedBox(height: 24),

                      // ── Sign In / Register Button ──
                      _buildPrimaryButton(),
                      const SizedBox(height: 20),

                      // ── Divider ──
                      Row(
                        children: [
                          const Expanded(
                              child: Divider(color: AppColors.divider)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or continue with',
                              style: AppTypography.captionMedium.copyWith(
                                  color: AppColors.iconGray),
                            ),
                          ),
                          const Expanded(
                              child: Divider(color: AppColors.divider)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Social Buttons ──
                      Row(
                        children: [
                          Expanded(child: _socialBtn('Google', '🇬')),
                          const SizedBox(width: 12),
                          Expanded(child: _socialBtn('Apple', '🍎')),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Terms ──
                      Text.rich(
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style: AppTypography.captionMedium.copyWith(
                              color: AppColors.iconGray),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: AppTypography.captionBold.copyWith(
                                  color: AppColors.primary),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: AppTypography.captionBold.copyWith(
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        key: const Key('open-admin-portal'),
                        onPressed: widget.onAdminPortal,
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('Open Admin Portal'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
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
    );
  }

  // ─── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mutedBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: ['Sign In', 'Register'].asMap().entries.map((e) {
          final isLogin = e.key == 0;
          final active = _isLogin == isLogin;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = isLogin),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: active ? AppShadows.card : null,
                ),
                child: Center(
                  child: Text(
                    e.value,
                    style: AppTypography.bodyLarge.copyWith(
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.mutedForeground,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientPrimary),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.primaryButton,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onLogin,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Center(
            child: Text(
              _isLogin ? 'Sign In to SmartRoute' : 'Create My Account',
              style: AppTypography.bodyLarge.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(icon, size: 16, color: AppColors.iconGray),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    hintText: hint,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.iconGray),
                  ),
                ),
              ),
              if (suffix != null) ...[
                suffix,
                const SizedBox(width: 16),
              ] else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialBtn(String label, String emoji) {
    return GestureDetector(
      onTap: widget.onLogin,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.mutedBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
