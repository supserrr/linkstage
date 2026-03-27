import 'package:flutter/material.dart';

import '../../../domain/entities/user_entity.dart' show ProfileVisibility, WhoCanMessage;

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.language = 'en',
    this.profileVisibility = ProfileVisibility.everyone,
    this.whoCanMessage = WhoCanMessage.everyone,
    this.showOnlineStatus = true,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final String language;
  final ProfileVisibility profileVisibility;
  final WhoCanMessage whoCanMessage;
  final bool showOnlineStatus;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    String? language,
    ProfileVisibility? profileVisibility,
    WhoCanMessage? whoCanMessage,
    bool? showOnlineStatus,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      whoCanMessage: whoCanMessage ?? this.whoCanMessage,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
    );
  }
}
