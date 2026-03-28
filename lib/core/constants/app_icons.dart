import 'package:flutter/material.dart';

/// Semantic icons for the app. Use these instead of [Icons] directly so each
/// concept maps to exactly one icon and the same icon is never used for
/// different meanings.
class AppIcons {
  AppIcons._();

  // --- Creative home: applications (events the creative has applied to) ---
  static const IconData applications = Icons.send_outlined;

  // --- Saved / bookmark (save for later) ---
  static const IconData savedOutline = Icons.bookmark_outline;
  static const IconData savedFilled = Icons.bookmark;

  // --- Gigs (completed bookings / work) ---
  static const IconData gigs = Icons.work_outline;

  // --- Applicants (people who applied; planner-facing) ---
  static const IconData applicants = Icons.people_outline;

  // --- Person / profile (avatar fallback, profile views) ---
  static const IconData person = Icons.person_outline;

  // --- Rating / star ---
  static const IconData rating = Icons.star;

  // --- Event (single event / placeholder) ---
  static const IconData event = Icons.event;

  // --- Date / calendar ---
  static const IconData date = Icons.calendar_today_outlined;

  // --- Location ---
  static const IconData location = Icons.location_on_outlined;

  // --- Messages (conversations) ---
  static const IconData messages = Icons.message_outlined;

  // --- Unread / chat (planner summary) ---
  static const IconData unread = Icons.chat_bubble_outline;

  // --- Notifications ---
  static const IconData notifications = Icons.notifications_outlined;

  // --- Navigation (bottom nav, list items) ---
  static const IconData home = Icons.home_outlined;
  static const IconData search = Icons.search;
  static const IconData eventsNav = Icons.event_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData chevronRight = Icons.chevron_right;

  // --- Actions ---
  static const IconData add = Icons.add;

  // --- Activity / proposal (e.g. "creative sent a proposal") ---
  static const IconData proposal = Icons.description_outlined;
}
