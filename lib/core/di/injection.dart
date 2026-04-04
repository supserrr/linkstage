import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/datasources/chat_user_remote_datasource.dart';
import '../../data/datasources/collaboration_remote_datasource.dart';
import '../../data/datasources/creative_past_work_preferences_remote_datasource.dart';
import '../../data/datasources/conversation_remote_datasource.dart';
import '../../data/datasources/portfolio_storage_datasource.dart';
import '../../data/datasources/event_remote_datasource.dart';
import '../../data/datasources/planner_profile_remote_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/datasources/review_remote_datasource.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../data/repositories/chat_user_repository_impl.dart';
import '../../data/repositories/collaboration_repository_impl.dart';
import '../../data/repositories/creative_past_work_preferences_repository_impl.dart';
import '../../data/repositories/conversation_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/followed_planners_repository_impl.dart';
import '../../data/repositories/saved_creatives_repository_impl.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../data/repositories/planner_profile_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/chat_user_repository.dart';
import '../../domain/repositories/collaboration_repository.dart';
import '../../domain/repositories/creative_past_work_preferences_repository.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/followed_planners_repository.dart';
import '../../domain/repositories/saved_creatives_repository.dart';
import '../../domain/repositories/planner_profile_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/auth/send_sign_in_link_usecase.dart';
import '../../domain/usecases/auth/sign_in_with_email_link_usecase.dart';
import '../../domain/usecases/auth/sign_in_with_google_usecase.dart';
import '../../domain/usecases/auth/sign_out_usecase.dart';
import '../../domain/usecases/auth/update_email_usecase.dart';
import '../../domain/usecases/user/change_username_usecase.dart';
import '../../domain/usecases/user/upsert_user_usecase.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/onboarding/onboarding_cubit.dart';
import '../../presentation/bloc/onboarding/profile_setup_draft_storage.dart';
import '../../presentation/bloc/settings/settings_cubit.dart';
import '../router/auth_redirect.dart';
import '../services/fcm_service.dart';
import '../services/push_notification_service.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Incremented when planner acknowledges home recent-activity items (prefs), so
/// [PlannerDashboardCubit] can rebuild while the home tab stays mounted in the shell.
final ValueNotifier<int> plannerHomeActivityAckRevision = ValueNotifier(0);

/// Initialize dependency injection.
Future<void> initInjection() async {
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(AuthRemoteDataSource.new);
  sl.registerLazySingleton<UserRemoteDataSource>(UserRemoteDataSource.new);
  sl.registerLazySingleton<PlannerProfileRemoteDataSource>(
    PlannerProfileRemoteDataSource.new,
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    ProfileRemoteDataSource.new,
  );
  sl.registerLazySingleton<EventRemoteDataSource>(EventRemoteDataSource.new);
  sl.registerLazySingleton<ReviewRemoteDataSource>(ReviewRemoteDataSource.new);
  sl.registerLazySingleton<BookingRemoteDataSource>(
    BookingRemoteDataSource.new,
  );
  sl.registerLazySingleton<PortfolioStorageDataSource>(
    PortfolioStorageDataSource.new,
  );
  sl.registerLazySingleton<ChatUserRemoteDataSource>(
    ChatUserRemoteDataSource.new,
  );
  sl.registerLazySingleton<ConversationRemoteDataSource>(
    ConversationRemoteDataSource.new,
  );
  sl.registerLazySingleton<CollaborationRemoteDataSource>(
    CollaborationRemoteDataSource.new,
  );
  sl.registerLazySingleton<CreativePastWorkPreferencesRemoteDataSource>(
    CreativePastWorkPreferencesRemoteDataSource.new,
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () =>
        AuthRepositoryImpl(sl<AuthRemoteDataSource>(), sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      sl<UserRemoteDataSource>(),
      sl<BookingRepository>(),
      sl<CollaborationRepository>(),
    ),
  );
  sl.registerLazySingleton<PlannerProfileRepository>(
    () => PlannerProfileRepositoryImpl(
      sl<PlannerProfileRemoteDataSource>(),
      sl<UserRepository>(),
    ),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      sl<ProfileRemoteDataSource>(),
      sl<UserRepository>(),
    ),
  );
  sl.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(sl<EventRemoteDataSource>()),
  );
  sl.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(
      sl<ReviewRemoteDataSource>(),
      sl<ProfileRepository>(),
    ),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(sl<BookingRemoteDataSource>()),
  );
  sl.registerLazySingleton<ChatUserRepository>(
    () => ChatUserRepositoryImpl(sl<ChatUserRemoteDataSource>()),
  );
  sl.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(
      sl<ConversationRemoteDataSource>(),
      sl<UserRepository>(),
    ),
  );
  sl.registerLazySingleton<CollaborationRepository>(
    () => CollaborationRepositoryImpl(sl<CollaborationRemoteDataSource>()),
  );
  sl.registerLazySingleton<CreativePastWorkPreferencesRepository>(
    () => CreativePastWorkPreferencesRepositoryImpl(
      sl<CreativePastWorkPreferencesRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<SavedCreativesRepository>(
    () => SavedCreativesRepositoryImpl(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<FollowedPlannersRepository>(
    () => FollowedPlannersRepositoryImpl(sl<PlannerProfileRepository>()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      sl<BookingRepository>(),
      sl<CollaborationRepository>(),
      sl<ConversationRepository>(),
      sl<EventRepository>(),
      sl<UserRepository>(),
      sl<UserRemoteDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SendSignInLinkUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(
    () => SignInWithEmailLinkUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => UpdateEmailUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => UpsertUserUseCase(sl<UserRepository>()));
  sl.registerLazySingleton(
    () => ChangeUsernameUseCase(sl<UserRepository>(), sl<ProfileRepository>()),
  );

  // Blocs (singleton so auth state is shared app-wide)
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      sendSignInLink: sl<SendSignInLinkUseCase>(),
      signInWithEmailLink: sl<SignInWithEmailLinkUseCase>(),
      signInWithGoogle: sl<SignInWithGoogleUseCase>(),
      signOut: sl<SignOutUseCase>(),
    ),
  );

  // Settings (requires async SharedPreferences)
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(
      prefs,
      userRepository: sl<UserRepository>(),
      authRepository: sl<AuthRepository>(),
      profileRepository: sl<ProfileRepository>(),
      plannerProfileRepository: sl<PlannerProfileRepository>(),
    ),
  );
  sl.registerLazySingleton<OnboardingCubit>(() => OnboardingCubit(prefs));
  sl.registerLazySingleton<ProfileSetupDraftStorage>(
    () => ProfileSetupDraftStorage(prefs),
  );

  // Router refresh (must be registered after AuthRepository)
  sl.registerLazySingleton<AuthRedirectNotifier>(
    () => AuthRedirectNotifier(
      sl<AuthRepository>(),
      sl<UserRepository>(),
      sl<ProfileRepository>(),
    ),
  );
  sl.registerLazySingleton<SplashNotifier>(
    () => SplashNotifier(sl<AuthRedirectNotifier>()),
  );

  sl.registerLazySingleton<FcmService>(
    () => FcmService(sl<UserRemoteDataSource>(), sl<AuthRepository>()),
  );
  sl.registerLazySingleton<PushNotificationService>(
    PushNotificationService.new,
  );
}
