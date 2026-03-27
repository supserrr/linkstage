import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/atoms/app_button.dart';
import '../../widgets/atoms/auth_sign_illustration.dart';
import '../../widgets/atoms/glass_card.dart';

/// Shown after sending sign-in link, or when authenticated but email not verified.
class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key, this.email = ''});

  final String email;

  @override
  Widget build(BuildContext context) {
    final auth = sl<AuthRepository>();
    final isLinkSentFlow = email.isNotEmpty;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: const Center(
                    child: AuthSignIllustration(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: isLinkSentFlow
                      ? _LinkSentView(email: email)
                      : _UnverifiedView(onSignOut: () async {
                          await auth.signOut();
                          if (context.mounted) {
                            context.go(AppRoutes.login);
                          }
                        }),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkSentView extends StatelessWidget {
  const _LinkSentView({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.home);
        }
        if (state is AuthError) {
          showToast(context, state.message, isError: true);
        }
        if (state is AuthLinkSent) {
          showToast(context, 'Link sent. Check your email.');
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Check your email',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a sign-in link to $email. Click the link to sign in.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Resend link',
              onPressed: loading
                  ? null
                  : () {
                      context.read<AuthBloc>().add(
                            AuthSendSignInLinkRequested(email: email),
                          );
                    },
              isLoading: loading,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: loading ? null : () => context.go(AppRoutes.login),
              child: const Text('Use a different email'),
            ),
          ],
        );
      },
    );
  }
}

class _UnverifiedView extends StatelessWidget {
  const _UnverifiedView({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Verify your email',
          style: Theme.of(context)
              .textTheme
              .headlineLarge
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your account needs verification. Sign out and sign in with the email link to verify.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Sign out',
          onPressed: onSignOut,
        ),
      ],
    );
  }
}
