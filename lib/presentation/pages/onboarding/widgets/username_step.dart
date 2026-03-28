import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../bloc/onboarding/profile_setup_cubit.dart';
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
  bool _checking = false;
  bool? _isAvailable; // null = not checked, true = available, false = taken

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

  Future<void> _checkAvailability() async {
    final value = _controller.text.trim();
    if (value.length < 3) return;
    setState(() {
      _checking = true;
      _isAvailable = null;
    });
    final available = await context
        .read<ProfileSetupCubit>()
        .checkUsernameAvailable(value);
    if (mounted) {
      setState(() {
        _checking = false;
        _isAvailable = available;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isAvailable != true) return;
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
                child: Column(
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
                        hintText: 'johndoe',
                      ),
                      autofocus: true,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      onChanged: (_) => setState(() => _isAvailable = null),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (v.trim().length < 3) {
                          return 'At least 3 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
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
                            _checking || _controller.text.trim().length < 3
                            ? null
                            : _checkAvailability,
                        icon: _checking
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: LoadingAnimationWidget.stretchedDots(
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
                          _checking ? 'Checking...' : 'Check availability',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide.none,
                        ),
                      ),
                    ),
                    if (!_checking && _isAvailable != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            _isAvailable! ? Icons.check_circle : Icons.cancel,
                            size: 20,
                            color: _isAvailable!
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isAvailable!
                                ? 'Username is available'
                                : 'Username is taken',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _isAvailable!
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
                      onPressed: _isAvailable == true ? _submit : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
