#!/usr/bin/env python3
"""V3 mission library build: adds schema fields to the existing 60 missions
and appends 30 newly authored missions (total 90)."""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATH = os.path.join(ROOT, "Reboot", "Content", "missions.json")

CONTEXT = {
    "PEOPLE": "Un lieu passant",
    "MOVEMENT": "Un trottoir ou une gare",
    "SPACE": "Un espace public conçu",
    "NATURE": "Un parc ou une fenêtre",
    "SOUND": "Un lieu sonore",
    "DESIGN": "Une vitrine ou une interface réelle",
    "SYSTEMS": "Un carrefour ou un marché",
    "PATTERNS": "Un lieu à répétition",
    "BEHAVIOR": "Un espace social",
    "DETAILS": "Un objet ordinaire",
}

NEW = [
    {"id": 61, "title": "Les distances choisies", "category": "PEOPLE", "mission": "Observe les distances que les gens maintiennent entre eux et ce qui les fait varier.", "cues": ["Les distances entre inconnus", "Les distances entre proches", "Ce qui rapproche ou éloigne"], "reflection": "Quelle distance choisis-tu dans un espace rempli ?", "difficulty": 3, "recommendedContext": "Une place ou un hall"},
    {"id": 62, "title": "Les accélérations", "category": "MOVEMENT", "mission": "Repère ce qui fait accélérer les gens dans un espace public.", "cues": ["L'approche d'une porte", "Une horloge visible", "Le téléphone qui sonne"], "reflection": "Qu'est-ce qui t'a fait accélérer aujourd'hui ?", "difficulty": 3, "recommendedContext": "Une rue commerçante"},
    {"id": 63, "title": "Les seuils invisibles", "category": "SPACE", "mission": "Observe les frontières invisibles qu'un espace public dessine sans les annoncer.", "cues": ["Le changement de revêtement", "La fin d'un éclairage", "Le rétrécissement du passage"], "reflection": "Quelle frontière invisible as-tu franchie sans la voir ?", "difficulty": 4, "recommendedContext": "Une place aux usages mélangés"},
    {"id": 64, "title": "Les signes de saison", "category": "NATURE", "mission": "Observe trois signes de la saison actuelle dans un même lieu.", "cues": ["Les couleurs dominantes", "Les comportements animaux", "La lumière et son angle"], "reflection": "Qu'est-ce que la saison change dans le lieu ?", "difficulty": 2, "recommendedContext": "Un parc"},
    {"id": 65, "title": "Le paysage sonore", "category": "SOUND", "mission": "Ferme les yeux deux minutes et dessine le paysage sonore du lieu.", "cues": ["Les sons proches et lointains", "Les sons réguliers et irréguliers", "Le silence entre les sons"], "reflection": "Quel son dominait, et lequel manquait ?", "difficulty": 3, "recommendedContext": "Un lieu ordinaire"},
    {"id": 66, "title": "La hiérarchie d'une affiche", "category": "DESIGN", "mission": "Démonte la hiérarchie visuelle d'une affiche : ce qui est lu en premier, en second, en dernier.", "cues": ["La taille et le contraste", "La direction du regard", "Ce qui est caché en bas"], "reflection": "Qu'est-ce que l'affiche veut que tu fasses ?", "difficulty": 3, "recommendedContext": "Une rue ou une station"},
    {"id": 67, "title": "Le flux d'un escalator", "category": "SYSTEMS", "mission": "Observe un escalator ou un tapis roulant comme un système de flux.", "cues": ["Les files et les dépassements", "Les points de blocage", "Ce qui régule le rythme"], "reflection": "Où le système perd-il de l'énergie ?", "difficulty": 4, "recommendedContext": "Une station"},
    {"id": 68, "title": "Les répétitions d'une façade", "category": "PATTERNS", "mission": "Trouve le motif répété d'une façade et ses trois variations.", "cues": ["Le motif de base", "Les variations discrètes", "Les cassures du motif"], "reflection": "Que révèlent les variations du motif ?", "difficulty": 3, "recommendedContext": "Une rue ancienne"},
    {"id": 69, "title": "Les attentes sociales", "category": "BEHAVIOR", "mission": "Observe ce que les gens font quand ils ne savent pas quoi faire : les comportements d'attente.", "cues": ["Les regards vers les autres", "Les micro-gestes", "Ce qui déclenche une action"], "reflection": "Quel comportement d'attente reconnais-tu chez toi ?", "difficulty": 4, "recommendedContext": "Une file d'attente"},
    {"id": 70, "title": "L'usure d'une poignée", "category": "DETAILS", "mission": "Examine une poignée ou un objet touché par des milliers de mains.", "cues": ["Les zones polies", "Les zones ignorées", "Ce que l'usure révèle de l'usage"], "reflection": "Qu'est-ce que l'usage a dessiné ?", "difficulty": 2, "recommendedContext": "Une porte publique"},
    {"id": 71, "title": "Les groupes qui se forment", "category": "PEOPLE", "mission": "Observe comment les groupes se forment, se séparent et se reforment dans un espace.", "cues": ["Les tailles de groupes", "Les distances internes", "Ce qui fait entrer ou sortir"], "reflection": "Dans quel groupe étais-tu, et pourquoi ?", "difficulty": 3, "recommendedContext": "Une terrasse ou un hall"},
    {"id": 72, "title": "Les trajets préférés", "category": "MOVEMENT", "mission": "Repère les trajets que les gens choisissent malgré l'absence de chemin.", "cues": ["Les raccourcis dans l'herbe", "Les diagonales évitées", "Les chemins balisés ignorés"], "reflection": "Que dit ton propre trajet de tes préférences ?", "difficulty": 3, "recommendedContext": "Un espace vert ou une cour"},
    {"id": 73, "title": "Les zones mortes d'un lieu", "category": "SPACE", "mission": "Trouve les zones d'un lieu que personne n'occupe jamais.", "cues": ["Les zones évitées", "Les bancs vides", "Les angles morts"], "reflection": "Pourquoi ces zones sont-elles mortes ?", "difficulty": 4, "recommendedContext": "Une place publique"},
    {"id": 74, "title": "Les visiteurs du lieu", "category": "NATURE", "mission": "Observe quels animaux visitent un même lieu et à quel moment.", "cues": ["Les espèces présentes", "Leurs trajectoires", "Leurs heures de passage"], "reflection": "Qu'est-ce que chaque visiteur cherche ?", "difficulty": 3, "recommendedContext": "Un jardin ou une cour"},
    {"id": 75, "title": "Les sons qui reviennent", "category": "SOUND", "mission": "Repère les sons qui reviennent régulièrement dans le lieu et ceux qui ne reviennent jamais.", "cues": ["Les sons cycliques", "Les sons uniques", "Le fond sonore constant"], "reflection": "Quel son rythme le lieu ?", "difficulty": 3, "recommendedContext": "Un lieu familier"},
    {"id": 76, "title": "L'ergonomie d'un guichet", "category": "DESIGN", "mission": "Observe une borne ou un guichet comme un objet ergonomique : ce qu'il facilite et ce qu'il complique.", "cues": ["Les hauteurs et les distances", "Les étapes imposées", "Les erreurs possibles"], "reflection": "Quelle friction ce dispositif ajoute-t-il ?", "difficulty": 4, "recommendedContext": "Une gare ou une administration"},
    {"id": 77, "title": "Les files secondaires", "category": "SYSTEMS", "mission": "Observe comment une file principale crée des files secondaires invisibles.", "cues": ["Les attentes debout", "Les allées et venues", "Les points de regroupement"], "reflection": "Quelle file secondaire es-tu en train de faire ?", "difficulty": 4, "recommendedContext": "Un marché ou un événement"},
    {"id": 78, "title": "Les motifs du carrelage", "category": "PATTERNS", "mission": "Choisis un sol carrelé et trouve le motif de base, puis ses variations dues à l'usage.", "cues": ["Le motif répété", "Les carreaux usés", "Les carreaux remplacés"], "reflection": "Que raconte l'usure du motif ?", "difficulty": 2, "recommendedContext": "Un sol public"},
    {"id": 79, "title": "Les gestes de politesse", "category": "BEHAVIOR", "mission": "Observe les micro-politesses qui rythment un lieu : qui cède le passage, qui tient la porte.", "cues": ["Les passages cédés", "Les portes tenues", "Les remerciements"], "reflection": "Quelle micro-politesse as-tu offerte aujourd'hui ?", "difficulty": 2, "recommendedContext": "Une entrée ou un couloir"},
    {"id": 80, "title": "Les traces d'une main", "category": "DETAILS", "mission": "Trouve un objet marqué par une seule main et lis l'histoire de cette trace.", "cues": ["La forme de la marque", "Sa profondeur", "Ce qu'elle révèle du geste"], "reflection": "Quel geste répété a laissé cette trace ?", "difficulty": 3, "recommendedContext": "Un outil ou un objet usagé"},
    {"id": 81, "title": "Les regards partagés", "category": "PEOPLE", "mission": "Observe les regards qui se croisent et ce qui les fait durer ou s'éteindre.", "cues": ["La durée des regards", "Ce qui les attire", "Ce qui les interrompt"], "reflection": "Quel regard as-tu soutenu aujourd'hui ?", "difficulty": 3, "recommendedContext": "Un transport ou une salle"},
    {"id": 82, "title": "Les hésitations", "category": "MOVEMENT", "mission": "Observe les moments où les gens hésitent avant de continuer.", "cues": ["Les pauses avant une porte", "Les demi-tours", "Les regards en arrière"], "reflection": "Où hésites-tu dans tes propres parcours ?", "difficulty": 4, "recommendedContext": "Un carrefour piéton"},
    {"id": 83, "title": "Les hauteurs d'un lieu", "category": "SPACE", "mission": "Observe un lieu à trois hauteurs : le sol, les yeux, le ciel.", "cues": ["Ce qui se passe au sol", "Ce qui se passe à hauteur des yeux", "Ce qui se passe en hauteur"], "reflection": "À quelle hauteur regardes-tu habituellement ?", "difficulty": 3, "recommendedContext": "Une rue"},
    {"id": 84, "title": "Les habitants du lieu", "category": "NATURE", "mission": "Observe un même lieu à deux heures différentes et note ce qui change.", "cues": ["La lumière", "Les présences", "Les sons"], "reflection": "Le lieu est-il le même aux deux heures ?", "difficulty": 3, "recommendedContext": "Un lieu que tu traverses souvent"},
    {"id": 85, "title": "Les silences d'une conversation", "category": "SOUND", "mission": "Dans un lieu de conversation, observe les silences entre les mots.", "cues": ["La durée des silences", "Ce qui les termine", "Ce qu'ils contiennent"], "reflection": "Quel silence as-tu laissé durer aujourd'hui ?", "difficulty": 4, "recommendedContext": "Un café ou une salle d'attente"},
    {"id": 86, "title": "La lisibilité d'un plan", "category": "DESIGN", "mission": "Observe un plan ou une signalétique et mesure sa lisibilité pour un inconnu.", "cues": ["Le point de départ évident", "Les choix proposés", "Ce qui est difficile à comprendre"], "reflection": "Quelle signalétique voudrais-tu refaire ?", "difficulty": 4, "recommendedContext": "Une station ou un bâtiment public"},
    {"id": 87, "title": "Les rythmes d'un marché", "category": "SYSTEMS", "mission": "Observe un marché comme un système avec ses heures, ses flux et ses équilibres.", "cues": ["Les heures de pointe", "Les flux de clients", "Les points d'équilibre"], "reflection": "Où le système est-il le plus fragile ?", "difficulty": 5, "recommendedContext": "Un marché"},
    {"id": 88, "title": "Les répétitions du vivant", "category": "PATTERNS", "mission": "Trouve un motif répété dans le vivant et ses variations.", "cues": ["Le motif de base", "Les variations individuelles", "Les anomalies"], "reflection": "Que disent les variations du motif ?", "difficulty": 3, "recommendedContext": "Un jardin ou une haie"},
    {"id": 89, "title": "Les contagions de gestes", "category": "BEHAVIOR", "mission": "Observe un geste qui se propage : quelqu'un fait quelque chose, et d'autres le répètent.", "cues": ["Le geste initial", "Les imitations", "La vitesse de propagation"], "reflection": "Quel geste as-tu imité sans le remarquer ?", "difficulty": 5, "recommendedContext": "Un lieu avec un public"},
    {"id": 90, "title": "La patine d'un objet quotidien", "category": "DETAILS", "mission": "Observe un objet que tu utilises chaque jour comme si tu le voyais pour la première fois.", "cues": ["Ses traces d'usage", "Ses zones intactes", "Ce qu'il révèle de toi"], "reflection": "Qu'est-ce que l'objet raconte de ta vie ?", "difficulty": 3, "recommendedContext": "Ton propre espace"}
]

def main():
    with open(PATH) as f:
        data = json.load(f)
    for d in data:
        category = "SPACE" if d["category"] == "CITY" else d["category"]
        d["category"] = category
        d["difficulty"] = max(1, min(5, (d["id"] - 1) // 15 + 1))
        d["recommendedContext"] = CONTEXT.get(category, "Un lieu public")
    data.extend(NEW)
    data.sort(key=lambda d: d["id"])
    with open(PATH, "w") as f:
        f.write("[\n")
        f.write(",\n".join(json.dumps(e, ensure_ascii=False) for e in data))
        f.write("\n]\n")
    print("missions:", len(data))

if __name__ == "__main__":
    main()
