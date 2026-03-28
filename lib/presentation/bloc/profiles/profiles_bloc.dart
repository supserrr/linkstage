import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/profile_entity.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'profiles_state.dart';

/// Delay before showing loading UI. If Firestore cache responds first, we never show loading.
const Duration _deferredLoadingDelay = Duration(milliseconds: 150);

class ProfilesBloc extends Bloc<ProfilesEvent, ProfilesState> {
  ProfilesBloc(
    this._repository, {
    String? excludeUserId,
    bool onlyCreativeAccounts = false,
  }) : _excludeUserId = excludeUserId,
       _onlyCreativeAccounts = onlyCreativeAccounts,
       super(const ProfilesState.initial()) {
    on<ProfilesLoadRequested>(_onLoad);
    on<ProfilesProfilesReceived>(_onProfilesReceived);
    on<ProfilesLoadFailed>(_onLoadFailed);
    on<ProfilesFilterChanged>(_onFilterChanged);
    on<ProfilesSearchQueryChanged>(_onSearchQueryChanged);
  }

  final ProfileRepository _repository;
  final String? _excludeUserId;
  final bool _onlyCreativeAccounts;
  StreamSubscription<List<ProfileEntity>>? _profilesSubscription;
  Timer? _loadingDeferTimer;
  int _loadId = 0;

  Future<void> _onLoad(
    ProfilesLoadRequested event,
    Emitter<ProfilesState> emit,
  ) async {
    await _profilesSubscription?.cancel();
    _loadingDeferTimer?.cancel();
    final loadId = ++_loadId;
    try {
      _profilesSubscription = _repository
          .getProfiles(
            category: event.category,
            location: event.location,
            excludeUserId: _excludeUserId,
            onlyCreativeAccounts: _onlyCreativeAccounts,
          )
          .listen(
            (profiles) => add(ProfilesProfilesReceived(profiles)),
            onError: (e) => add(ProfilesLoadFailed(e.toString())),
          );
      _loadingDeferTimer = Timer(_deferredLoadingDelay, () {
        if (loadId == _loadId && !isClosed) {
          _loadingDeferTimer = null;
          emit(
            ProfilesState.loading(
              profiles: state.profiles,
              searchQuery: state.searchQuery,
            ),
          );
        }
      });
    } catch (e) {
      emit(ProfilesState.error(e.toString()));
    }
  }

  void _onProfilesReceived(
    ProfilesProfilesReceived event,
    Emitter<ProfilesState> emit,
  ) {
    _loadingDeferTimer?.cancel();
    _loadingDeferTimer = null;
    emit(ProfilesState.loaded(event.profiles, searchQuery: state.searchQuery));
  }

  void _onLoadFailed(ProfilesLoadFailed event, Emitter<ProfilesState> emit) {
    _loadingDeferTimer?.cancel();
    _loadingDeferTimer = null;
    emit(ProfilesState.error(event.message));
  }

  void _onSearchQueryChanged(
    ProfilesSearchQueryChanged event,
    Emitter<ProfilesState> emit,
  ) {
    emit(
      ProfilesState(
        status: state.status,
        profiles: state.profiles,
        searchQuery: event.query,
        error: state.error,
      ),
    );
  }

  Future<void> _onFilterChanged(
    ProfilesFilterChanged event,
    Emitter<ProfilesState> emit,
  ) async {
    add(
      ProfilesLoadRequested(category: event.category, location: event.location),
    );
  }

  @override
  Future<void> close() {
    _loadingDeferTimer?.cancel();
    _profilesSubscription?.cancel();
    return super.close();
  }
}

abstract class ProfilesEvent {}

class ProfilesLoadRequested extends ProfilesEvent {
  ProfilesLoadRequested({this.category, this.location});

  final ProfileCategory? category;
  final String? location;
}

class ProfilesFilterChanged extends ProfilesEvent {
  ProfilesFilterChanged({this.category, this.location});

  final ProfileCategory? category;
  final String? location;
}

class ProfilesSearchQueryChanged extends ProfilesEvent {
  ProfilesSearchQueryChanged(this.query);
  final String query;
}

class ProfilesProfilesReceived extends ProfilesEvent {
  ProfilesProfilesReceived(this.profiles);
  final List<ProfileEntity> profiles;
}

class ProfilesLoadFailed extends ProfilesEvent {
  ProfilesLoadFailed(this.message);
  final String message;
}
