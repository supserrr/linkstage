import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/usecases/auth/update_email_usecase.dart';
import '../../bloc/change_email/change_email_cubit.dart';
import '../../bloc/change_email/change_email_state.dart';

/// Page to change email (sends verification to new address).
/// For Google users: re-authenticates with Google, then sends verification link.
/// For email-link users: shows message to sign out and sign in with new email.
class ChangeEmailPage extends StatelessWidget {
  const ChangeEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthRedirectNotifier>().user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Change email')),
        body: const Center(child: Text('Please sign in to change your email')),
      );
    }
    return BlocProvider(
      create: (_) => ChangeEmailCubit(sl<UpdateEmailUseCase>()),
      child: _ChangeEmailView(currentEmail: user.email),
    );
  }
}

class _ChangeEmailView extends StatefulWidget {
  const _ChangeEmailView({required this.currentEmail});

  final String currentEmail;

  @override
  State<_ChangeEmailView> createState() => _ChangeEmailViewState();
}

class _ChangeEmailViewState extends State<_ChangeEmailView> {
  final _newEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _newEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change email')),
      body: BlocConsumer<ChangeEmailCubit, ChangeEmailState>(
        listener: (context, state) {
          if (state.success) {
            sl<AuthRedirectNotifier>().refresh();
            if (context.mounted) {
              showToast(
                context,
                'Verification email sent. Check your new inbox to complete the change.',
              );
              context.pop();
            }
          }
          if (state.error != null) {
            showToast(context, state.error!, isError: true);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Current: ${widget.currentEmail}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _newEmailController,
                    decoration: const InputDecoration(
                      labelText: 'New email',
                      hintText: 'you@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: Validators.email,
                    enabled: !state.isSubmitting,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will send a verification link to your new email. '
                    'You may need to sign in with Google again to confirm.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: state.isSubmitting
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() == true) {
                              context.read<ChangeEmailCubit>().submit(
                                    _newEmailController.text.trim(),
                                  );
                            }
                          },
                    child: state.isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: LoadingAnimationWidget.stretchedDots(
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 20,
                            ),
                          )
                        : const Text('Send verification email'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
