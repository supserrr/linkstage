import '../entities/event_entity.dart';
import '../entities/profile_entity.dart';

/// Weights for recommendation scoring.
const int _weightTypeProfessionMatch = 3;
const int _weightLocationMatch = 2;
const int _weightCategoryMatch = 2;

/// Keywords associated with each creative category for matching event text.
final Map<ProfileCategory, List<String>> _categoryKeywords = {
  ProfileCategory.dj: [
    'dj',
    'music',
    'party',
    'wedding',
    'corporate',
    'concert',
    'club',
    'entertainment',
  ],
  ProfileCategory.photographer: [
    'photo',
    'photography',
    'wedding',
    'portrait',
    'event',
    'corporate',
    'film',
  ],
  ProfileCategory.decorator: [
    'decor',
    'decoration',
    'wedding',
    'corporate',
    'venue',
    'floral',
    'design',
  ],
  ProfileCategory.contentCreator: [
    'content',
    'social',
    'video',
    'media',
    'influencer',
    'brand',
    'marketing',
  ],
};

/// Normalizes a string into a set of lowercase tokens (letters and digits).
Set<String> _normalizeWords(String? s) {
  if (s == null || s.trim().isEmpty) return {};
  final normalized = s.trim().toLowerCase();
  final tokens = normalized.split(RegExp(r'[\s,.\-_/]+'));
  return tokens.where((t) => t.length > 1).toSet();
}

/// Returns true if location strings match (normalized contains or equality).
bool _locationMatches(String? a, String? b) {
  if (a == null || b == null || a.trim().isEmpty || b.trim().isEmpty) {
    return false;
  }
  final na = a.trim().toLowerCase();
  final nb = b.trim().toLowerCase();
  return na == nb || na.contains(nb) || nb.contains(na);
}

/// Scores how well an event matches a creative's profile (higher = better fit).
/// Returns 0 if [profile] is null so events remain sortable by date.
int scoreEventForCreative(EventEntity event, ProfileEntity? profile) {
  if (profile == null) return 0;

  int score = 0;

  final eventWords = _normalizeWords(event.eventType)
    ..addAll(_normalizeWords(event.title))
    ..addAll(_normalizeWords(event.description));

  final profileWords = <String>{}
    ..addAll(profile.professions.expand((p) => _normalizeWords(p)))
    ..addAll(profile.services.expand((s) => _normalizeWords(s)));

  if (eventWords.isNotEmpty && profileWords.isNotEmpty) {
    final matches = eventWords.where((w) => profileWords.contains(w)).length;
    score += matches * _weightTypeProfessionMatch;
  }

  if (profile.category != null) {
    final keywords = _categoryKeywords[profile.category!] ?? [];
    final categoryWordSet = keywords.toSet();
    final categoryMatches = eventWords
        .where((w) => categoryWordSet.contains(w))
        .length;
    if (categoryMatches > 0) {
      score +=
          _weightCategoryMatch * (categoryMatches > 2 ? 2 : categoryMatches);
    }
  }

  if (_locationMatches(profile.location, event.location)) {
    score += _weightLocationMatch;
  }

  return score;
}
