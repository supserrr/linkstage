import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../widgets/atoms/glass_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_borders.dart';
import '../../core/di/injection.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth/update_email_usecase.dart';
import '../../domain/usecases/user/change_username_usecase.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/change_email/change_email_cubit.dart';
import '../bloc/change_email/change_email_state.dart';
import '../bloc/change_username/change_username_cubit.dart';
import '../bloc/change_username/change_username_state.dart';
import '../bloc/settings/settings_cubit.dart';
import '../bloc/settings/settings_state.dart';
import '../widgets/molecules/privacy_settings_form.dart';
import '../widgets/molecules/profile_avatar.dart';
import '../../core/router/app_router.dart';
import '../../core/router/auth_redirect.dart';
import '../../l10n/app_localizations.dart';

/// Settings page with My Profile header, centered profile section, and account
/// settings in a contained card (dummy UI style).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<SettingsCubit>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  String? _lastLoadedUserId;

  @override
  Widget build(BuildContext context) {
    final authNotifier = sl<AuthRedirectNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myProfile),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListenableBuilder(
        listenable: authNotifier,
        builder: (context, _) {
          final user = authNotifier.user;
          final role = user?.role;
          final userId = user?.id;
          if (userId != null && userId != _lastLoadedUserId) {
            _lastLoadedUserId = userId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<SettingsCubit>().loadFromBackend(userId);
            });
          }
          return BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _ProfileHeader(user: user, role: role),
                        const SizedBox(height: 20),
                        _AccountSettingsCard(
                          user: user,
                          state: state,
                          onLanguageTap: () =>
                              _showLanguagePicker(context, state),
                        ),
                        const SizedBox(height: 20),
                        _SignOutTile(
                          onTap: () {
                            context
                                .read<AuthBloc>()
                                .add(AuthSignOutRequested());
                          },
                        ),
                      ]),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.user, this.role});

  final dynamic user;
  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    final photoUrl = (user?.photoUrl as String?) ??
        sl<AuthRepository>().currentUser?.photoUrl;
    final displayName = user?.displayName ?? user?.email ?? 'User';
    final email = user?.email ?? '—';
    final editRoute = role == UserRole.eventPlanner
        ? AppRoutes.plannerProfile
        : AppRoutes.creativeProfile;

    return Column(
      children: [
        GestureDetector(
          onTap: () => context.push(AppRoutes.viewProfile),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              ProfileAvatar(
                photoUrl: photoUrl,
                displayName: displayName,
                radius: 48,
              ),
              GestureDetector(
                onTap: () => context.push(editRoute),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName.isNotEmpty ? displayName : 'User',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ) ??
              const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _AccountSettingsCard extends StatelessWidget {
  const _AccountSettingsCard({
    required this.user,
    required this.state,
    required this.onLanguageTap,
  });

  final dynamic user;
  final SettingsState state;
  final VoidCallback onLanguageTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.notifications_outlined,
            label: 'Notification',
            trailing: Switch(
              value: state.notificationsEnabled,
              onChanged: (v) =>
                  context.read<SettingsCubit>().setNotificationsEnabled(v),
            ),
          ),
          _SettingsDivider(colorScheme: colorScheme),
          _SettingsRow(
            icon: Icons.brightness_6_outlined,
            label: 'Light or Dark Interface',
            trailing: Switch(
              value: state.themeMode == ThemeMode.dark,
              onChanged: (v) {
                context.read<SettingsCubit>().setThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light,
                    );
              },
            ),
          ),
          _SettingsDivider(colorScheme: colorScheme),
          _SettingsRow(
            icon: Icons.language,
            label: 'Language',
            value: _languageLabel(state.language),
            onTap: onLanguageTap,
          ),
          _SettingsDivider(colorScheme: colorScheme),
          _SettingsRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user?.email ?? '—',
            onTap: () => _showChangeEmailSheet(context, user?.email),
          ),
          _SettingsDivider(colorScheme: colorScheme),
          _SettingsRow(
            icon: Icons.person_outline,
            label: 'Username',
            value: user?.username != null ? '@${user!.username}' : '—',
            onTap: () => _showChangeUsernameSheet(context, user),
          ),
          _SettingsDivider(colorScheme: colorScheme),
          _SettingsRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy',
            onTap: () => _showPrivacySheet(context),
          ),
          _SettingsDivider(colorScheme: colorScheme),
          _SettingsRow(
            icon: Icons.support_agent_outlined,
            label: 'Contact Support',
            onTap: () => _showContactSupportSheet(context),
          ),
        ],
      ),
    );
  }

}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const rowHeight = 52.0;
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorders.borderRadius,
      child: SizedBox(
        height: rowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                ),
              ),
              if (trailing != null)
                trailing!
              else ...[
              if (value != null) ...[
                Text(
                  value!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                if (onTap != null) const SizedBox(width: 8),
              ],
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16 + 22 + 14,
      endIndent: 16,
      color: colorScheme.outline.withValues(alpha: 0.3),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      child: const Text('Sign out'),
    );
  }
}

String _languageLabel(String code) {
  switch (code) {
    case 'en':
      return 'English';
    case 'fr':
      return 'Francais';
    case 'rw':
      return 'Kinyarwanda';
    case 'sw':
      return 'Kiswahili';
    default:
      return code;
  }
}

