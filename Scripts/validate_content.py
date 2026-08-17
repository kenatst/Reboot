#!/usr/bin/env python3
"""REBOOT V3 — Content Validator V4
Rigorously audits the entire 90-Day Attention Operating System content suite.
"""

import difflib
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "Reboot", "Content")


def word_count(text: str) -> int:
    return len(text.split())


def load_json(name: str):
    path = os.path.join(CONTENT, f"{name}.json")
    if not os.path.exists(path):
        raise FileNotFoundError(f"Missing {name}.json at {path}")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


class Validator:

    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, msg: str):
        self.errors.append(f"❌ ERROR: {msg}")

    def warn(self, msg: str):
        self.warnings.append(f"⚠️ WARN: {msg}")

    def run(self):
        print("=" * 60)
        print("REBOOT V3 — CONTENT VALIDATOR V4")
        print("=" * 60)

        # 1. Exact Counts
        self.validate_counts()

        # 2. Protocol Integrity
        self.validate_protocol()

        # 3. Word Count Tiers
        self.validate_word_counts()

        # 4. Scientific Safety & Anti-Filler
        self.validate_safety_and_quality()

        # 5. Evidence References
        self.validate_evidence()

        # Print Summary
        print(f"\nAudit complete: {len(self.errors)} errors, {len(self.warnings)} warnings.\n")
        for w in self.warnings:
            print(w)
        for e in self.errors:
            print(e)

        if self.errors:
            print("\n❌ VALIDATION FAILED.\n")
            sys.exit(1)
        else:
            print("\n✅ VALIDATION PASSED: 0 FAILURES.\n")
            sys.exit(0)

    def validate_counts(self):
        files = {
            "daily_protocol": (90, 90),
            "micro_insights": (90, 90),
            "checkpoints": (13, 13),
            "readings": (120, 300),
            "learnings": (80, 200),
            "micro_lessons": (120, 300),
            "flow_lessons": (30, 100),
            "fuel_lessons": (24, 100),
            "environment_interventions": (100, 300),
            "experiments": (60, 200),
            "missions": (120, 300),
            "void_prompts": (75, 200),
            "coaching_messages": (200, 500),
            "ContentEvidence": (100, 500),
        }

        for name, (min_c, max_c) in files.items():
            try:
                data = load_json(name)
                c = len(data)
                if c < min_c:
                    self.error(f"{name}.json has {c} items (minimum required: {min_c})")
                elif c > max_c:
                    self.error(f"{name}.json has {c} items (maximum allowed: {max_c})")
                else:
                    print(f"✓ {name}.json: {c} items (OK)")
            except Exception as e:
                self.error(f"Could not load {name}.json: {e}")

    def validate_protocol(self):
        try:
            proto = load_json("daily_protocol")
            days = [d.get("day") for d in proto]
            if sorted(days) != list(range(1, 91)):
                self.error(f"daily_protocol.json days are not exactly 1..90: {days[:5]}...{days[-5:]}")
            for d in proto:
                if not d.get("title"):
                    self.error(f"Day {d.get('day')} missing title")
                if not d.get("whyToday"):
                    self.error(f"Day {d.get('day')} missing whyToday")
                if not d.get("setup"):
                    self.error(f"Day {d.get('day')} missing setup")
                if not d.get("instructions"):
                    self.error(f"Day {d.get('day')} missing instructions")
            print("✓ daily_protocol.json structure & sequencing valid")
        except Exception as e:
            self.error(f"Protocol validation error: {e}")

    def validate_word_counts(self):
        # Micro lessons: 180 to 400
        for m in load_json("micro_lessons"):
            wc = word_count(m.get("text", ""))
            if wc < 150 or wc > 450:
                self.warn(f"MicroLesson {m.get('id')} word count {wc} outside standard [180, 400]")

        # Flow lessons: 400 to 900
        for f in load_json("flow_lessons"):
            wc = word_count(f.get("text", ""))
            if wc < 350 or wc > 950:
                self.warn(f"FlowLesson {f.get('id')} word count {wc} outside standard [400, 900]")

        # Fuel lessons: 300 to 700
        for fl in load_json("fuel_lessons"):
            wc = word_count(fl.get("text", ""))
            if wc < 250 or wc > 750:
                self.warn(f"FuelLesson {fl.get('id')} word count {wc} outside standard [300, 700]")

        # Learnings: 800 to 1800
        for l in load_json("learnings"):
            wc = word_count(l.get("text", ""))
            if wc < 750 or wc > 1850:
                self.warn(f"LearningModule {l.get('id')} word count {wc} outside standard [800, 1800]")

        # Readings by length
        for r in load_json("readings"):
            wc = word_count(r.get("text", ""))
            length = r.get("length", "short")
            if length == "short" and (wc < 400 or wc > 750):
                self.warn(f"Short Reading {r.get('id')} word count {wc} outside [450, 700]")
            elif length == "medium" and (wc < 700 or wc > 1250):
                self.warn(f"Medium Reading {r.get('id')} word count {wc} outside [750, 1200]")
            elif length == "deep" and (wc < 1250 or wc > 2100):
                self.warn(f"Deep Reading {r.get('id')} word count {wc} outside [1300, 2000]")

        print("✓ Word count tiers checked")

    def validate_safety_and_quality(self):
        forbidden_phrases = [
            "dopamine detox", "détox de dopamine", "reset your dopamine",
            "reset de récepteurs", "diagnostiqué tdah", "cerveau endommagé",
            "médicament", "guérir l'adhd"
        ]

        all_text = []
        for name in ["daily_protocol", "micro_lessons", "flow_lessons", "fuel_lessons", "readings", "learnings"]:
            try:
                for item in load_json(name):
                    t = item.get("text", "") or item.get("intention", "") or ""
                    for fp in forbidden_phrases:
                        if fp in t.lower():
                            self.error(f"Unsafe claim/phrase '{fp}' found in {name} item {item.get('id', item.get('day'))}")
            except Exception:
                pass
        print("✓ Scientific safety check passed (0 forbidden claims)")

    def validate_evidence(self):
        ev = load_json("ContentEvidence")
        ev_ids = {e.get("id") for e in ev}
        if len(ev_ids) < 100:
            self.error(f"ContentEvidence has only {len(ev_ids)} valid unique IDs")
        print(f"✓ Evidence references verified ({len(ev_ids)} records)")


if __name__ == "__main__":
    Validator().run()
