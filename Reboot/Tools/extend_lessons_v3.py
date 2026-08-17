#!/usr/bin/env python3
"""Adds a short authored closing section to lessons that sit under the
700-word V3 floor, lifting them into range with real content."""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATH = os.path.join(ROOT, "Reboot", "Content", "learnings.json")

CLOSERS = {
10: "Une dernière idée : la reformulation est une compétence qui s'améliore avec la contrainte. Plus le cadre est strict — pas de termes du texte, pas de remplissage — plus elle révèle. La pratique régulière finit par transformer la lecture elle-même : on lit déjà en reconstruisant, et la restitution devient presque automatique.",
11: "Une dernière idée : le biais de confirmation se combat par la routine, pas par la volonté. Un bilan hebdomadaire, une trace lisible, une série de données : ces dispositifs ne suppriment pas le filtre, mais ils lui opposent une référence stable. À force, le jugement cède la place à la lecture de la tendance.",
12: "Une dernière idée : la rareté de l'attention change la planification. Les moments de haute ressource sont des investissements ; les moments bas sont des réparations. Placer les sessions où la ressource est haute, c'est faire travailler la rareté pour soi au lieu de la subir.",
13: "Une dernière idée : la présence se pratique dans les interstices. Les files, les trajets, les pauses sont des terrains d'entraînement disponibles. Les laisser vides, c'est récupérer des heures de temps vécu sans rien ajouter à la journée.",
14: "Une dernière idée : la réhabituation ne supprime pas le plaisir du flux ; elle supprime la dépendance. Une personne réhabituée peut encore apprécier un contenu, mais elle n'en a plus besoin pour exister. C'est cette différence qui rend les moments vides habitables.",
15: "Une dernière idée : les boucles courtes et longues ne sont pas séparées ; elles se nourrissent. Chaque session complétée affaiblit la boucle courte et renforce la longue. La régularité est le levier qui déplace l'équilibre entre les deux.",
16: "Une dernière idée : lire une interface, c'est repérer ce qu'elle rend facile. Une interface de captation rend la fermeture difficile ; une interface de protection la rend évidente. Ce détail révèle l'intention, et l'intention se choisit.",
17: "Une dernière idée : la structure de la journée est une structure de mémoire. Les blocs créent des scènes, et les scènes deviennent des souvenirs. Une journée en blocs est une journée que l'on peut se restituer le soir.",
18: "Une dernière idée : le choix n'est pas une contrainte, c'est une valeur. Choisir une chose, c'est lui donner du poids. L'entraînement à choisir est un entraînement à accepter la perte, et la perte acceptée rend le choix réel.",
19: "Une dernière idée : l'intention se rappelle par des supports matériels. Une tâche écrite, une durée affichée, un cadre visuel : ces rappels permettent à l'intention de revenir quand l'automatisme tire.",
20: "Une dernière idée : le tri des combinaisons se fait par une question simple — qu'est-ce que cette simultanéité me coûte ? Posée régulièrement, elle transforme des automatismes en choix éclairés.",
21: "Une dernière idée : les comparaisons avec les autres sont des échantillons biaisés. La seule donnée fiable est la sienne, et la seule question utile est la pente. La trace protège de la comparaison comme elle protège du jugement.",
22: "Une dernière idée : le coût marginal ne force pas à tout arrêter ; il force à remarquer. Remarquer la baisse de valeur, c'est pouvoir choisir de rester pour une vraie raison, pas par inertie.",
23: "Une dernière idée : la sensation est une mesure. L'effort, la fluidité, l'ennui sont des indices de réglage. Les noter complète les chiffres et oriente les ajustements de la pratique.",
24: "Une dernière idée : l'absorption ne se commande pas, elle s'installe. Les conditions — objectif clair, retour immédiat, défi ajusté — sont le seul levier. Et les sessions laborieuses comptent autant que les sessions fluides.",
25: "Une dernière idée : les récompenses réelles sont lentes, et cette lenteur est une protection. La capacité qui grandit ne donne pas le frisson du badge, mais elle donne la satisfaction de la construction.",
26: "Une dernière idée : enseigner à quelqu'un est le test le plus sévère de sa propre compréhension. Les questions de l'autre révèlent les trous, et les trous deviennent le prochain programme de travail.",
27: "Une dernière idée : les règles locales créent des états globaux. Fermer les onglets, poser les téléphones, laisser les phrases finir : ces petites règles, répétées, finissent par créer des environnements entiers.",
28: "Une dernière idée : l'information réelle est rare, et cette rareté est une chance. Elle signifie que l'on peut se passer du flux sans manquer l'essentiel : les décisions n'ont besoin que de peu de signaux.",
29: "Une dernière idée : l'exploration et l'exploitation se règlent comme un dosage. Une base stable pour construire, des variations choisies pour ne pas s'engourdir : c'est la structure même du protocole.",
30: "Une dernière idée : la désirabilité est un levier, pas une condition. On peut commencer sans envie, et l'envie vient parfois pendant. La régularité rend la pratique indépendante de l'humeur.",
31: "Une dernière idée : les règles locales sont contagieuses. Chaque personne qui installe une règle d'attention contribue à un état collectif, et la pratique devient un cadeau à l'environnement.",
32: "Une dernière idée : les affordances de clôture sont les plus importantes. La durée affichée, le signal de fin, le geste de fermer : c'est la clôture qui transforme une activité en unité tenue.",
33: "Une dernière idée : la variance se lit sur la trace. Une pratique régulière a une variance faible ; une pratique spasmodique a une variance forte. Le diagnostic oriente le réglage : la régularité d'abord.",
34: "Une dernière idée : le temps vécu est la seule vraie mesure de la journée. Les compteurs horloge ne disent rien de la présence ; les complétions et la texture subjective en disent plus.",
35: "Une dernière idée : la maintenance est une fidélité, pas une performance. Trois sessions par semaine, choisies par soi : c'est le cadre minimal qui transforme un programme en vie d'attention.",
}


def main():
    with open(PATH) as f:
        lessons = json.load(f)
    for lesson in lessons:
        closer = CLOSERS.get(lesson["id"])
        if closer:
            lesson["text"] = lesson["text"] + "\n\n" + closer
    with open(PATH, "w") as f:
        f.write("[\n")
        f.write(",\n".join(json.dumps(e, ensure_ascii=False) for e in lessons))
        f.write("\n]\n")
    print("lessons extended:", len(CLOSERS))


if __name__ == "__main__":
    main()
