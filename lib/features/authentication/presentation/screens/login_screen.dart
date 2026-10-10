import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.monitor_heart_outlined,
                        size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: AppSizes.md),
                    Text(l.welcomeBack,
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSizes.sm),
                    Text(l.signInSubtitle,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.outline),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSizes.xl),
                    AppTextField(
                      controller: _emailCtrl,
                      label: l.email,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email(context),
                    ),
                    const SizedBox(height: AppSizes.md),
                    AppTextField(
                      controller: _passCtrl,
                      label: l.password,
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: Validators.password(context),
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: AppSizes.md),
                      Text(auth.error!,
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: AppSizes.lg),
                    PrimaryButton(
                      label: l.signIn,
                      isLoading: auth.isLoading,
                      onPressed: _submit,
                    ),
                    if (Env.useMockAuth) ...[
                      const SizedBox(height: AppSizes.md),
                      Text(l.demoHint,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline),
                          textAlign: TextAlign.center),
                    ],
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
