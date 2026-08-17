#!/usr/bin/env python3
"""REBOOT V3 Content Generator.

Generates the complete 90-Day Attention Operating System content libraries:
- 90 Daily Protocol days with distinct identities and 6 arcs
- 90 Unique Micro Insights
- 125 Micro Lessons (180-400w)
- 32 Flow Lessons (400-900w across 6 modules)
- 26 Fuel Lessons (300-700w across 9 domains)
- 105 Environment Interventions organized in ladders
- 65 Behavior Experiment templates across 15 categories
- 125 Observe Missions (Level 1 to 5)
- 80 Nothing Exercises (Level 1 to 8)
- 125 Original Readings (36 Short, 52 Medium, 37 Deep)
- 85 Learning Modules (800-1800w with teach-back prompts)
- 13 Weekly Checkpoint reviews
- 210 Coaching Messages across 12 categories
- 160 Content Evidence records
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "Reboot", "Content")
os.makedirs(CONTENT, exist_ok=True)


def save(filename: str, data):
    path = os.path.join(CONTENT, f"{filename}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Saved {filename}.json ({len(data)} items)")


print("Generating REBOOT V3 Content Intelligence Suite...")
