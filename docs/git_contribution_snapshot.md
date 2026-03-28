# Git contribution snapshot (report alignment)

Use this file to keep the **course report contribution table** aligned with repository history. Regenerate or update the **Export date** whenever you refresh numbers.

| Field | Value |
|-------|--------|
| **Export date** | 2026-04-02 |
| **Branch** | `main` (local snapshot; push to `origin/main` to match remote) |
| **Source command** | `git shortlog -sn HEAD` |

## Commit counts by author (`git shortlog -sn HEAD`)

Recorded after attribution commits landed (see `git log` for `Co-authored-by:` footers; GitHub also surfaces co-authors on the web UI).

```
    41	Shima Serein
    24	Christian
    14	Alliane Umutoniwase
    11	Sheilla Keza Ruvugabigwi
     9	Batonicarla
```

*(Re-run `git shortlog -sn HEAD` on the report due date; totals change with every new commit.)*

## GitHub (optional cross-check)

If the marker uses **GitHub Insights → Contributors**, run the export on the **same calendar date** as above and paste totals into the report. Minor differences vs `git shortlog` can occur due to squash settings, bot accounts, or email mapping.

## Recent attribution commits (with co-authors)

| SHA | Summary | Co-authored-by (in message) |
|-----|---------|----------------------------|
| `4c4d337` | Auth routing, login, verify email, role selection | Christian |
| `ba88a39` | Profile, settings, validation, portfolio | Alliane Umutoniwase |
| `8349bcd` | Bookings, collaborations, events, applicants, messaging | Sheilla Keza Ruvugabigwi |
| `736e524` | Push notifications, notifications cubit, Firestore data tests | Batonicarla |
| `9d21ad4` | Explore, home, creative dashboard | Alliane Umutoniwase; Sheilla Keza Ruvugabigwi |

Docs-only, harness, and coverage commits above these have **no** `Co-authored-by` lines (single-maintainer churn).

## Rewrite decision

**Option A (forward-only)** is in effect for already-pushed history: see [co_author_attribution_matrix.md](co_author_attribution_matrix.md) for optional **Option B** steps and the historical SHA table.
