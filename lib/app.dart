import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/settings/settings_cubit.dart';
import 'presentation/bloc/settings/settings_state.dart';

/// Root application widget.
class LinkStageApp extends StatelessWidget {
  const LinkStageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>(),
      child: BlocProvider<SettingsCubit>.value(
        value: sl<SettingsCubit>(),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          bloc: sl<SettingsCubit>(),
          builder: (context, settings) {
            return MaterialApp.router(
              title: 'LinkStage',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: settings.themeMode,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(settings.language),
              routerConfig: AppRouter.router,
            );
          },
        ),
      ),
    );
  }
}
