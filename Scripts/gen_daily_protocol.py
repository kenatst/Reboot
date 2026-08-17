#!/usr/bin/env python3
"""Generates daily_protocol.json with exactly 90 distinct days, 6 narrative arcs, valid content IDs."""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "Reboot", "Content")
os.makedirs(CONTENT, exist_ok=True)

# 6 Narrative Arcs:
# Days 01–07: WE'RE LEARNING YOU (Calibrating)
# Days 08–21: CONTROL THE INPUT (Digital friction)
# Days 22–40: HOLD THE LINE (Focus duration & resistance)
# Days 41–60: GO DEEPER (Active retrieval & learning)
# Days 61–75: BUILD FLOW CONDITIONS (Flow Lab & Transfer)
# Days 76–90: OWN THE SYSTEM (Personal Rules & Operating Manual)

arc_titles = [
    # Days 1 to 7
    (1, "stay", None, "LIGNE DE BASE", "Mesurer ta durée naturelle sans forcer.", 15, 1, "Bureau propre, téléphone en vue mais non touché."),
    (2, "observe", 1, "AUDIT D'ENVIRONNEMENT", "Repérer les trois objets qui attirent ton regard.", 15, 1, "Prends 10 minutes d'observation attentive autour de toi."),
    (3, "recall", 1, "RESTITUTION INITIALE", "Lire un texte court, fermer le support et résumer.", 15, 1, "Lecture attentive d'un texte court sans pause."),
    (4, "nothing", 1, "TOLÉRANCE AU CALME", "Rester assis 3 minutes sans aucun stimulus.", 5, 1, "Assieds-toi confortablement, mains sur les cuisses."),
    (5, "stay", None, "FENÊTRE RÉELLE", "Travailler 20 minutes sur une seule tâche de fond.", 20, 1, "Document unique ouvert, téléphone retourné."),
    (6, "observe", 2, "PREMIER LEVIER", "Observer la circulation et le flux des passants.", 15, 1, "Poste d'observation extérieur sans écouteurs."),
    (7, "stay", None, "CARTE INITIALE", "Clôture de la semaine de calibrage : test de maintien.", 20, 1, "Bilan de tes 7 premiers jours et revue des mesures."),

    # Days 8 to 21
    (8, "stay", None, "LE BADGE", "Couper les pastilles rouges et mesurer l'apaisement.", 20, 1, "Téléphone configuré sans aucun badge de notification."),
    (9, "recall", 2, "LE FILTRE DE LECTURE", "Extraire la thèse sans relire le texte une deuxième fois.", 20, 2, "Lis le texte une seule fois à vitesse constante."),
    (10, "nothing", 2, "L'ATTENTE DU MATIN", "Passer la première transition de la journée sans écran.", 5, 1, "Attente active sans sollicitation."),
    (11, "explain", 1, "ENSEIGNER LE PREMIER MODÈLE", "Comprendre un concept et l'expliquer en trois étapes.", 25, 2, "Étudie le module puis formule l'explication à voix haute."),
    (12, "stay", None, "TÉLÉPHONE HORS DE LA PIÈCE", "Expérimenter la distance physique pendant un bloc de 25 min.", 25, 2, "Déposer l'appareil dans une autre pièce fermée."),
    (13, "observe", 3, "LES CHEMINS DE DÉSIR", "Observer les traces d'usure et les raccourcis urbains.", 20, 2, "Marche exploratoire de 15 minutes."),
    (14, "recall", 3, "ARCHITECTURE D'IDÉES", "Cartographier les arguments secondaires d'un essai.", 20, 2, "Reconstruis le plan détaillé de mémoire."),
    (15, "stay", None, "L'OBJECTIF CLAIR", "Poser par écrit le résultat exact attendu avant de démarrer.", 25, 2, "Une fiche avec une seule phrase de fin de bloc."),
    (16, "nothing", 3, "LE CAFÉ EN SILENCE", "Boire une boisson chaude sans aucun écran ni audio.", 10, 1, "Dégustation consciente sans média."),
    (17, "explain", 2, "LA STRUCTURE CAUSALE", "Expliquer comment A produit B dans un modèle économique.", 25, 2, "Isole la chaîne de cause à effet avant d'enseigner."),
    (18, "stay", None, "LE MUR DES 10 MINUTES", "Reconnaître l'impulsion de décrochage et la traverser.", 25, 2, "Surveille le seuil critique entre 8 et 12 minutes."),
    (19, "observe", 4, "LE PREMIER SWITCH", "Observer les gestes réflexes des usagers dans les transports.", 20, 2, "Prends note des postures corporelles d'évitement."),
    (20, "recall", 4, "RÉCUPÉRATION IMMÉDIATE", "Rédiger la synthèse dans les 60 secondes après lecture.", 20, 2, "Pas de délai : écris dès la fermeture du texte."),
    (21, "stay", None, "CONTRÔLE DU SIGNAL", "Valider la fin de la Phase 01 : 25 min de focus pur.", 25, 2, "Environnement épuré, zéro notification."),

    # Days 22 to 40
    (22, "stay", None, "TENIR LA LIGNE", "Allonger la fenêtre de maintien à 30 minutes.", 30, 2, "Tâche unitaire de fond, minuteur lancé."),
    (23, "explain", 3, "LA MÉTHODE FEYNMAN", "Vulgariser un principe sans aucun mot de jargon.", 25, 2, "Fais comme si tu t'adressais à un adolescent de 14 ans."),
    (24, "nothing", 4, "LA TRANSITION PROPRE", "Faire 5 minutes de vide complet entre deux réunions ou cours.", 5, 2, "Ferme les yeux et laisse décanter l'information."),
    (25, "recall", 5, "CONTRE-ARGUMENTS", "Trouver la faille ou la limite du texte étudié.", 25, 2, "Isole la principale objection logique à la thèse."),
    (26, "observe", 5, "LES FLUX DE FOULE", "Analyser comment l'espace guide les déplacements piétons.", 20, 2, "Poste d'observation dans un carrefour dense."),
    (27, "stay", None, "LE RETOUR EN 60 SECONDES", "Pratiquer le ré-engagement instantané après une micro-interruption.", 30, 2, "Si tu es coupé, reprends la dernière ligne sans attendre."),
    (28, "explain", 4, "LA DETTE ATTENTIONNELLE", "Comprendre le coût des tâches inachevées et l'enseigner.", 25, 2, "Formule les conséquences du multitâche chronique."),
    (29, "stay", None, "UNE SEULE FENÊTRE", "Travailler sur un document unique en plein écran.", 30, 2, "Dock masqué, navigateur fermé."),
    (30, "nothing", 5, "LA MARCHE SANS AUDIO", "Marcher 15 minutes dans la ville sans écouteurs.", 15, 2, "Écoute attentivement les sons de l'environnement."),
    (31, "recall", 6, "LECTURE ET SYNTHÈSE DENSE", "Résumer un texte de 800 mots en exactement 3 points cardinaux.", 25, 2, "Densité maximale : élimine tout mot inutile."),
    (32, "stay", None, "LE CAP DES 35 MINUTES", "Repousser la frontière de ton attention soutenue.", 35, 2, "Bloc exigeant sur un livrable stratégique."),
    (33, "observe", 6, "LES RITUELS DE TRAVAIL", "Observer comment s'installent les gens dans un café.", 20, 2, "Repère les objets posés en premier sur la table."),
    (34, "recall", 7, "LIS · FERME · RECONSTRUIS", "Perfectionner la séquence reine de l'apprentissage actif.", 25, 2, "Ferme le support avant de poser le premier mot."),
    (35, "explain", 5, "LE BIAIS DE DISPONIBILITÉ", "Enseigner comment les souvenirs récents faussent le jugement.", 30, 2, "Donne deux exemples concrets issus du quotidien."),
    (36, "stay", None, "LE SILENCE DU MATIN", "Placer un bloc de 35 min dans la première heure de travail.", 35, 2, "Zéro e-mail consulté avant la fin de ce bloc."),
    (37, "nothing", 6, "L'ATTENTE EN FILE", "Faire la queue dans un commerce sans sortir son téléphone.", 10, 2, "Garde les mains immobiles et observe l'espace."),
    (38, "observe", 7, "L'ARCHITECTURE DU CHOIX", "Analyser la disposition des produits dans un magasin.", 20, 2, "Repère ce qui est placé au niveau des yeux."),
    (39, "recall", 8, "TRANSFERT DE MODÈLE", "Appliquer un concept lu à un problème personnel actuel.", 25, 3, "Écris le lien direct entre la théorie et ta pratique."),
    (40, "stay", None, "LE MI-PARCOURS", "Valider la stabilité : 35 min sans la moindre bascule.", 35, 2, "Bilan de mi-parcours et mesure de la clarté."),

    # Days 41 to 60
    (41, "stay", None, "UNE LIGNE D'ARRIVÉE NETTE", "Définir le critère d'arrêt avant de poser les mains.", 35, 3, "Écris la condition de succès sur une fiche bristol."),
    (42, "explain", 6, "LA MÉMOIRE DE TRAVAIL", "Enseigner la limite des 4 items de la boucle phonologique.", 30, 3, "Explique pourquoi le multitâche sature le système."),
    (43, "recall", 9, "TEXTE LONG ET DENSE", "Restituer un texte de 1400 mots avec précision causale.", 30, 3, "Lecture lente d'un grand essai historique ou scientifique."),
    (44, "nothing", 7, "LE TEMPS SUSPENDU", "Rester 15 minutes dans le calme sans aucun support.", 15, 3, "Poste assis confortable, yeux ouverts ou fermés."),
    (45, "stay", None, "L'ISOLATION COMPLÈTE", "Bloquer toute communication extérieure pendant 40 min.", 40, 3, "Mode avion activé, porte fermée, casque antibruit."),
    (46, "observe", 8, "LES SIGNAUX INVISIBLES", "Repérer les micro-hésitations et postures dans un débat.", 25, 3, "Observation d'une interaction complexe."),
    (47, "explain", 7, "L'EFFET ZEIGARNIK", "Enseigner pourquoi les tâches inachevées hantent l'esprit.", 30, 3, "Démontre le mécanisme de la boucle ouverte."),
    (48, "recall", 10, "RÉPÉTITION ESPACÉE", "Réactiver un texte lu la semaine dernière sans le relire.", 25, 3, "Interrogation de mémoire sur un sujet ancien."),
    (49, "stay", None, "DURÉE ET DIFFICULTÉ", "Traiter le problème le plus intimidant de ta semaine.", 40, 3, "Attaque frontale de la tâche que tu repousses."),
    (50, "nothing", 8, "LA PAUSE EXTÉRIEURE", "Marcher 20 minutes dehors sans musique ni téléphone.", 20, 3, "Rythme de marche soutenu, regard libre."),
    (51, "explain", 8, "LES SYSTÈMES COMPLEXES", "Enseigner la notion de boucle de rétroaction et d'émergence.", 30, 3, "Illustre la théorie avec un exemple urbain."),
    (52, "stay", None, "LA PARTIE DIFFICILE", "Maintenir l'effort quand la solution ne vient pas immédiatement.", 40, 3, "Tolère l'incertitude pendant 40 minutes."),
    (53, "recall", 11, "EXTRACTION DU CADRE", "Distinguer les faits réels des interprétations de l'auteur.", 30, 3, "Analyse critique d'un texte d'opinion."),
    (54, "observe", 9, "L'USAGE DE L'ESPACE PUBLIC", "Analyser où les gens s'assoient et pourquoi.", 25, 3, "Cartographie des zones d'attraction dans un parc."),
    (55, "stay", None, "LE SHUTDOWN PROPRE", "Terminer une session par un rangement complet et le plan de demain.", 40, 3, "Clôture nette sans laisser de dossier ouvert."),
    (56, "nothing", 9, "LE CALME DU SOIR", "Passer 20 minutes avant le coucher sans lumière bleue.", 20, 3, "Ambiance tamisée, zéro écran dans la pièce."),
    (57, "explain", 9, "LE PRINCIPE DE PARETO", "Enseigner la loi des 80/20 appliquée à l'efficacité personnelle.", 30, 3, "Identifie les 20% d'actions qui produisent 80% du focus."),
    (58, "recall", 12, "SYNTHÈSE MULTI-SOURCES", "Croiser deux concepts lus récemment dans un seul résumé.", 30, 3, "Mise en relation de deux modèles mentaux."),
    (59, "stay", None, "LE STANDARD DES 45 MINUTES", "Franchir le palier des 45 minutes de travail ininterrompu.", 45, 3, "Grand bloc de production intellectuelle."),
    (60, "observe", 10, "LES MÉCANISMES D'INCITATION", "Observer comment une gare incite à la consommation.", 25, 3, "Repère les pièges visuels et sonores."),

    # Days 61 to 75
    (61, "stay", None, "CONDITIONS DE FLOW", "Lancer un bloc Flow Lab avec tâche découpée et fin claire.", 45, 3, "Contrat de flow défini dans le Flow Lab."),
    (62, "explain", 10, "DÉFI VERSUS COMPÉTENCE", "Enseigner le modèle du canal de flow de Csikszentmihalyi.", 30, 3, "Explique comment naviguer entre ennui et anxiété."),
    (63, "recall", 13, "RESTITUTION STRUCTURÉE", "Reconstruire une démonstration logique étape par étape.", 30, 3, "Vérifie que chaque déduction découle de la précédente."),
    (64, "nothing", 10, "LE SILENCE TOTAL", "20 minutes de repos sensoriel complet sans aucune entrée.", 20, 3, "Régénération profonde du cortex préfrontal."),
    (65, "stay", None, "LE FEEDBACK VISUEL", "Travailler avec un indicateur d'avancement tangible en direct.", 45, 3, "Compteur de mots ou étapes cochées à vue."),
    (66, "observe", 11, "LA SYNCHRONISATION SOCIALE", "Observer le mimétisme postural dans un groupe de travail.", 25, 3, "Repère les signaux de cohésion non verbaux."),
    (67, "explain", 11, "LA RÉFUTABILITÉ DE POPPER", "Enseigner pourquoi une hypothèse doit pouvoir être testée.", 35, 3, "Distingue la science de la croyance dogmatique."),
    (68, "stay", None, "TROP FACILE / TROP DUR", "Ajuster la difficulté en direct pour rester dans la zone de flow.", 45, 3, "Montez ou baissez la contrainte selon ton état."),
    (69, "recall", 14, "LECTURE CRITIQUE DENSE", "Résumer un grand texte philosophique sans simplification abusive.", 30, 3, "Respecte la nuance et les ambiguïtés du propos."),
    (70, "nothing", 11, "L'ATTENTE LIBRE", "Traverser un imprévu de planning sans ouvrir ton téléphone.", 15, 3, "Garde le calme face au retard ou au contretemps."),
    (71, "stay", None, "LE TRANSFERT DE PASSION", "Importer les conditions de ton jeu ou sport dans ton travail.", 45, 3, "Applique le feedback court à ton dossier actuel."),
    (72, "explain", 12, "L'INTERLEAVING", "Enseigner pourquoi l'alternance bat le bachotage massif.", 35, 3, "Démontre l'effet sur la mémoire à long terme."),
    (73, "observe", 12, "L'ERGONOMIE INVISIBLE", "Observer les objets dont le design parfait les rend transparents.", 25, 3, "Isole trois outils remarquablement conçus."),
    (74, "recall", 15, "ENSEIGNER À UN PROFANE", "Expliquer un sujet ardu avec des analogies quotidiennes.", 30, 3, "Fais tester ta clarté auprès d'un tiers."),
    (75, "stay", None, "LES CONDITIONS VALIDÉES", "Clôture de la phase Flow : bloc de 45 min en immersion totale.", 45, 3, "Toutes les conditions réunies : silence, fin, feedback."),

    # Days 76 to 90
    (76, "stay", None, "TES RÈGLES PERSONNELLES", "Formaliser tes 5 règles attentionnelles testées et validées.", 45, 3, "Rédige ton manifeste d'environnement personnel."),
    (77, "explain", 13, "LA SOUVERAINETÉ ATTENTIONNELLE", "Enseigner pourquoi l'attention est le capital ultime du XXIe siècle.", 35, 3, "Synthèse des 11 semaines d'apprentissage."),
    (78, "recall", 16, "RECONSTRUCTION HISTORIQUE", "Restituer une chaîne d'événements historiques complexes.", 30, 3, "Régularité des dates, causes et conséquences."),
    (79, "nothing", 12, "LE REPOS DU MAÎTRE", "25 minutes de vide complet sans aucune sollicitation.", 25, 3, "Immersion dans le calme sans attente."),
    (80, "stay", None, "LE BLOC DE HAUTE VALEUR", "Réaliser 50 minutes de travail sur ton grand projet de vie.", 50, 3, "Concentration totale sur l'essentiel."),
    (81, "observe", 13, "LE MONDE NUMÉRISÉ", "Observer la capture attentionnelle généralisée dans la rue.", 25, 3, "Regarde le contraste entre les passants et ta présence."),
    (82, "explain", 14, "LA DETTE COGNITIVE", "Enseigner la gestion de l'énergie et la prévention de l'épuisement.", 35, 3, "Démontre l'impact des micro-pauses sans écran."),
    (83, "recall", 17, "LE TEST DE SYNTHÈSE", "Résumer l'ensemble des 5 modèles mentaux les plus marquants.", 35, 3, "Création d'une grille de lecture transversale."),
    (84, "stay", None, "LA MAÎTRISE DU TEMPS", "Gérer une session de 50 min avec transition propre à la fin.", 50, 3, "Arrêt net à la sonnerie avec livrable prêt."),
    (85, "stay", None, "CONÇOIS TON PROTOCOLE", "Définir tes propres exercices pour les 5 derniers jours.", 50, 3, "Autonomie complète : choisis ta discipline."),
    (86, "nothing", 13, "LA DERNIÈRE PAUSE", "25 minutes de contemplation sans aucun objectif utilitaire.", 25, 3, "Habite l'espace sans rien chercher à produire."),
    (87, "recall", 18, "LE BILAN DE RÉTENTION", "Interrogation sur les concepts clés du début de protocole.", 30, 3, "Constat de la solidité des traces mnésiques."),
    (88, "explain", 15, "TRANSMETTRE LA MÉTHODE", "Expliquer l'architecture de REBOOT à quelqu'un qui veut démarrer.", 35, 3, "Expose les trois piliers : filtre, maintien, rappel."),
    (89, "stay", None, "L'AVANT-DERNIER BLOC", "50 minutes de focus souverain sur ta création principale.", 50, 3, "Démonstration finale de stabilité attentionnelle."),
    (90, "stay", None, "OWN IT.", "Jour 90. Clôture officielle et génération de ton Manuel Opératoire.", 50, 3, "Consulte ton Attention Operating Manual et entre en Core Mode.")
]

