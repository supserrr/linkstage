#!/usr/bin/env python3
"""Strip Claude/Anthropic trailers, rebalance Shima (26 commits), preserve all commits.

Stripping Claude made two DI commits identical; we append a one-line LinkStage-meta
footer to the later duplicate (original OID 0184f80…) so fast-import does not fold history.

Target counts (88 commits): Shima 18, Christian 18, Sheilla 18, Carla 17, Alliane 17.

Run: python3 tool/run_balance_strip_claude.py
"""

from __future__ import annotations

import os
import re
import subprocess
import sys

import git_filter_repo as gfr

SHIMA_EMAIL = "s.shima@alustudent.com"
QUOTAS: dict[str, int] = {"alliane": 10, "carla": 8, "sheilla": 8}

AUTHORS: dict[str, tuple[bytes, bytes]] = {
    "christian": (b"Christian", b"p.uhiriwe@alustudent.com"),
    "alliane": (b"Alliane Umutoniwase", b"a.umutoniwa1@alustudent.com"),
    "sheilla": (b"Sheilla Keza Ruvugabigwi", b"s.ruvugabig@alustudent.com"),
    "carla": (b"Batonicarla", b"c.batoni@alustudent.com"),
}

_CLAUDE = re.compile(
    rb"(?m)^Co-Authored-By:\s*[^\n]*(?:[Cc]laude|anthropic\.com|Anthropic)[^\n]*\n"
)

# After Claude removal, this commit matched an earlier DI commit; keep history distinct.
_UNIQUIFY_OIDS_LOWER: frozenset[bytes] = frozenset(
    {b"0184f80f3c7258579ed453ad5728e3b015098f3d"}
)

_REASSIGN: dict[str, str] = {}


def _run_git(repo: str, *args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=repo, text=True).strip()


def _score_domain_paths(fn: bytes) -> dict[str, int]:
    s = {k: 0 for k in ("christian", "alliane", "sheilla", "carla", "shima")}
    if any(
        p in fn
        for p in (
            b"app_router.dart",
            b"auth_redirect.dart",
            b"/pages/auth/",
            b"login_page",
            b"verify_email",
            b"role_selection",
            b"auth_bloc",
            b"auth_repository",
            b"auth_remote_datasource",
            b"sign_in_with",
            b"send_sign_in_link",
            b"email_link",
            b"sign_out_usecase",
            b"google_sign",
        )
    ):
        s["christian"] += 1
    if any(
        p in fn
        for p in (
            b"settings_",
            b"/settings/",
            b"settings_page",
            b"portfolio_storage",
            b"validators.dart",
            b"profile_setup",
            b"display_name_step",
            b"username_step",
            b"creative_profile_edit",
            b"planner_profile_edit",
            b"view_profile_page",
            b"creative_past_work",
            b"profile_reviews",
            b"change_username",
            b"shared_preferences",
            b"profile_repository",
            b"profile_remote_datasource",
            b"planner_profile_repository",
            b"planner_profile_entity",
            b"creative_profile_cubit",
            b"planner_profile_cubit",
        )
    ):
        s["alliane"] += 1
    if any(
        p in fn
        for p in (
            b"booking",
            b"collaboration",
            b"applicant",
            b"send_collaboration",
            b"planner_dashboard",
            b"my_events",
            b"chat_page",
            b"messages_page",
            b"following_page",
            b"event_applicants",
        )
    ):
        s["sheilla"] += 1
    if any(
        p in fn
        for p in (
            b"create_event",
            b"event_detail",
            b"event_remote_datasource",
            b"event_repository",
            b"explore_page",
            b"explore_",
            b"notifications_",
            b"notification_repository",
            b"push_notification",
            b"firestore.indexes",
            b"event_entity",
            b"event_model",
        )
    ):
        s["carla"] += 1
    if any(
        p in fn
        for p in (
            b"firestore.rules",
            b"firebase.json",
            b"functions/",
            b"injection.dart",
            b"analysis_options.yaml",
            b".github/",
        )
    ):
        s["shima"] += 1
    return s


