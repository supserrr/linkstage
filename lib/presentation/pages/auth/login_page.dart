import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/atoms/app_button.dart';
import '../../widgets/atoms/app_text_field.dart';
import '../../widgets/atoms/auth_sign_illustration.dart';
import '../../widgets/atoms/glass_card.dart';
import '../../widgets/atoms/google_sign_in_button.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/utils/validators.dart';

/// Unified auth screen: Google Sign-In and Email Link (passwordless).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LoginView();
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _showEmailForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendEmailLink() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthSendSignInLinkRequested(email: _emailController.text.trim()),
        );
  }

  void _signInWithGoogle() {
    context.read<AuthBloc>().add(const AuthSignInWithGoogleRequested());
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final illustrationHeight = keyboardVisible
        ? 60.0
        : (screenHeight * 0.36).clamp(140.0, 280.0);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final compact = keyboardVisible;
    final topPad = compact ? 8.0 : 16.0;
    final cardPad = compact ? 12.0 : 24.0;
    final beforeInputs = compact ? 20.0 : 32.0;
    final betweenInputs = compact ? 12.0 : 16.0;
    final beforeButton = compact ? 16.0 : 24.0;
    final bottomPad = compact ? 8.0 : 24.0;

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: topPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: illustrationHeight),
                  child: const Center(
                    child: AuthSignIllustration(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlassCard(
                  padding: EdgeInsets.all(cardPad),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign In or Create Account',
                          style:
                              Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: beforeInputs),
                        BlocConsumer<AuthBloc, AuthState>(
                          listener: (context, state) {
                            if (state is AuthAuthenticated) {
                              context.go(AppRoutes.home);
                            }
                            if (state is AuthLinkSent) {
                              context.go(
                                Uri(
                                  path: AppRoutes.verifyEmail,
                                  queryParameters: {'email': state.email},
                                ).toString(),
                              );
                            }
                            if (state is AuthError) {
                              showToast(context, state.message, isError: true);
                            }
                          },
                          builder: (context, state) {
                            final loading = state is AuthLoading;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GoogleSignInButton(
                                  onPressed: loading ? null : _signInWithGoogle,
                                  isLoading: loading && !_showEmailForm,
                                ),
                                SizedBox(
                                  height: _showEmailForm
                                      ? betweenInputs
                                      : beforeButton,
                                ),
                                if (_showEmailForm) ...[
                                  AppTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.done,
                                    validator: Validators.email,
                                  ),
                                  SizedBox(height: beforeButton),
                                  AppButton(
                                    label: 'Send sign-in link',
                                    onPressed: loading ? null : _sendEmailLink,
                                    isLoading: loading,
                                  ),
                                  SizedBox(height: betweenInputs),
                                  TextButton(
                                    onPressed: loading
                                        ? null
                                        : () => setState(() => _showEmailForm = false),
                                    child: const Text('Back'),
                                  ),
                                ] else
                                  AppButton(
                                    label: 'Continue with Email',
                                    onPressed: loading
                                        ? null
                                        : () => setState(() => _showEmailForm = true),
                                    isLoading: false,
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: bottomPad + bottomPadding),
            ],
          ),
        ),
      ),
    );
  }
}
