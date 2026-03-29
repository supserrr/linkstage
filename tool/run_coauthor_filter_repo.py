#!/usr/bin/env python3
# Copyright: used only locally for LinkStage history rewrite (Option B).
"""Append Co-authored-by trailers from touched paths using git-filter-repo."""

from __future__ import annotations

import os
import sys

import git_filter_repo as gfr

TRAILERS_ORDER: list[tuple[str, bytes]] = [
    ("christian", b"Co-authored-by: Christian <p.uhiriwe@alustudent.com>"),
    ("alliane", b"Co-authored-by: Alliane Umutoniwase <a.umutoniwa1@alustudent.com>"),
    ("sheilla", b"Co-authored-by: Sheilla Keza Ruvugabigwi <s.ruvugabig@alustudent.com>"),
    ("carla", b"Co-authored-by: Batonicarla <c.batoni@alustudent.com>"),
    ("shima", b"Co-authored-by: Shima Serein <s.shima@alustudent.com>"),
]

# Unique substring per person for duplicate detection (any encoding in message).
MARKER_SUBSTR: dict[str, bytes] = {
    "christian": b"Christian <p.uhiriwe@alustudent.com>",
    "alliane": b"Alliane Umutoniwase <a.umutoniwa1@alustudent.com>",
    "sheilla": b"Sheilla Keza Ruvugabigwi <s.ruvugabig@alustudent.com>",
    "carla": b"Batonicarla <c.batoni@alustudent.com>",
    "shima": b"Shima Serein <s.shima@alustudent.com>",
}

EMAIL_TO_TAG: dict[bytes, str] = {
    b"p.uhiriwe@alustudent.com": "christian",
    b"a.umutoniwa1@alustudent.com": "alliane",
    b"s.ruvugabig@alustudent.com": "sheilla",
    b"c.batoni@alustudent.com": "carla",
    b"s.shima@alustudent.com": "shima",
}


def _norm_email(raw: bytes) -> bytes:
    return raw.lower().strip()


def _iter_paths(commit) -> list[bytes]:
    out: list[bytes] = []
    for ch in commit.file_changes:
        if ch.type == b"DELETEALL":
            continue
        fn = ch.filename
        if isinstance(fn, tuple):
            for part in fn:
                if part:
                    out.append(part.lower())
        elif fn:
            out.append(fn.lower())
    return out


def _collect_tags(paths: list[bytes]) -> set[str]:
    tags: set[str] = set()
    for fn in paths:
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
            tags.add("christian")

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
            tags.add("alliane")

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
            tags.add("sheilla")

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
            tags.add("carla")

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
            tags.add("shima")

    return tags


def commit_callback(commit, _metadata) -> None:
    if len(commit.parents) > 1:
        return

    author_tag = EMAIL_TO_TAG.get(_norm_email(commit.author_email))
    if not author_tag:
        return

    paths = _iter_paths(commit)
    if not paths:
        return

    tags = _collect_tags(paths)
    tags.discard(author_tag)

    msg = commit.message
    to_add: list[bytes] = []
    for key, line in TRAILERS_ORDER:
        if key not in tags:
            continue
        if MARKER_SUBSTR[key] in msg:
            continue
        to_add.append(line)

    if not to_add:
        return

    if not msg.endswith(b"\n"):
        msg += b"\n"
    commit.message = msg + b"\n".join(to_add) + b"\n"


def main() -> None:
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(repo_root)
    args = gfr.FilteringOptions.parse_args(["--force", "--proceed", "--quiet"])
    gfr.RepoFilter(args, commit_callback=commit_callback).run()
    print(
        "History rewrite finished. Restore remote if needed:\n"
        "  git remote add origin https://github.com/supserrr/linkstage.git\n"
        "  git push --force-with-lease origin main\n"
        "Tell teammates: git fetch && git reset --hard origin/main"
    )


if __name__ == "__main__":
    main()
