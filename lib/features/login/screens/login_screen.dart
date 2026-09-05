import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/kl_skyline.dart';
import '../../user_management/application/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  final AuthController authController;

  const LoginScreen({super.key, required this.authController});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _showPassword = false;
  String? _infoMessage;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuthChanged);
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authController != widget.authController) {
      oldWidget.authController.removeListener(_onAuthChanged);
      widget.authController.addListener(_onAuthChanged);
    }
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _switchTab(bool isLogin) {
    if (_isLogin != isLogin) {
      setState(() {
        _isLogin = isLogin;
        _infoMessage = null;
      });
      widget.authController.clearError();
    }
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _infoMessage = null;
    });
    await widget.authController.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _infoMessage = null;
    });
    final success = await widget.authController.register(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (success && widget.authController.requiresEmailConfirmation && mounted) {
      setState(() {
        _isLogin = true;
        _passwordController.clear();
        _infoMessage =
            'Account created. Check your email to confirm your account, then sign in.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;
    final availH = screenH - topPad - MediaQuery.of(context).padding.bottom;
    final heroH = availH * 0.44;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
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
                  SizedBox(height: topPad + 8),
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
                            Text(
                              'SmartRoute',
                              style: AppTypography.logo.copyWith(
                                color: Colors.white,
                              ),
                            ),
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
                  const Expanded(child: KLSkyline(height: 128)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Smart Transit\nCompanion',
                          style: AppTypography.headlineLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LRT · MRT · Bus · BRT · Monorail',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.white55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

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
                      _buildTabToggle(),
                      const SizedBox(height: 20),

                      if (_infoMessage != null)
                        _buildInfoMessage(_infoMessage!),
                      if (widget.authController.errorMessage != null)
                        _buildErrorMessage(widget.authController.errorMessage!),

                      if (!_isLogin) ...[
                        _buildField(
                          label: 'FULL NAME',
                          icon: Icons.person_outline_rounded,
                          controller: _nameController,
                          hint: 'Enter your full name',
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildField(
                        label: 'EMAIL ADDRESS',
                        icon: Icons.mail_outline_rounded,
                        controller: _emailController,
                        hint: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        label: 'PASSWORD',
                        icon: Icons.shield_outlined,
                        controller: _passwordController,
                        hint: '••••••••',
                        obscure: !_showPassword,
                        autocorrect: false,
                        enableSuggestions: false,
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

                      if (_isLogin) ...[
                        const SizedBox(height: 24),
                      ] else
                        const SizedBox(height: 24),

                      _buildPrimaryButton(),
                      const SizedBox(height: 20),

                      Text.rich(
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style: AppTypography.captionMedium.copyWith(
                            color: AppColors.iconGray,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: AppTypography.captionBold.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: AppTypography.captionBold.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
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
              onTap: () => _switchTab(isLogin),
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

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.severityCriticalBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.severityCriticalColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.severityCriticalColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.severityCriticalColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final isLoading = widget.authController.isLoading;

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
          onTap: isLoading
              ? null
              : (_isLogin ? _handleSignIn : _handleRegister),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _isLogin ? 'Sign In to SmartRoute' : 'Create My Account',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                    ),
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
    TextInputType? keyboardType,
    bool autocorrect = true,
    bool enableSuggestions = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
                  keyboardType: keyboardType,
                  autocorrect: autocorrect,
                  enableSuggestions: enableSuggestions,
                  textCapitalization: textCapitalization,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: hint,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.iconGray,
                    ),
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
}
