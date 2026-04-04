/// Image URLs for avatars / portfolio. We keep raw storage URLs: Supabase
/// `/render/image/` transforms need a paid plan, so resizing params are ignored.
class ImageUrlUtils {
  ImageUrlUtils._();

  /// Pass-through URL; [width]/[height] reserved for future paid-tier transforms.
  static String thumbnailUrl(String url, {int width = 96, int height = 96}) {
    if (url.isEmpty) return url;
    return url;
  }
}
