import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/utils/image_url_utils.dart';

void main() {
  test('thumbnailUrl returns empty for empty url', () {
    expect(ImageUrlUtils.thumbnailUrl(''), '');
  });

  test('thumbnailUrl returns url unchanged', () {
    const u = 'https://example.com/a.png';
    expect(ImageUrlUtils.thumbnailUrl(u), u);
    expect(ImageUrlUtils.thumbnailUrl(u, width: 200, height: 200), u);
  });
}
