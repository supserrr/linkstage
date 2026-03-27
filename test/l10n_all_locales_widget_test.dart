import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/l10n/app_localizations.dart';

/// Exercises every `AppLocalizations` getter (and parameterized message) so
/// generated `app_localizations_*.dart` files contribute to full `lcov.info`.
void exerciseAllStrings(AppLocalizations l10n) {
  // Keep alphabetically grouped by section in app_localizations.dart for maintenance.
  expect(l10n.aboutEvent, isNotEmpty);
  expect(l10n.all, isNotEmpty);
  expect(l10n.allCreatives, isNotEmpty);
  expect(l10n.applicationSent, isNotEmpty);
  expect(l10n.applications, isNotEmpty);
  expect(l10n.apply, isNotEmpty);
  expect(l10n.applyToCollaborate, isNotEmpty);
  expect(l10n.appTitle, isNotEmpty);
  expect(l10n.budget, isNotEmpty);
  expect(l10n.budgetNotSpecified, isNotEmpty);
  expect(l10n.cancel, isNotEmpty);
  expect(l10n.category, isNotEmpty);
  expect(l10n.chat, isNotEmpty);
  expect(l10n.checkYourEmail, isNotEmpty);
  expect(l10n.clear, isNotEmpty);
  expect(l10n.concert, isNotEmpty);
  expect(l10n.conference, isNotEmpty);
  expect(l10n.connect, isNotEmpty);
  expect(l10n.connectWithCreatives, isNotEmpty);
  expect(l10n.contentCreator, isNotEmpty);
  expect(l10n.continueWithEmail, isNotEmpty);
  expect(l10n.continueWithGoogle, isNotEmpty);
  expect(l10n.corporate, isNotEmpty);
  expect(l10n.creatives, isNotEmpty);
  expect(l10n.decorator, isNotEmpty);
  expect(l10n.delete, isNotEmpty);
  expect(l10n.deleteEvent, isNotEmpty);
  expect(l10n.deleteEventConfirm, isNotEmpty);
  expect(l10n.edit, isNotEmpty);
  expect(l10n.email, isNotEmpty);
  expect(l10n.eventPlanners, isNotEmpty);
  expect(l10n.events, isNotEmpty);
  expect(l10n.explore, isNotEmpty);
  expect(l10n.filters, isNotEmpty);
  expect(l10n.findEventsGigsMixers, isNotEmpty);
  expect(l10n.gallery, isNotEmpty);
  expect(l10n.gigs, isNotEmpty);
  expect(l10n.home, isNotEmpty);
  expect(l10n.justNow, isNotEmpty);
  expect(l10n.language, isNotEmpty);
  expect(l10n.location, isNotEmpty);
  expect(l10n.markAllRead, isNotEmpty);
  expect(l10n.message, isNotEmpty);
  expect(l10n.music, isNotEmpty);
  expect(l10n.myProfile, isNotEmpty);
  expect(l10n.noCreativesFound, isNotEmpty);
  expect(l10n.noEventPlannersFound, isNotEmpty);
  expect(l10n.noMessagesYet, isNotEmpty);
  expect(l10n.noNotificationsHint, isNotEmpty);
  expect(l10n.noNotificationsYet, isNotEmpty);
  expect(l10n.noUpcomingEvents, isNotEmpty);
  expect(l10n.notifications, isNotEmpty);
  expect(l10n.older, isNotEmpty);
  expect(l10n.party, isNotEmpty);
  expect(l10n.photography, isNotEmpty);
  expect(l10n.privacy, isNotEmpty);
  expect(l10n.resendLink, isNotEmpty);
  expect(l10n.search, isNotEmpty);
  expect(l10n.seeAll, isNotEmpty);
  expect(l10n.sendMessageToStart, isNotEmpty);
  expect(l10n.sendSignInLink, isNotEmpty);
  expect(l10n.settings, isNotEmpty);
  expect(l10n.signInLinkSentMessage('a@b.com'), isNotEmpty);
  expect(l10n.signInOrCreateAccount, isNotEmpty);
  expect(l10n.signInToViewNotifications, isNotEmpty);
  expect(l10n.signOut, isNotEmpty);
  expect(l10n.theme, isNotEmpty);
  expect(l10n.thisWeek, isNotEmpty);
  expect(l10n.today, isNotEmpty);
  expect(l10n.topRated, isNotEmpty);
  expect(l10n.upcoming, isNotEmpty);
  expect(l10n.useDifferentEmail, isNotEmpty);
  expect(l10n.verifyEmailMessage, isNotEmpty);
  expect(l10n.verifyYourEmail, isNotEmpty);
  expect(l10n.wedding, isNotEmpty);
  expect(l10n.welcomeToLinkStage, isNotEmpty);
  expect(l10n.workshop, isNotEmpty);
  expect(l10n.yesterday, isNotEmpty);
}

void main() {
  test('loads English via delegate', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    exerciseAllStrings(l10n);
  });

  test('loads French via delegate', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    exerciseAllStrings(l10n);
  });

  test('loads Kinyarwanda via delegate', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('rw'));
    exerciseAllStrings(l10n);
  });

  test('loads Swahili via delegate', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('sw'));
    exerciseAllStrings(l10n);
  });

  test('lookupAppLocalizations throws for unsupported locale', () {
    expect(
      () => lookupAppLocalizations(const Locale('de')),
      throwsA(isA<FlutterError>()),
    );
  });

  test('AppLocalizations delegate shouldReload is false', () {
    expect(
      AppLocalizations.delegate.shouldReload(AppLocalizations.delegate),
      isFalse,
    );
  });
}
