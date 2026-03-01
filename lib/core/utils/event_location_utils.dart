import '../../domain/entities/event_entity.dart';

/// Placeholder when the viewer cannot see the real address.
const String kEventLocationHiddenPlaceholder = 'Location on request';

/// Placeholder for venue/place name when location is hidden.
const String kEventVenueHiddenPlaceholder = 'Private location';

/// Whether the viewer may see the real venue and address for [event].
/// The event planner always sees full location.
bool eventLocationIsVisible(
  EventEntity event, {
  required bool isPlanner,
  required bool hasAcceptedBooking,
}) {
  if (isPlanner) return true;
  switch (event.locationVisibility) {
    case LocationVisibility.public:
      return true;
    case LocationVisibility.private:
      return false;
    case LocationVisibility.acceptedCreatives:
      return hasAcceptedBooking;
  }
}

/// Single-line location text for list cards (typically the address field).
String getEventLocationDisplayLine(
  EventEntity event, {
  required bool isPlanner,
  required bool hasAcceptedBooking,
}) {
  if (!eventLocationIsVisible(
    event,
    isPlanner: isPlanner,
    hasAcceptedBooking: hasAcceptedBooking,
  )) {
    return kEventLocationHiddenPlaceholder;
  }
  return event.location.isNotEmpty ? event.location : '—';
}

/// Place name for detail row when visible; placeholder when hidden.
String getEventVenueDisplay(
  EventEntity event, {
  required bool isPlanner,
  required bool hasAcceptedBooking,
}) {
  if (!eventLocationIsVisible(
    event,
    isPlanner: isPlanner,
    hasAcceptedBooking: hasAcceptedBooking,
  )) {
    return kEventVenueHiddenPlaceholder;
  }
  return event.venueName.isNotEmpty ? event.venueName : 'Place';
}

/// Address line for detail row when visible; placeholder when hidden.
String getEventAddressDisplay(
  EventEntity event, {
  required bool isPlanner,
  required bool hasAcceptedBooking,
}) {
  if (!eventLocationIsVisible(
    event,
    isPlanner: isPlanner,
    hasAcceptedBooking: hasAcceptedBooking,
  )) {
    return kEventLocationHiddenPlaceholder;
  }
  return event.location.isNotEmpty ? event.location : 'Address not specified';
}

/// Destination string for maps when the viewer can open directions.
String? eventMapsDestinationIfVisible(
  EventEntity event, {
  required bool isPlanner,
  required bool hasAcceptedBooking,
}) {
  if (!eventLocationIsVisible(
    event,
    isPlanner: isPlanner,
    hasAcceptedBooking: hasAcceptedBooking,
  )) {
    return null;
  }
  if (event.location.isNotEmpty) {
    return event.venueName.isNotEmpty
        ? '${event.venueName}, ${event.location}'
        : event.location;
  }
  if (event.venueName.isNotEmpty) return event.venueName;
  return null;
}
