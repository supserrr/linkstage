import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/presentation/bloc/onboarding/profile_setup_cubit.dart';
import 'package:linkstage/presentation/bloc/onboarding/profile_setup_state.dart';
import 'package:linkstage/presentation/bloc/onboarding/username_step_cubit.dart';
import 'package:linkstage/presentation/pages/onboarding/widgets/username_step.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:flutter/services.dart';

class _ProfileSetupLikeCubit extends Cubit<ProfileSetupState>
    implements ProfileSetupCubit {
  _ProfileSetupLikeCubit() : super(const ProfileSetupState());

  var checked = 0;

  Future<bool> checkUsernameAvailable(String username) async {
    checked++;
    return true;
  }

  void setUsername(String value) {
    emit(state.copyWith(username: value));
  }

  @override
  void clearPhotoAndError() {}

  @override
  void setBio(String value) {}

  @override
  void setCategory(ProfileCategory? value) {}

  @override
  void setDisplayName(String value) {}

  @override
  void setLocation(String value) {}

  @override
  void setPhoto(dynamic file) {}

  @override
  void setPriceRange(String value) {}

  @override
  Future<void> submit() async {}

  @override
  Future<bool> uploadSelectedPhoto() async => true;
}

class _TestAssetBundle extends CachingAssetBundle {
  static const _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"></svg>';

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(_svg.codeUnits);
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _svg;
}

void main() {
  testWidgets('UsernameStep validates and can check availability', (
    tester,
  ) async {
    final profileSetup = _ProfileSetupLikeCubit();
    final usernameCubit = UsernameStepCubit(profileSetup);

    var next = 0;
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _TestAssetBundle(),
        child: MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<ProfileSetupCubit>.value(value: profileSetup),
                BlocProvider<UsernameStepCubit>.value(value: usernameCubit),
              ],
              child: UsernameStep(onNext: () => next++),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Enter valid username.
    final field = find.byType(TextFormField);
    expect(field, findsOneWidget);
    await tester.enterText(field, 'marie_uwimana');
    await tester.pump();

    // Check availability button should be enabled.
    await tester.tap(find.text('Check availability'));
    await tester.pump();

    expect(profileSetup.checked, 1);
    expect(next, 0);
  });
}
