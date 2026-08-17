#!/usr/bin/env python3
"""V3 content build: schema fields for readings, removal of truncated stubs,
protocol contentID remap and intention rewording."""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONTENT = os.path.join(ROOT, "Reboot", "Content")

TRANSFER = {
1: "Repère trois transactions d'attention refusées demain.",
2: "Note le délai de retour après chaque changement aujourd'hui.",
3: "Note ce que chaque distraction t'apprenait sur la tâche.",
4: "Mesure ton délai de retour sur trois sorties.",
5: "Retire un objet de tentation de ta table avant de commencer.",
6: "Lis un paragraphe deux fois et reformule-le.",
7: "Traverse une minute d'ennui sans la remplir.",
8: "Observe un objet ordinaire pendant trois minutes.",
9: "Attache une session à un rendez-vous fixe de ta journée.",
10: "Remplace une promesse magique par une pratique mesurable.",
11: "Ferme tous les onglets sauf un avant la prochaine tâche.",
12: "Reste dix minutes de plus sur une chose aujourd'hui.",
13: "Identifie un bruit déguisé en signal aujourd'hui.",
14: "Enseigne une notion en trois phrases à quelqu'un.",
15: "Note ce qui occupait ton esprit après cinq minutes de vide.",
16: "Reformule une idée sans aucun mot de la source.",
17: "Retarde une vérification de dix minutes.",
18: "Choisis une direction d'attention pour l'heure qui vient.",
19: "Évalue ce que chaque application te coûte en attention.",
20: "Questionne un outil que tu utilises sans y penser.",
21: "Libère ta scène mentale avant une tâche complexe.",
22: "Choisis une limite et tiens-la aujourd'hui.",
23: "Ralentis une action volontairement aujourd'hui.",
24: "Repère un déclencheur avant de céder.",
25: "Choisis un projet qui demande de rester.",
26: "Sois entièrement présent à une conversation.",
27: "Pose ton téléphone pendant tout un repas.",
28: "Ferme un texte et reconstruis son idée centrale.",
29: "Protège une fenêtre de travail des interruptions.",
30: "Regarde un lieu familier pendant dix minutes.",
31: "Décris ta session en données, pas en jugement.",
32: "Fais une session complète plutôt que deux survolées.",
33: "Corrige ta posture avant ta prochaine session.",
34: "Attends une heure avant de répondre à un message.",
35: "Reste avec une chose même quand elle devient inconfortable.",
36: "Modifie un réglage de ton environnement numérique.",
37: "Identifie quelle conception de l'attention guide tes choix.",
38: "Note une donnée de session sans la juger.",
39: "Choisis une chose qui mérite la profondeur aujourd'hui.",
40: "Reconstruis un contenu d'hier sans le relire.",
41: "Change un contexte pour changer un réflexe.",
42: "Défends une heure de profondeur dans ta journée.",
43: "Utilise un outil contre son réglage par défaut.",
44: "Compte tes dépenses d'attention de la matinée.",
45: "Groupe deux activités en une seule fenêtre.",
46: "Traverse un moment d'impatience sans agir.",
47: "Reviens sur une chose que tu as déjà vue.",
48: "Protège ta nuit comme tu protèges tes sessions.",
49: "Reconstruis ta journée en trois scènes.",
50: "Définis ta cadence d'entretien pour la semaine.",
}


def save(name, data):
    with open(os.path.join(CONTENT, f"{name}.json"), "w") as f:
        f.write("[\n")
        f.write(",\n".join(json.dumps(e, ensure_ascii=False) for e in data))
        f.write("\n]\n")


def main():
    # Readings: drop truncated stubs, add V3 schema fields.
    readings = json.load(open(os.path.join(CONTENT, "readings.json")))
    readings = [r for r in readings if r["id"] <= 50]
    tier_difficulty = {"short": 1, "medium": 2, "deep": 3}
    for r in readings:
        r["difficulty"] = tier_difficulty.get(r.get("length"), 2)
        r["reconstructionPrompt"] = r.get("question", "Qu'est-ce qui est réellement resté ?")
        r["transferPrompt"] = TRANSFER.get(r["id"], "Applique l'idée à ta prochaine session.")
        r.pop("question", None)
    save("readings", readings)

    # Lessons: drop truncated stubs.
    lessons = json.load(open(os.path.join(CONTENT, "learnings.json")))
    lessons = [l for l in lessons if l["id"] <= 35]
    save("learnings", lessons)

    # Protocol: remap reading contentIDs into the 50-reading library and
    # reword the three near-duplicate intentions.
    days = json.load(open(os.path.join(CONTENT, "daily_protocol.json")))
    reword = {
        50: "Trente minutes d'une seule tâche, sans sortie, pour franchir le palier de la demi-heure.",
        66: "Trois quarts d'heure d'une seule tâche, sans sortie, pour installer le format du travail réel.",
        75: "Une heure d'une seule tâche, sans sortie, pour la première fois.",
    }
    for d in days:
        if d.get("contentType") == "reading" and d.get("contentID"):
            d["contentID"] = ((d["day"] * 7) % 50) + 1
        if d["day"] in reword:
            d["intention"] = reword[d["day"]]
    save("daily_protocol", days)

    print("readings:", len(readings), "lessons:", len(lessons), "protocol:", len(days))


if __name__ == "__main__":
    main()