protocol_days = []
for day_num, mode_name, content_id, title, why_today, dur, diff, setup in arc_titles:
    phase = 1 if day_num <= 21 else (2 if day_num <= 40 else (3 if day_num <= 60 else (4 if day_num <= 75 else 5)))
    if day_num > 75: phase = 4  # Keep within 4 phases if schema specifies 1..4
    week = ((day_num - 1) // 7) + 1
    
    ctype = "stay"
    cid = None
    if mode_name == "recall":
        ctype = "reading"
        cid = content_id or ((day_num % 125) + 1)
    elif mode_name == "explain":
        ctype = "lesson"
        cid = content_id or ((day_num % 85) + 1)
    elif mode_name == "observe":
        ctype = "mission"
        cid = content_id or ((day_num % 125) + 1)
    elif mode_name == "nothing":
        ctype = "void"
        cid = content_id or ((day_num % 80) + 1)

    protocol_days.append({
        "day": day_num,
        "phase": min(4, phase),
        "week": week,
        "mode": mode_name,
        "skill": f"ATTENTION_{mode_name.upper()}",
        "title": f"JOUR {day_num:03d} — {title.upper()}",
        "intention": f"Maintenir une présence totale pendant {dur} minutes sur l'exercice du jour.",
        "whyToday": why_today,
        "duration": dur,
        "difficulty": diff,
        "setup": setup,
        "instructions": [
            "Élimine toute distraction potentielle de ton champ visuel et auditif.",
            "Pose l'intention exacte de la session avant de lancer le minuteur.",
            "En cas d'impulsion de décrochage, prends acte du signal sans agir et reviens à la tâche."
        ],
        "challenge": "Garder les yeux fixés sur la tâche active jusqu'à la sonnerie finale sans un seul switch.",
        "reflection": "Quelle a été la principale tension ressentie et comment l'as-tu traversée ?",
        "contentType": ctype,
        "contentID": cid,
        "completionMessage": f"Jour {day_num:03d} complété. Ton attention s'ancre dans la durée."
    })

with open(os.path.join(CONTENT, "daily_protocol.json"), "w", encoding="utf-8") as f:
    json.dump(protocol_days, f, ensure_ascii=False, indent=2)

print(f"Generated daily_protocol.json ({len(protocol_days)} days)")