void _showLanguagePicker(BuildContext context, SettingsState state) {
  const languages = [
    ('en', 'English'),
    ('fr', 'Francais'),
    ('rw', 'Kinyarwanda'),
    ('sw', 'Kiswahili'),
  ];
  final cubit = context.read<SettingsCubit>();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => GlassBottomSheet(
      child: SafeArea(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Language',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          ...languages.map((l) => ListTile(
                title: Text(l.$2),
                trailing: state.language == l.$1
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  cubit.setLanguage(l.$1);
                  Navigator.pop(ctx);
                },
              )),
        ],
      ),
    ),
  ),
);
}

void _showChangeEmailSheet(BuildContext context, String? currentEmail) {
  if (currentEmail == null || currentEmail.isEmpty) {
    showToast(context, 'Please sign in to change your email', isError: true);
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => GlassBottomSheet(
      child: BlocProvider(
        create: (_) => ChangeEmailCubit(sl<UpdateEmailUseCase>()),
        child: _ChangeEmailSheetContent(
          currentEmail: currentEmail,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    ),
  );
}

void _showChangeUsernameSheet(BuildContext context, dynamic user) {
  if (user == null) {
    showToast(context, 'Please sign in to change your username', isError: true);
    return;
  }
  final userEntity = user as UserEntity;
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => GlassBottomSheet(
      child: BlocProvider(
        create: (_) => ChangeUsernameCubit(
          sl<ChangeUsernameUseCase>(),
          userEntity,
        ),
        child: _ChangeUsernameSheetContent(
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    ),
  );
}

void _showPrivacySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => GlassBottomSheet(
      child: BlocProvider.value(
        value: context.read<SettingsCubit>(),
        child: const _PrivacySheetContent(),
      ),
    ),
  );
}

class _ChangeEmailSheetContent extends StatefulWidget {
  const _ChangeEmailSheetContent({
    required this.currentEmail,
    required this.onClose,
  });

  final String currentEmail;
  final VoidCallback onClose;

  @override
  State<_ChangeEmailSheetContent> createState() =>
      _ChangeEmailSheetContentState();
}

class _ChangeEmailSheetContentState extends State<_ChangeEmailSheetContent> {
  final _newEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _newEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangeEmailCubit, ChangeEmailState>(
      listener: (context, state) {
        if (state.success) {
          sl<AuthRedirectNotifier>().refresh();
          if (context.mounted) {
            showToast(
              context,
              'Verification email sent. Check your new inbox to complete the change.',
            );
            widget.onClose();
          }
        }
        if (state.error != null) {
          showToast(context, state.error!, isError: true);
        }
      },
      builder: (context, state) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Change email',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
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
                      'We will send a verification link to your new email.',
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
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            )
                          : const Text('Send verification email'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChangeUsernameSheetContent extends StatefulWidget {
  const _ChangeUsernameSheetContent({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_ChangeUsernameSheetContent> createState() =>
      _ChangeUsernameSheetContentState();
}

class _ChangeUsernameSheetContentState extends State<_ChangeUsernameSheetContent> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ChangeUsernameCubit>();
    final current = cubit.state.currentUsername;
    if (current != null && current.isNotEmpty) {
      _controller.text = current.replaceFirst('@', '');
    }
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final value = _controller.text.trim();
      if (value.isNotEmpty && context.mounted) {
        context.read<ChangeUsernameCubit>().checkAvailability(value);
      } else if (context.mounted) {
        context.read<ChangeUsernameCubit>().clearValidation();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    context.read<ChangeUsernameCubit>().submit(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangeUsernameCubit, ChangeUsernameState>(
      listener: (context, state) {
        if (state.status == ChangeUsernameStatus.success) {
          if (context.mounted) {
            sl<AuthRedirectNotifier>().refresh();
            showToast(context, 'Username updated');
            widget.onClose();
          }
        }
        if (state.status == ChangeUsernameStatus.error &&
            state.errorMessage != null) {
          showToast(context, state.errorMessage!, isError: true);
        }
      },
      builder: (context, state) {
        final canChange = state.canChangeUsername;
        String? cooldownMessage;
        if (state.nextChangeDate != null) {
          cooldownMessage =
              'You can change your username again on ${state.nextChangeDate}';
        }
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Change username',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (cooldownMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      cooldownMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixText: '@',
                      hintText: 'username',
                      errorText: state.validationError,
                      suffixIcon: state.isCheckingAvailability
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: LoadingAnimationWidget.stretchedDots(
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                            )
                          : null,
                    ),
                    textInputAction: TextInputAction.done,
                    enabled: canChange && !state.isSubmitting,
                    onSubmitted: (_) => _submit(context),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: canChange &&
                            !state.isSubmitting &&
                            state.isAvailable == true &&
                            _controller.text.trim().length >= 3
                        ? () => _submit(context)
                        : null,
                    child: state.isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: LoadingAnimationWidget.stretchedDots(
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrivacySheetContent extends StatelessWidget {
  const _PrivacySheetContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Privacy',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const PrivacySettingsForm(),
          ],
        ),
      ),
    );
  }
}

void _showContactSupportSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => GlassBottomSheet(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              'Contact Support',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Get help from our support team.',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.parse('mailto:support@linkstage.app');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.email_outlined),
              label: const Text('Email support'),
            ),
          ],
          ),
        ),
      ),
    ),
  );
}

