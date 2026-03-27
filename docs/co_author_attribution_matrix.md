# Co-authored-by attribution matrix (LinkStage)

This document supports **honest** multi-author Git metadata: only list co-authors who **meaningfully contributed** to the change ([GitHub multi-author commits](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors)).

## Canonical trailer lines

Use these exact strings in commit message footers (matches [`.mailmap`](../.mailmap) / existing log emails):

```text
Co-authored-by: Shima Serein <s.shima@alustudent.com>
Co-authored-by: Christian <p.uhiriwe@alustudent.com>
Co-authored-by: Alliane Umutoniwase <a.umutoniwa1@alustudent.com>
Co-authored-by: Sheilla Keza Ruvugabigwi <s.ruvugabig@alustudent.com>
Co-authored-by: Batonicarla <c.batoni@alustudent.com>
```

## Historical commits (Option B — optional rewrite)

These SHAs were flagged where **integration work on `main`** touched domains owned by other members (from `git log -- <paths>` and commit subjects). **Confirm with each co-author** before rewriting messages.

| SHA (short) | Primary author (Git) | Suggested co-authors (verify first) | Rationale |
|-------------|----------------------|-------------------------------------|-----------|
| `086dfa8` | Shima Serein | Christian, Batonicarla | Notifications/Firebase, auth repository, planner dashboard, broad tests |
| `c64b089` | Shima Serein | Christian, Sheilla, Batonicarla | Auth, booking datasource/repo, planner/collaboration wiring |
| `a940bd5` | Shima Serein | Christian | Verify-email and onboarding username (auth flows) |
| `06721eb` | Shima Serein | Sheilla, Christian | Cubits for bookings, applicants, collaboration, chat, login, etc. |
| `f60f521` | Shima Serein | Alliane, Sheilla, Batonicarla | Planner/creative profiles, dashboard, events UI |

### If the team applies Option B

1. Agree a **push freeze**; everyone stops pushing to `main`.
2. `git fetch origin && git checkout main && git pull`
3. `git rebase -i <commit-before-first-rewrite>` → mark commits above as `reword`, append the agreed `Co-authored-by:` lines to each message.
4. `git push --force-with-lease origin main`
5. Teammates: `git fetch origin && git reset --hard origin/main` (or rebase open branches).

**Risk:** All SHAs after the earliest rewritten commit change; regenerate contribution stats and update the report on the **same date** as the export.

## Decision log (choose-rewrite)

| Decision | Choice |
|----------|--------|
| **Pushed `main` history** | **Option A (forward-only)** in this session: no force-push; historical SHAs unchanged. Option B remains available using the table above when the whole team agrees. |
| **New local work** | Landed as **multiple commits** with `Co-authored-by:` trailers keyed to domain owners (see recent `git log` after the attribution commits). |

## Contribution report alignment

After any merge or rewrite, refresh numbers for the report from the **same** source on the **same** date:

```bash
git shortlog -sn --all
# or GitHub: Insights → Contributors
```

A dated snapshot for this repo is kept in [git_contribution_snapshot.md](git_contribution_snapshot.md) (regenerated when attribution work lands).
