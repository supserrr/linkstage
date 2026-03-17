import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_entity.dart' show ProfileVisibility, WhoCanMessage;
import '../../bloc/settings/settings_cubit.dart';
import '../../bloc/settings/settings_state.dart';

/// Shared form for privacy settings: profile visibility, who can message, and
/// show online status. Used by both the privacy settings page and settings sheet.
class PrivacySettingsForm extends StatelessWidget {
  const PrivacySettingsForm({
    super.key,
    this.sectionHeaderStyle,
  });

  /// Optional custom style for section headers. If null, uses theme defaults.
  final TextStyle? sectionHeaderStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final headerStyle = sectionHeaderStyle ??
        theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        );

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Profile visibility',
                style: headerStyle,
              ),
            ),
            RadioGroup<ProfileVisibility>(
              groupValue: state.profileVisibility,
              onChanged: (v) {
                if (v != null) {
                  context.read<SettingsCubit>().setProfileVisibility(v);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RadioListTile<ProfileVisibility>(
                    title: const Text('Everyone'),
                    subtitle: const Text(
                      'Your profile is visible to all users',
                    ),
                    value: ProfileVisibility.everyone,
                  ),
                  RadioListTile<ProfileVisibility>(
                    title: const Text('Connections only'),
                    subtitle: const Text(
                      'Only people you\'ve connected with',
                    ),
                    value: ProfileVisibility.connectionsOnly,
                  ),
                  RadioListTile<ProfileVisibility>(
                    title: const Text('Only me'),
                    subtitle: const Text('Profile is private'),
                    value: ProfileVisibility.onlyMe,
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Who can message you',
                style: headerStyle,
              ),
            ),
            RadioGroup<WhoCanMessage>(
              groupValue: state.whoCanMessage,
              onChanged: (v) {
                if (v != null) {
                  context.read<SettingsCubit>().setWhoCanMessage(v);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RadioListTile<WhoCanMessage>(
                    title: const Text('Everyone'),
                    subtitle: const Text(
                      'Any user can send you messages',
                    ),
                    value: WhoCanMessage.everyone,
                  ),
                  RadioListTile<WhoCanMessage>(
                    title: const Text('People you\'ve worked with'),
                    subtitle: const Text(
                      'Only after a completed booking',
                    ),
                    value: WhoCanMessage.workedWith,
                  ),
                  RadioListTile<WhoCanMessage>(
                    title: const Text('No one'),
                    subtitle: const Text('Disable direct messages'),
                    value: WhoCanMessage.noOne,
                  ),
                ],
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Show when you\'re active'),
              subtitle: const Text(
                'Let others see when you were last active',
              ),
              value: state.showOnlineStatus,
              onChanged: (v) =>
                  context.read<SettingsCubit>().setShowOnlineStatus(v),
            ),
          ],
        );
      },
    );
  }
}
