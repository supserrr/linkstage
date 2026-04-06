# Create Event / Gig Flow

## Overview

Event planners can create events (gigs) through the create event form. Events are stored in Firestore and can be saved as drafts or published as open for creatives to find and apply.

## Backend

### Data Layer

- **EventRemoteDataSource.createEvent()** – Writes a new document to the `events` collection via Firestore `add()`, returns the created `EventEntity` with the generated document ID.
- **EventRepository.createEvent()** – Domain contract and implementation delegating to the datasource.

### Firestore

- **Collection:** `events`
- **Fields:** plannerId, title, date, location, description, status, imageUrls, locationVisibility (`public` \| `private` \| `acceptedCreatives`; default `public` when omitted)
- **Rules:** Create allowed when `request.resource.data.plannerId == request.auth.uid`
- **Indexes:** plannerId + date (existing) – no new indexes required for create

## Frontend

### Entry Points

1. **Planner Dashboard** – "Post a Gig" card navigates to create event.
2. **My Events (empty)** – "Create event" button in empty state.
3. **My Events (with events)** – "+" icon in app bar.

### Route

- **Path:** `/bookings/create-event`
- **Name:** `createEvent`
- **Parent:** `/bookings` (Events/Gigs tab)

### Form Fields

| Field       | Required | Notes                                                |
| ----------- | -------- | ---------------------------------------------------- |
| Title       | Yes      | e.g. Wedding Reception, Corporate Gala               |
| Date        | No       | Date picker; events without date are valid (drafts)  |
| Location    | No       | Picked from Google Maps; "Browse in Google Maps" opens the location in the Maps app |
| Description | No       | Multi-line; details for creatives                    |
| Pictures    | No       | Multiple images; uploaded to Supabase Storage        |
| Status      | Yes      | Draft (save for later) or Open (visible to creatives)|
| Location visibility | Yes (default Public) | **Public** – address on cards/detail for everyone. **Private** – hidden from others; planner always sees full location. **Accepted** – others see a placeholder until the planner accepts a creative for the event; accepted creatives and the planner see the real address. |

### Location (free, no API key)

- **Text field**: Manual address or venue name.
- **Use current location**: Gets GPS position and reverse-geocodes to address (device native, free).
- **Pick on map**: Opens an OpenStreetMap picker; tap to select, uses device geocoding for address.
- **Browse in maps**: Opens the location in OpenStreetMap in the browser.

### Post-Save

On successful save, the user is navigated to the Events tab (`/bookings`). The events list reloads and shows the new event.
