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
    expect(
      CollaborationEntity.statusFromKey('declined'),
      CollaborationStatus.declined,
    );
    expect(
      CollaborationEntity.statusFromKey('completed'),
      CollaborationStatus.completed,
    );
    expect(CollaborationEntity.statusFromKey('x'), null);
  });

  test('inequality when optional collaboration fields differ', () {
    final t = DateTime.utc(2026, 3, 1);
    final full = CollaborationEntity(
      id: '1',
      requesterId: 'a',
      targetUserId: 'b',
      description: 'd',
      status: CollaborationStatus.completed,
      title: 't',
      eventId: 'e',
      createdAt: t,
      budget: 99.5,
      date: t,
      startTime: '09:00',
      endTime: '17:00',
      location: 'Kigali',
      eventType: 'Gala',
      plannerConfirmedAt: t,
      creativeConfirmedAt: t,
    );
    const minimal = CollaborationEntity(
      id: '1',
      requesterId: 'a',
      targetUserId: 'b',
      description: 'd',
    );
    expect(full == minimal, isFalse);
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
