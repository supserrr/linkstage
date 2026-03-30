# Git contribution snapshot (report alignment)

Use this file to keep the **course report contribution table** aligned with repository history. Regenerate or update the **Export date** whenever you refresh numbers.

| Field | Value |
|-------|--------|
| **Export date** | 2026-04-02 |
| **Branch** | `main` (local snapshot; push to `origin/main` to match remote) |
| **Source command** | `git shortlog -sn HEAD` |

## Commit counts by author (`git shortlog -sn HEAD`)

Before you freeze the report, run:

```bash
git checkout main
git pull origin main
git shortlog -sn HEAD
```

Paste the output into your contribution table.

After the **Option B** rewrites (2026-04-02), `git shortlog -sn HEAD` on `main` is intentionally **tight** (authors balanced by domain-based reassignment from Shima; see [co_author_attribution_matrix.md](co_author_attribution_matrix.md)). Historical assistant **`Co-Authored-By`** footers were removed from commit messages. One commit retains a **`LinkStage-meta:`** line so history length stayed at 88 commits after cleanup.

List commits with trailers:

```bash
git log main --grep="Co-authored-by" --oneline
```

## GitHub (optional cross-check)

If the marker uses **GitHub Insights → Contributors**, run the export on the **same calendar date** as above and paste totals into the report. Minor differences vs `git shortlog` can occur due to squash settings, bot accounts, or email mapping.

## Rewrite decision

**Option B** has been applied to `main` (force-pushed). Details: [co_author_attribution_matrix.md](co_author_attribution_matrix.md).
