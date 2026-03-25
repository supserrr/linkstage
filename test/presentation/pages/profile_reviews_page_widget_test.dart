import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/review_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/presentation/bloc/profile_reviews/profile_reviews_cubit.dart';
import 'package:linkstage/presentation/bloc/profile_reviews/profile_reviews_state.dart';
import 'package:linkstage/presentation/pages/profile/profile_reviews_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockProfileReviewsCubit extends MockCubit<ProfileReviewsState>
    implements ProfileReviewsCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ProfileReviewsState(revieweeUserId: 'x'));
  });

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows loader when signed out', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(null);
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    await tester.pumpWidget(const MaterialApp(home: ProfileReviewsPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ProfileReviewsPage), findsOneWidget);
    expect(find.text('Reviews'), findsNothing);
  });

  testWidgets('shows empty state when no reviews', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockProfileReviewsCubit();
    const seeded = ProfileReviewsState(
      revieweeUserId: 'creative-1',
      reviews: [],
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<ProfileReviewsState>(
      cubit,
      const Stream<ProfileReviewsState>.empty(),
      initialState: seeded,
    );

    await tester.pumpWidget(
      MaterialApp(home: ProfileReviewsPage(profileReviewsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Reviews'), findsOneWidget);
    expect(find.text('No reviews yet'), findsOneWidget);
  });

  testWidgets('tapping Like calls cubit.likeReview', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockProfileReviewsCubit();
    final review = ReviewEntity(
      id: 'r1',
      reviewerId: 'u2',
      revieweeId: 'creative-1',
      rating: 5,
      comment: 'Great',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final seeded = ProfileReviewsState(
      revieweeUserId: 'creative-1',
      reviews: [review],
      reviewAuthorsById: const {},
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<ProfileReviewsState>(
      cubit,
      const Stream<ProfileReviewsState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.likeReview(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(home: ProfileReviewsPage(profileReviewsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.thumb_up_outlined).first);
    await tester.pump();

    verify(() => cubit.likeReview('r1')).called(1);
  });
}
