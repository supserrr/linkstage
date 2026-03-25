import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/review_remote_datasource.dart';

void main() {
  group('ReviewRemoteDataSource', () {
    test('createReview clamps rating and persists fields', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ReviewRemoteDataSource(firestore: fake);

      final created = await ds.createReview(
        bookingId: 'b1',
        reviewerId: 'u1',
        revieweeId: 'u2',
        rating: 99,
        comment: 'Nice',
      );

      expect(created.bookingId, 'b1');
      expect(created.rating, 5);
    });

    test('getReviewByBookingAndReviewer returns null when missing', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ReviewRemoteDataSource(firestore: fake);

      final r = await ds.getReviewByBookingAndReviewer('b1', 'u1');
      expect(r, isNull);
    });

    test('likeReview toggles likedBy + likeCount', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ReviewRemoteDataSource(firestore: fake);

      final ref = fake.collection('reviews').doc('r1');
      await ref.set({
        'bookingId': 'b1',
        'reviewerId': 'u1',
        'revieweeId': 'u2',
        'rating': 5,
        'comment': 'x',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'reply': '',
        'replyAt': null,
        'likeCount': 0,
        'likedBy': <String>[],
        'flagCount': 0,
        'flaggedBy': <String>[],
      });

      await ds.likeReview('r1', 'u3');
      var doc = await ref.get();
      expect(doc.data()?['likeCount'], 1);
      expect((doc.data()?['likedBy'] as List).contains('u3'), isTrue);

      await ds.likeReview('r1', 'u3');
      doc = await ref.get();
      expect(doc.data()?['likeCount'], 0);
      expect((doc.data()?['likedBy'] as List).contains('u3'), isFalse);
    });

    test('flagReview toggles flaggedBy + flagCount', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ReviewRemoteDataSource(firestore: fake);

      final ref = fake.collection('reviews').doc('r2');
      await ref.set({
        'bookingId': 'b1',
        'reviewerId': 'u1',
        'revieweeId': 'u2',
        'rating': 5,
        'comment': 'x',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'reply': '',
        'replyAt': null,
        'likeCount': 0,
        'likedBy': <String>[],
        'flagCount': 0,
        'flaggedBy': <String>[],
      });

      await ds.flagReview('r2', 'u3');
      var doc = await ref.get();
      expect(doc.data()?['flagCount'], 1);
      expect((doc.data()?['flaggedBy'] as List).contains('u3'), isTrue);

      await ds.flagReview('r2', 'u3');
      doc = await ref.get();
      expect(doc.data()?['flagCount'], 0);
      expect((doc.data()?['flaggedBy'] as List).contains('u3'), isFalse);
    });
  });
}
