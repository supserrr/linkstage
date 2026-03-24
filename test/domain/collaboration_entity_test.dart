import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';

void main() {
  test('statusFromKey', () {
    expect(
      CollaborationEntity.statusFromKey('pending'),
      CollaborationStatus.pending,
    );
    expect(
      CollaborationEntity.statusFromKey('accepted'),
      CollaborationStatus.accepted,
    );
    expect(CollaborationEntity.statusFromKey('x'), null);
  });

  test('displayTitle prefers title', () {
    const c = CollaborationEntity(
      id: '1',
      requesterId: 'a',
      targetUserId: 'b',
      description: 'x',
      title: 'My Title',
    );
    expect(c.displayTitle, 'My Title');
  });

  test('displayTitle uses eventType when title empty', () {
    const c = CollaborationEntity(
      id: '1',
      requesterId: 'a',
      targetUserId: 'b',
      description: 'x',
      eventType: 'Wedding',
    );
    expect(c.displayTitle, 'Wedding');
  });

  test('displayTitle truncates long description', () {
    final long = 'a' * 60;
    final c = CollaborationEntity(
      id: '1',
      requesterId: 'a',
      targetUserId: 'b',
      description: long,
    );
    expect(c.displayTitle.length, lessThan(54));
    expect(c.displayTitle.endsWith('...'), true);
  });

  test('displayTitle fallback Collaboration', () {
    const c = CollaborationEntity(
      id: '1',
      requesterId: 'a',
      targetUserId: 'b',
      description: '',
    );
    expect(c.displayTitle, 'Collaboration');
  });
}