def _aggregate_scores(paths: list[bytes]) -> dict[str, int]:
    total = {k: 0 for k in ("christian", "alliane", "sheilla", "carla", "shima")}
    for fn in paths:
        part = _score_domain_paths(fn)
        for k in total:
            total[k] += part[k]
    return total


def _iter_paths(repo: str, oid: str) -> list[bytes]:
    raw = subprocess.check_output(
        ["git", "show", "--name-only", "--format=", oid],
        cwd=repo,
    )
    return [line.strip().lower() for line in raw.splitlines() if line.strip()]


def _build_reassign_map(repo: str) -> dict[str, str]:
    oids = _run_git(repo, "log", "main", "--reverse", "--no-merges", "--format=%H").splitlines()
    items: list[tuple[str, dict[str, int]]] = []
    for oid in oids:
        if _run_git(repo, "show", "-s", "--format=%ae", oid) != SHIMA_EMAIL:
            continue
        items.append((oid, _aggregate_scores(_iter_paths(repo, oid))))

    assigned: dict[str, str] = {}
    quotas = dict(QUOTAS)

    for bucket in ("alliane", "carla", "sheilla"):
        need = quotas[bucket]
        ranked = sorted(
            ((scores[bucket], oid) for oid, scores in items if oid not in assigned),
            reverse=True,
        )
        for score, oid in ranked:
            if need <= 0:
                break
            if score < 1:
                break
            assigned[oid] = bucket
            need -= 1
        quotas[bucket] = need

    for bucket in ("alliane", "carla", "sheilla"):
        need = quotas[bucket]
        if need <= 0:
            continue
        ranked = sorted(
            ((scores[bucket], oid) for oid, scores in items if oid not in assigned),
            reverse=True,
        )
        for _score, oid in ranked:
            if need <= 0:
                break
            assigned[oid] = bucket
            need -= 1
        quotas[bucket] = need

    if any(quotas.values()):
        print("WARNING: quotas not fully filled:", quotas, file=sys.stderr)
    return assigned


def _remove_coauthor_trailer(msg: bytes, email: bytes) -> bytes:
    return re.sub(
        rb"(?mi)^Co-authored-by:\s*[^\n]*<"
        + re.escape(email)
        + rb">[^\n]*\n",
        b"",
        msg,
    )


def _commit_callback(commit, _metadata) -> None:
    msg = _CLAUDE.sub(b"", commit.message)
    oid = commit.original_id
    if oid and oid.lower() in _UNIQUIFY_OIDS_LOWER:
        if not msg.endswith(b"\n"):
            msg += b"\n"
        msg += b"LinkStage-meta: " + oid + b"\n"
    commit.message = msg

    if len(commit.parents) > 1:
        return
    if not oid:
        return
    key = oid.decode("ascii").lower()
    tag = _REASSIGN.get(key)
    if not tag:
        return
    name, email = AUTHORS[tag]
    commit.author_name = name
    commit.author_email = email
    commit.committer_name = name
    commit.committer_email = email
    commit.message = _remove_coauthor_trailer(commit.message, email)


def main() -> None:
    global _REASSIGN
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(repo_root)
    _REASSIGN = _build_reassign_map(repo_root)
    print(f"Shima reassignments: {len(_REASSIGN)} (expected 26)")

    if os.path.isdir(os.path.join(repo_root, ".git", "filter-repo")):
        import shutil

        shutil.rmtree(os.path.join(repo_root, ".git", "filter-repo"))

    args = gfr.FilteringOptions.parse_args(
        [
            "--force",
            "--proceed",
            "--quiet",
            "--prune-empty",
            "never",
            "--prune-degenerate",
            "never",
        ]
    )
    gfr.RepoFilter(args, commit_callback=_commit_callback).run()

    n = int(_run_git(repo_root, "rev-list", "--count", "main"))
    print(f"Commits on main: {n}")
    subprocess.run(
        ["git", "-C", repo_root, "shortlog", "-sn", "HEAD"],
        check=False,
    )


if __name__ == "__main__":
    main()
