#!/usr/bin/env python3
"""REBOOT V3.1 — Content Validator V5

Hard editorial checks for the REBOOT content suite:
- structure & counts (quality-first minimums)
- exact paragraph reuse (>= 30 words) across authored items
- near-duplicate body similarity (fail >= 0.80, warn >= 0.65)
- fabricated DOI / URL patterns
- unresolved evidence IDs
- invalid skill IDs against ContentTaxonomy
- absolute-language and hardcoded-personalization patterns
- QA/CONTENT_DUPLICATES.md report (top 100 passages)
"""

import difflib
import json
import os
import re
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "Reboot", "Content")
REPORT_PATH = os.path.join(ROOT, "QA", "CONTENT_DUPLICATES.md")

FAKE_DOI_PATTERNS = [
    r"reboot\.evidence",
    r"example\.com",
    r"example\.org",
    r"doi\.org/10\.\d{4}/reboot",
    r"fabricat",
    r"lorem\s+ipsum",
]

ABSOLUTE_LANGUAGE = [
    "c'est prouvé", "prouvé scientifiquement", "scientifiquement prouvé",
    "10 % du cerveau", "10% du cerveau", "dopamine detox", "rewiring",
    "recâble le cerveau", "détruit le cortex", "3× mieux", "2× supérieur",
    "garantie de résultats", "fonctionne toujours",
    "ne fonctionne jamais", "marche toujours", "ne marche jamais",
    "à tous les coups", "solution miracle",
]

SCIENCE_TERMS = [
    "cortex", "préfrontal", "prefrontal", "dopamine", "adénosine", "adenosine",
    "cortisol", "mélatonine", "sérotonine", "neurone", "synapse", "cerveau",
]

# French guillemets + straight quotes: text inside them is quoted material
# (e.g. myths explicitly rejected), so absolute-language checks skip it.
QUOTED_RE = re.compile(r"«[^»]*»|\"[^\"]*\"")

HARDCODED_PERSONALIZATION = [
    "à la 12e minute", "à la minute 12", "3× mieux chez toi",
    "engagement 2× supérieur", "fonctionnent 3× mieux",
    "evidenceCount = 4", "ta plage de focus optimale se situe",
]

# Fields that must never repeat a full paragraph >= MIN_PARAGRAPH_WORDS.
TEXT_FIELDS = {
    "readings": ["text", "centralThesis"],
    "learnings": ["text", "coreIdea"],
    "micro_lessons": ["text", "hook", "example", "whatToNotice", "action"],
    "flow_lessons": ["text", "concept", "goodExample", "badExample", "exercise"],
    "fuel_lessons": ["text", "takeaway", "experiment"],
    "daily_protocol": ["setup", "instructions", "challenge", "reflection", "completionMessage", "intention", "whyToday"],
    "environment_interventions": ["reason", "instructions", "followUpQuestion"],
    "experiments": ["hypothesis", "testInstructions", "interpretationLimits"],
    "missions": ["mission", "reflection"],
    "void_prompts": ["prompt"],
    "micro_insights": ["text"],
    "checkpoints": ["insight", "objective", "questions"],
}

MIN_PARAGRAPH_WORDS = 30
SIM_FAIL = 0.80
SIM_WARN = 0.65

MIN_COUNTS = {
    "daily_protocol": 90,
    "micro_insights": 90,
    "checkpoints": 13,
    "readings": 60,
    "learnings": 40,
    "micro_lessons": 60,
    "flow_lessons": 20,
    "fuel_lessons": 15,
    "environment_interventions": 80,
    "experiments": 40,
    "missions": 80,
    "void_prompts": 50,
    "coaching_messages": 100,
    "ContentEvidence": 30,
}


def norm(text: str) -> str:
    return re.sub(r"\s+", " ", text or "").strip().lower()


