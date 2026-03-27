import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../bloc/settings/settings_cubit.dart';
import '../../widgets/molecules/privacy_settings_form.dart';

/// Privacy settings page with industry-standard options.
class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<SettingsCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Privacy')),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: PrivacySettingsForm(
                sectionHeaderStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
