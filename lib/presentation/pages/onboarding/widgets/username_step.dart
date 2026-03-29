import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../bloc/onboarding/profile_setup_cubit.dart';
import '../../../bloc/onboarding/username_step_cubit.dart';
import '../../../bloc/onboarding/username_step_state.dart';
import '../../../widgets/atoms/app_button.dart';
import '../../../widgets/atoms/glass_card.dart';

class UsernameStep extends StatefulWidget {
  const UsernameStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<UsernameStep> createState() => _UsernameStepState();
}

class _UsernameStepState extends State<UsernameStep> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final username = context.read<ProfileSetupCubit>().state.username;
    if (username != null && username.isNotEmpty) {
      _controller.text = username;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability(BuildContext context) async {
    await context.read<UsernameStepCubit>().checkAvailability(_controller.text);
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (context.read<UsernameStepCubit>().state.isAvailable != true) return;
    final value = _controller.text.trim();
    if (value.length < 3) return;
    context.read<ProfileSetupCubit>().setUsername(value);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/images/username_page_illustration_dark.svg'
        : 'assets/images/username_page_illustration_light.svg';
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final titleGap = keyboardVisible ? 20.0 : 32.0;
    final bottomGap = keyboardVisible ? 16.0 : 24.0;

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SvgPicture.asset(asset, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return BlocBuilder<UsernameStepCubit, UsernameStepState>(
                      builder: (context, availState) {
                        final checking = availState.checking;
                        final isAvailable = availState.isAvailable;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Choose your username',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '3-20 characters. Letters, numbers, underscore only.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: titleGap),
                            TextFormField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixText: '@ ',
                                hintText: 'marie_uwimana',
                              ),
                              autofocus: true,
                              textCapitalization: TextCapitalization.none,
                              autocorrect: false,
                              onChanged: (_) => context
                                  .read<UsernameStepCubit>()
                                  .onUsernameChanged(),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Username is required';
                                }
                                if (v.trim().length < 3) {
                                  return 'At least 3 characters';
                                }
                                if (!RegExp(
                                  r'^[a-zA-Z0-9_]+$',
                                ).hasMatch(v.trim())) {
                                  return 'Letters, numbers, underscore only';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed:
                                    checking ||
                                        _controller.text.trim().length < 3
                                    ? null
                                    : () => _checkAvailability(context),
                                icon: checking
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child:
                                            LoadingAnimationWidget.stretchedDots(
                                              color: theme.colorScheme.primary,
                                              size: 20,
                                            ),
                                      )
                                    : Icon(
                                        Icons.search,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                label: Text(
                                  checking
                                      ? 'Checking...'
                                      : 'Check availability',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                  side: BorderSide.none,
                                ),
                              ),
                            ),
                            if (!checking && isAvailable != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    isAvailable
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 20,
                                    color: isAvailable
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAvailable
                                        ? 'Username is available'
                                        : 'Username is taken',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isAvailable
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            SizedBox(height: bottomGap),
                            AppButton(
                              label: 'Next',
                              onPressed: isAvailable == true
                                  ? () => _submit(context)
                                  : null,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
