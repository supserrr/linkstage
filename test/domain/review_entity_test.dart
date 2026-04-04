import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/review_entity.dart';

void main() {
  test('props equality', () {
    const a = ReviewEntity(
      id: '1',
      reviewerId: 'r',
      revieweeId: 'e',
      rating: 5,
    );
    expect(a, const ReviewEntity(
      id: '1',
      reviewerId: 'r',
      revieweeId: 'e',
      rating: 5,
    ));
    expect(a, isNot(const ReviewEntity(
      id: '2',
      reviewerId: 'r',
      revieweeId: 'e',
      rating: 5,
    )));
  });
}
