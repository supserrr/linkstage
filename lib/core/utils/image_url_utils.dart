/// Utilities for image URLs.
/// Note: Supabase image transforms (/render/image/public/) require Pro plan.
/// Use the original public URL so images load on free tier.
class ImageUrlUtils {
  ImageUrlUtils._();

  /// Returns the URL for display. For Supabase/other storage, returns [url] as-is.
  /// [width] and [height] are ignored (transforms require Supabase Pro).
  static String thumbnailUrl(
    String url, {
    int width = 96,
    int height = 96,
  }) {
    if (url.isEmpty) return url;
    return url;
  }
}
