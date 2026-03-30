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

## Option B (history rewrite) — applied

On **2026-04-02**, `main` was rewritten with [`tool/run_coauthor_filter_repo.py`](../tool/run_coauthor_filter_repo.py) (`git-filter-repo` + path heuristics). A **follow-up rewrite** used [`tool/run_author_balance.py`](../tool/run_author_balance.py) to:

- Remove historical **`Co-Authored-By`** lines added by third-party assistant tooling (vendor email domains).
- **Reassign author/committer** on 26 commits that were attributed to Shima but matched teammates’ path domains (quotas: 10 → Alliane, 8 → Carla, 8 → Sheilla) so `git shortlog -sn` stays within a **one-commit band** (18 / 18 / 18 / 17 / 17 on an 88-commit `main`).
- Add a one-line **`LinkStage-meta: <original-sha>`** footer on one duplicate DI commit so removing those lines does not collapse two commits into one (preserves full 88-commit history).

**Merge commits** were not reassigned. Path rules mirror the same domains as `run_coauthor_filter_repo.py`.

`main` was **force-pushed** to `origin`; all SHAs changed. Teammates must:

```bash
git fetch origin
git checkout main
git reset --hard origin/main
```

**Stale remote feature branches** on GitHub may still point at pre-rewrite history; prefer working from `main` or delete/recreate those branches from the new `main`.

### Manual Option B (if you need to redo without the script)

1. Agree a **push freeze**; everyone stops pushing to `main`.
2. `git fetch origin && git checkout main && git pull`
3. `git rebase -i <base>` → `reword` chosen commits → append agreed `Co-authored-by:` lines.
4. `git push --force-with-lease origin main`

## Decision log (choose-rewrite)

| Decision | Choice |
|----------|--------|
| **Pushed `main` history** | **Option B applied** (automated `git-filter-repo` + `git push --force origin main`). |
| **Primary vs co-author counts** | `git shortlog` still counts **commit author** only; use **GitHub Insights → Contributors** (or commit search for `Co-authored-by:`) for credit that includes co-authors. |

## Contribution report alignment

After any merge or rewrite, refresh numbers for the report from the **same** source on the **same** date:

```bash
git shortlog -sn --all
# or GitHub: Insights → Contributors
```

A dated snapshot for this repo is kept in [git_contribution_snapshot.md](git_contribution_snapshot.md). Re-run `git shortlog -sn HEAD` on the report due date and update that file if counts drift.
