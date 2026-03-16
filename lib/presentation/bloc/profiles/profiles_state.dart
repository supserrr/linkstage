import '../../../domain/entities/profile_entity.dart';

class ProfilesState {
  const ProfilesState({
    this.status = ProfilesStatus.initial,
    this.profiles = const [],
    this.searchQuery = '',
    this.error,
  });

  const ProfilesState.initial()
      : status = ProfilesStatus.initial,
        profiles = const [],
        searchQuery = '',
        error = null;

  const ProfilesState.loading({this.profiles = const [], this.searchQuery = ''})
      : status = ProfilesStatus.loading,
        error = null;

  ProfilesState.loaded(
    this.profiles, {
    this.searchQuery = '',
  })  : status = ProfilesStatus.loaded,
        error = null;

  ProfilesState.error(this.error, {this.profiles = const [], this.searchQuery = ''})
      : status = ProfilesStatus.error;

  final ProfilesStatus status;
  final List<ProfileEntity> profiles;
  final String searchQuery;
  final String? error;

  List<ProfileEntity> get filteredProfiles {
    if (searchQuery.trim().isEmpty) return profiles;
    final q = searchQuery.trim().toLowerCase();
    return profiles.where((p) {
      final un = (p.username ?? p.id).toLowerCase();
      final dn = (p.displayName ?? '').toLowerCase();
      return un.contains(q) || dn.contains(q);
    }).toList();
  }

}

enum ProfilesStatus { initial, loading, loaded, error }