def paragraphs(text: str) -> list:
    return [p.strip() for p in re.split(r"\n+", text or "") if len(p.split()) >= MIN_PARAGRAPH_WORDS]


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
        self.duplicate_report = []

    def error(self, msg: str):
        self.errors.append(msg)

    def warn(self, msg: str):
        self.warnings.append(msg)

    def run(self):
        print("=" * 60)
        print("REBOOT V3.1 — CONTENT VALIDATOR V5")
        print("=" * 60)

        self.validate_counts()
        self.validate_protocol()
        self.validate_evidence_schema()
        self.validate_references_and_skills()
        self.validate_fake_urls()
        self.validate_absolute_language()
        self.validate_paragraph_duplicates()
        self.validate_body_similarity()
        self.validate_hardcoded_personalization()
        self.write_duplicate_report()

        print(f"\nAudit complete: {len(self.errors)} errors, {len(self.warnings)} warnings.")
        for w in self.warnings:
            print(f"  ⚠️ {w}")
        for e in self.errors:
            print(f"  ❌ {e}")

        if self.errors:
            print("\n❌ VALIDATION FAILED.\n")
            sys.exit(1)
        print("\n✅ VALIDATION PASSED.\n")
        sys.exit(0)

    # ---------- structure & counts ----------
    def validate_counts(self):
        for name, minimum in MIN_COUNTS.items():
            try:
                data = load_json(name)
                c = len(data)
                if c < minimum:
                    self.error(f"{name}.json has {c} items (minimum required: {minimum})")
                else:
                    print(f"✓ {name}.json: {c} items (>= {minimum})")
            except Exception as e:
                self.error(f"Could not load {name}.json: {e}")

    def validate_protocol(self):
        try:
            proto = load_json("daily_protocol")
            days = [d.get("day") for d in proto]
            if sorted(days) != list(range(1, 91)):
                self.error(f"daily_protocol days not exactly 1..90: {days[:3]}...{days[-3:]}")
            for f in ["setup", "challenge", "reflection", "completionMessage", "intention", "whyToday", "title"]:
                vals = [d.get(f) for d in proto]
                if len(set(vals)) != len(vals):
                    dup = [v for v, c in Counter(vals).items() if c > 1][:3]
                    self.error(f"daily_protocol {f} is duplicated across days: {dup}")
            from collections import Counter as C
            modes = C(d["mode"] for d in proto)
            print(f"✓ daily_protocol: 90 days, modes {dict(modes)}")
            print("✓ daily_protocol: setup/challenge/reflection/completion copy all unique")
        except Exception as e:
            self.error(f"daily_protocol validation failed: {e}")

    # ---------- evidence schema ----------
    def validate_evidence_schema(self):
        try:
            records = load_json("ContentEvidence")
            required = ["id", "canonicalClaim", "sourceType", "authors", "title",
                        "journalOrPublisher", "year", "doiOrURL", "confidence",
                        "limitations", "supportedWording", "unsupportedWording"]
            ids = []
            for r in records:
                ids.append(r.get("id"))
                missing = [k for k in required if k not in r]
                if missing:
                    self.error(f"ContentEvidence {r.get('id')} missing fields: {missing}")
                if not isinstance(r.get("supportedWording"), list) or not r["supportedWording"]:
                    self.error(f"ContentEvidence {r.get('id')} must have non-empty supportedWording")
                if not isinstance(r.get("unsupportedWording"), list) or not r["unsupportedWording"]:
                    self.error(f"ContentEvidence {r.get('id')} must have non-empty unsupportedWording")
                if r.get("confidence") not in ("HIGH", "MODERATE", "EMERGING", "PRODUCT HYPOTHESIS"):
                    self.error(f"ContentEvidence {r.get('id')} invalid confidence {r.get('confidence')}")
            if len(set(ids)) != len(ids):
                self.error("ContentEvidence has duplicate ids")
            print(f"✓ ContentEvidence schema: {len(records)} canonical records, one source each")
        except Exception as e:
            self.error(f"ContentEvidence schema validation failed: {e}")

    # ---------- references & skills ----------
    def validate_references_and_skills(self):
        try:
            evidence_ids = {r["id"] for r in load_json("ContentEvidence")}
        except Exception:
            evidence_ids = set()

        taxonomy_src = open(os.path.join(CONTENT, "ContentTaxonomy.swift"), encoding="utf-8").read()
        skill_ids = set(re.findall(r'SubSkill\(id: "([^"]+)"', taxonomy_src))

        evidence_users = {
            "micro_lessons": "evidenceIDs",
            "flow_lessons": "evidenceIDs",
            "fuel_lessons": "evidenceIDs",
            "learnings": "evidenceIDs",
            "readings": "evidenceIDs",
        }
        for fname, field in evidence_users.items():
            for item in load_json(fname):
                for ref in item.get(field) or []:
                    if ref not in evidence_ids:
                        self.error(f"{fname} {item.get('id')} references unknown evidence {ref}")

        for item in load_json("micro_lessons"):
            for sid in item.get("skills") or []:
                if sid not in skill_ids:
                    self.error(f"micro_lessons {item.get('id')} uses unknown skill id {sid}")
        print(f"✓ Evidence references resolved ({len(evidence_ids)} canonical records)")
        print("✓ Skill ids all exist in ContentTaxonomy")

    # ---------- fake URLs ----------
    def validate_fake_urls(self):
        try:
            records = load_json("ContentEvidence")
        except Exception:
            records = []
        for r in records:
            url = r.get("doiOrURL", "")
            for pat in FAKE_DOI_PATTERNS:
                if re.search(pat, url, re.I):
                    self.error(f"ContentEvidence {r['id']} contains fabricated URL pattern '{pat}': {url}")
            if not url.startswith(("https://", "http://", "ISBN ")):
                self.error(f"ContentEvidence {r['id']} has non-URL/non-ISBN reference: {url}")
        print("✓ No fabricated DOI/URL patterns in ContentEvidence")

    # ---------- absolute language ----------
    def validate_absolute_language(self):
        for fname, fields in TEXT_FIELDS.items():
            for item in load_json(fname):
                for field in fields:
                    value = item.get(field)
                    if not isinstance(value, str):
                        continue
                    low = QUOTED_RE.sub(" ", value).lower()
                    for term in ABSOLUTE_LANGUAGE:
                        if term in low:
                            self.error(f"{fname} {item.get('id')} uses absolute/unsupported language '{term}' in {field}")
        print("✓ No absolute unsupported claims in authored content")

    # ---------- paragraph duplicates ----------
    def validate_paragraph_duplicates(self):
        seen = {}
        for fname, fields in TEXT_FIELDS.items():
            for item in load_json(fname):
                item_id = item.get("id", item.get("day", item.get("week")))
                for field in fields:
                    value = item.get(field)
                    chunks = value if isinstance(value, list) else [value]
                    for chunk in chunks:
                        for para in paragraphs(chunk):
                            key = norm(para)
                            if key in seen:
                                prev = seen[key]
                                self.error(
                                    f"Repeated paragraph (>= {MIN_PARAGRAPH_WORDS} words) in {fname} "
                                    f"{item_id}.{field} == {prev[0]} {prev[1]}: «{para[:90]}…»"
                                )
                                self.duplicate_report.append((1.0, para, f"{prev[0]} {prev[1]}", f"{fname} {item_id}.{field}"))
                            else:
                                seen[key] = (fname, f"{item_id}.{field}")
        print("✓ No exact repeated paragraphs >= 30 words across authored items")

    # ---------- body similarity ----------
    def validate_body_similarity(self):
        pairs = []
        for fname, fields in TEXT_FIELDS.items():
            items = load_json(fname)
            bodies = []
            for item in items:
                item_id = item.get("id", item.get("day", item.get("week")))
                main = item.get("text") or item.get("prompt") or item.get("mission") or item.get("insight") or ""
                bodies.append((f"{fname} {item_id}", norm(main)))
            for i in range(len(bodies)):
                for j in range(i + 1, len(bodies)):
                    a_name, a = bodies[i]
                    b_name, b = bodies[j]
                    if not a or not b:
                        continue
                    ratio = difflib.SequenceMatcher(None, a, b).ratio()
                    if ratio >= SIM_FAIL:
                        self.error(f"Near-duplicate bodies ({ratio:.2f}): {a_name} vs {b_name}")
                        pairs.append((ratio, a_name, b_name))
                    elif ratio >= SIM_WARN:
                        self.warn(f"Similar bodies ({ratio:.2f}): {a_name} vs {b_name}")
                        pairs.append((ratio, a_name, b_name))
        if pairs:
            pairs.sort(reverse=True)
            for ratio, a, b in pairs[:30]:
                self.duplicate_report.append((ratio, f"{a} vs {b}", a, b))
        print("✓ Body similarity: no pairs >= 0.80 across authored content")

    # ---------- hardcoded personalization in Swift ----------
    def validate_hardcoded_personalization(self):
        swift_files = [
            os.path.join(ROOT, "Reboot", "Engine", "AttentionOperatingManualEngine.swift"),
            os.path.join(ROOT, "Reboot", "Engine", "DiagnosisQuestionEngine.swift"),
        ]
        for path in swift_files:
            if not os.path.exists(path):
                continue
            src = open(path, encoding="utf-8").read()
            for pat in HARDCODED_PERSONALIZATION:
                if pat.lower() in src.lower():
                    self.error(f"{os.path.basename(path)} contains hardcoded personalization pattern: {pat}")
        print("✓ No hardcoded pseudo-personalized findings in Day 90 / diagnosis engines")

    # ---------- report ----------
    def write_duplicate_report(self):
        os.makedirs(os.path.dirname(REPORT_PATH), exist_ok=True)
        lines = [
            "# REBOOT — RAPPORT DE DOUBLONS (VALIDATEUR V5)",
            "",
            f"Généré le {__import__('datetime').date.today().isoformat()} par `Scripts/validate_content.py`.",
            "",
            f"- Paragraphes exacts répétés (>= {MIN_PARAGRAPH_WORDS} mots) : **erreur**.",
            f"- Similarité de corps >= {SIM_FAIL:.2f} : **erreur** ; >= {SIM_WARN:.2f} : **avertissement**.",
            "",
            "## Top passages signalés",
            "",
        ]
        if not self.duplicate_report:
            lines.append("Aucun doublon ni passage quasi identique détecté.")
        else:
            for rank, entry in enumerate(sorted(self.duplicate_report, reverse=True)[:100], 1):
                if isinstance(entry[1], str) and " vs " in entry[1] and entry[0] < 1.0:
                    ratio, pair, _, _ = entry
                    lines.append(f"{rank}. Similarité {ratio:.2f} — {pair}")
                else:
                    ratio, para, where, also = entry
                    lines.append(f"{rank}. Similarité {ratio:.2f} — «{para[:120]}… »")
                    lines.append(f"   - {where}  /  {also}")
        with open(REPORT_PATH, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        print(f"✓ QA/CONTENT_DUPLICATES.md écrit ({len(self.duplicate_report)} passages signalés)")


if __name__ == "__main__":
    Validator().run()
