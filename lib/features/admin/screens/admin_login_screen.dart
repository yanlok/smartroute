import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../admin_constants.dart';

class AdminLoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onBack;

  const AdminLoginScreen({
    super.key,
    required this.onLogin,
    required this.onBack,
  });

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _authenticationError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _authenticationError = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final validEmail =
        _emailController.text.trim().toLowerCase() == AdminConstants.demoEmail;
    final validPassword =
        _passwordController.text == AdminConstants.demoPassword;

    if (!validEmail || !validPassword) {
      setState(() {
        _authenticationError =
            'The email or password does not match the demo admin account.';
      });
      return;
    }

    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.gradientHeader,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.md,
              AppSpacing.pageHorizontal,
              AppSpacing.pageBottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      tooltip: 'Back to passenger login',
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.surface,
                    ),
                    const SizedBox(height: AppSpacing.sectionLg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.iconContainer),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: AppShadows.cardLg,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionLg),
                    Text(
                      AdminConstants.portalName,
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gapXs),
                    Text(
                      'Secure access to the SmartRoute admin workspace.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.white65,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionXxl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxl2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.loginCard,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Administrator sign in',
                              style: AppTypography.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.sectionXl),
                            TextFormField(
                              key: const Key('admin-email-field'),
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Enter the admin email address.'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.sectionLg),
                            TextFormField(
                              key: const Key('admin-password-field'),
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _showPassword
                                      ? 'Hide password'
                                      : 'Show password',
                                  onPressed: () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Enter the admin password.'
                                  : null,
                            ),
                            if (_authenticationError != null) ...[
                              const SizedBox(height: AppSpacing.sectionSm),
                              Text(
                                _authenticationError!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.sectionXl),
                            ElevatedButton.icon(
                              key: const Key('admin-login-button'),
                              onPressed: _submit,
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Sign In to Admin Portal'),
                            ),
                            const SizedBox(height: AppSpacing.sectionLg),
                            Container(
                              padding: const EdgeInsets.all(
                                AppSpacing.containerPadding,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              child: Text(
                                'Demo access\n${AdminConstants.demoEmail}\n'
                                '${AdminConstants.demoPassword}',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.secondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
