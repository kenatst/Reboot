#!/usr/bin/env python3
"""REBOOT V3 content validator.

Checks structure, uniqueness, references and word-count tiers across the
bundled content libraries. Exit code 0 = no failures (warnings allowed).
"""

from __future__ import annotations

import difflib
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "Reboot", "Content")

MODES = {"stay", "recall", "explain", "nothing", "observe"}
READING_TIERS = {"short": (450, 650), "medium": (750, 1100), "deep": (1300, 1800)}
LESSON_TIER = (700, 1500)

failures: list[str] = []
warnings: list[str] = []


def load(name: str):
    path = os.path.join(CONTENT, f"{name}.json")
    try:
        with open(path) as f:
            return json.load(f)
    except Exception as exc:  # noqa: BLE001
        failures.append(f"{name}.json: invalid JSON ({exc})")
        return []


def norm(text: str) -> str:
    return re.sub(r"\s+", " ", text or "").strip().lower()


def similarity(a: str, b: str) -> float:
    return difflib.SequenceMatcher(None, norm(a), norm(b)).ratio()


def check_empty(obj, name: str, fields):
    for field in fields:
        value = obj.get(field)
        if value is None or value == "" or value == []:
            failures.append(f"{name}: empty field '{field}'")


def main() -> int:
    # 1. Protocol days
    days = load("daily_protocol")
    if len(days) != 90:
        failures.append(f"daily_protocol: expected 90 days, got {len(days)}")
    else:
        numbers = [d["day"] for d in days]
        if numbers != list(range(1, 91)):
            failures.append("daily_protocol: days must be sequential 1..90")
        ids = [d["day"] for d in days]
        if len(set(ids)) != len(ids):
            failures.append("daily_protocol: duplicate day ids")
        for d in days:
            if d.get("mode") not in MODES:
                failures.append(f"daily_protocol day {d.get('day')}: invalid mode {d.get('mode')}")
            check_empty(d, f"daily_protocol day {d.get('day')}", [
                "phase", "week", "mode", "skill", "title", "intention", "whyToday",
                "duration", "difficulty", "setup", "instructions", "challenge",
                "reflection", "contentType", "completionMessage"
            ])
            if d.get("contentType") != "stay" and d.get("contentID") is None:
                failures.append(f"daily_protocol day {d.get('day')}: missing contentID for {d.get('contentType')}")

        # Duplicate titles within the same week
        by_week = {}
        for d in days:
            by_week.setdefault(d["week"], []).append(d)
        for week, week_days in by_week.items():
            titles = [norm(d["title"]) for d in week_days]
            if len(set(titles)) != len(titles):
                failures.append(f"daily_protocol: duplicate title within week {week}")
        intentions = [norm(d["intention"]) for d in days]
        if len(set(intentions)) != len(intentions):
            failures.append("daily_protocol: duplicate intentions")
        for i, a in enumerate(intentions):
            for b in intentions[i + 1:]:
                if a and a == b:
                    break

    # 2. Micro insights
    insights = load("micro_insights")
    if len(insights) != 90:
        failures.append(f"micro_insights: expected 90, got {len(insights)}")
    texts = [norm(i.get("text", "")) for i in insights]
    if len(set(texts)) != len(texts):
        failures.append("micro_insights: duplicate texts")

    # 3. Void prompts
    voids = load("void_prompts")
    if len(voids) < 45:
        failures.append(f"void_prompts: expected >= 45, got {len(voids)}")

    # 4. Missions
    missions = load("missions")
    mission_ids = [m["id"] for m in missions]
    if len(set(mission_ids)) != len(mission_ids):
        failures.append("missions: duplicate ids")
    for m in missions:
        if len(m.get("cues", [])) > 3:
            failures.append(f"missions id {m.get('id')}: more than 3 cues")
        check_empty(m, f"missions id {m.get('id')}", ["title", "category", "mission", "cues", "reflection", "difficulty", "recommendedContext"])

    # 5. Checkpoints
    checkpoints = load("checkpoints")
    if len(checkpoints) != 13:
        failures.append(f"checkpoints: expected 13, got {len(checkpoints)}")

    # 6. Readings
    readings = load("readings")
    reading_ids = [r["id"] for r in readings]
    if len(set(reading_ids)) != len(reading_ids):
        failures.append("readings: duplicate ids")
    for r in readings:
        tier = r.get("length")
        words = len(r.get("body", r.get("text", "")).split())
        lo, hi = READING_TIERS.get(tier, (0, 10**9))
        if not (lo <= words <= hi):
            failures.append(f"readings id {r.get('id')}: {words} words outside {tier} tier {lo}-{hi}")
        check_empty(r, f"readings id {r.get('id')}", ["title", "category", "difficulty", "length", "reconstructionPrompt", "transferPrompt"])

    # 7. Lessons
    lessons = load("learnings")
    lesson_ids = [l["id"] for l in lessons]
    if len(set(lesson_ids)) != len(lesson_ids):
        failures.append("learnings: duplicate ids")
    for l in lessons:
        words = len(l.get("text", "").split())
        lo, hi = LESSON_TIER
        if not (lo <= words <= hi):
            failures.append(f"learnings id {l.get('id')}: {words} words outside lesson tier {lo}-{hi}")

    # 8. contentID references
    reading_set = set(reading_ids)
    lesson_set = set(lesson_ids)
    mission_set = set(mission_ids)
    void_set = {v["id"] for v in voids}
    for d in days:
        cid = d.get("contentID")
        if cid is None:
            continue
        pool = {
            "reading": reading_set,
            "lesson": lesson_set,
            "mission": mission_set,
            "void": void_set,
            "stay": set(),
        }.get(d.get("contentType"), set())
        if pool and cid not in pool:
            failures.append(f"daily_protocol day {d.get('day')}: contentID {cid} missing in {d.get('contentType')} library")

    # 9. Near-duplicate similarity across protocol intentions
    seen = []
    for d in days:
        text = norm(d.get("intention", ""))
        for other in seen:
            if text and similarity(text, other) > 0.82:
                warnings.append(f"daily_protocol: near-duplicate intention (>{0.82}) day {d.get('day')}")
                break
        seen.append(text)

    # 10. Protocol instructions repeated across a whole phase
    for phase in range(1, 5):
        phase_days = [d for d in days if d.get("phase") == phase]
        inst = [json.dumps(d.get("instructions"), ensure_ascii=False) for d in phase_days]
        if len(set(inst)) < len(inst):
            warnings.append(f"daily_protocol: repeated instruction arrays in phase {phase}")

    print(f"FAILURES ({len(failures)})")
    for f in failures:
        print("  FAIL:", f)
    print(f"WARNINGS ({len(warnings)})")
    for w in warnings:
        print("  WARN:", w)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
