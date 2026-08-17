#!/usr/bin/env python3
"""Generates micro_insights.json, coaching_messages.json, checkpoints.json, void_prompts.json."""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "Reboot", "Content")
os.makedirs(CONTENT, exist_ok=True)

# 1. 90 MICRO INSIGHTS (Sharp, 2-4 sentences, quotable, no modulo loops)
micro_insights = [
    {"day": 1, "text": "L'attention n'est pas une réserve d'énergie magique, c'est un mécanisme de filtrage. Ce que tu ne laisses pas entrer n'a pas besoin d'être combattu."},
    {"day": 2, "text": "Le geste vers le téléphone précède la pensée de 300 millisecondes. Repérer le micro-mouvement est la première barrière de défense."},
    {"day": 3, "text": "L'illusion de fluidité te fait croire que lire, c'est savoir. La seule connaissance réelle est celle que tu peux reconstruire sans support."},
    {"day": 4, "text": "Le vide n'est pas du temps perdu, c'est le moment où ton réseau cérébral par défaut réorganise ce que tu viens d'apprendre."},
    {"day": 5, "text": "Une tâche sans fin mesurable est une invitation permanente au décrochage. Définis l'arrêt avant de poser les mains."},
    {"day": 6, "text": "Les environnements propres réduisent la charge cognitive passive. Chaque objet visible réclame une fraction d'analyse attentionnelle."},
    {"day": 7, "text": "Une semaine de calibrage ne juge pas ta volonté. Elle trace la carte exacte de tes points de friction."},
    {"day": 8, "text": "Les pastilles rouges exploitent ton biais de complétion. Les désactiver coupe le stimulus avant qu'il ne déclenche l'impulsion."},
    {"day": 9, "text": "Le multitâche n'existe pas pour les tâches cognitives exigeantes. Tu ne fais que payer le coût de réactivation à chaque saut."},
    {"day": 10, "text": "Le premier switch survient souvent quand la difficulté augmente légèrement. Reconnais la tension comme un signal d'apprentissage, pas d'ennui."},
    {"day": 11, "text": "Le téléphone posé sur le bureau réduit la capacité de mémoire de travail disponible, même éteint. La distance physique libère du processeur."},
    {"day": 12, "text": "Une friction de vingt secondes suffit à briser 80% des automatismes numériques. Rend l'accès légèrement pénible."},
    {"day": 13, "text": "Le flux infini est conçu sans ligne d'arrivée. Tu ne t'arrêteras jamais naturellement : c'est à toi d'imposer le cadre temporel."},
    {"day": 14, "text": "Deux semaines de friction changent le réflexe. Ton cerveau commence à tolérer trois minutes sans chercher de nouveau stimulus."},
    {"day": 15, "text": "La clarté de l'étape suivante est le plus puissant antidote à la procrastination. Si tu hésites plus de dix secondes, décompose la tâche."},
    {"day": 16, "text": "L'ennui est le terreau de l'imagination profonde. Les esprits constamment stimulés ne produisent que des échos."},
    {"day": 17, "text": "Quand tu fermes un livre, résume l'idée centrale en une phrase. C'est l'effort de rappel qui consolide les traces mnésiques."},
    {"day": 18, "text": "Le mode focus n'est pas une punition, c'est un contrat avec toi-même. Protège ton temps comme un actif rare."},
    {"day": 19, "text": "Observer les détails physiques d'une pièce ancre ton attention dans le réel. C'est un entraînement direct de ton orientation perceptive."},
    {"day": 20, "text": "La fatigue mentale ressemble à de la paresse, mais c'est une baisse de carburant attentionnel. Choisis une vraie pause, pas du scroll."},
    {"day": 21, "text": "Trois semaines pour reprendre le contrôle de l'entrée. Moins de bruit entrant signifie plus de clarté pour penser."},
    {"day": 22, "text": "La stabilité attentionnelle se muscle comme un tendon. Chaque minute supplémentaire au-delà de l'envie de décrocher compte double."},
    {"day": 23, "text": "Ne confonds pas réactivité et efficacité. Répondre à un message dans la minute détruit vingt minutes de focus profond."},
    {"day": 24, "text": "Le sommeil n'est pas négociable pour l'attention. Une nuit tronquée dégrade la fonction exécutive dès le lendemain matin."},
    {"day": 25, "text": "La répétition espacée bat l'accumulation massive. Vaut mieux quinze minutes de rappel trois fois par semaine que trois heures d'affilée."},
    {"day": 26, "text": "L'éclairage et l'air frais ont un impact mesurable sur la vigilance. Optimise ton poste de travail avant de blâmer ta volonté."},
    {"day": 27, "text": "Quand tu décroches, ne t'insulte pas. Prends acte du switch et reviens à la tâche en moins de soixante secondes."},
    {"day": 28, "text": "Un mois complet. Les réflexes automatiques ont reculé. Tu commences à habiter ton propre espace mental."},
    {"day": 29, "text": "La dopamine récompense la nouveauté, pas la valeur. Les flux sociaux te vendent du signal sans contenu."},
    {"day": 30, "text": "Le travail en profondeur exige une porte fermée, physique ou symbolique. Préviens ton entourage : ce bloc t'appartient."},
    {"day": 31, "text": "La lecture lente n'est pas un retard, c'est une digestion. Ruminer un paragraphe complexe vaut mieux que survoler dix pages."},
    {"day": 32, "text": "Le bruit ambiant cohérent peut aider certains profils, mais le silence complet reste la référence pour l'abstraction pure."},
    {"day": 33, "text": "Un objectif flou produit une attention fuyante. Écris exactement ce qui doit exister à la fin de cette session."},
    {"day": 34, "text": "Apprendre, c'est encoder, stocker et récupérer. La plupart des gens oublient la troisième étape, qui est pourtant la seule décisive."},
    {"day": 35, "text": "Le café masque l'adénosine mais ne crée pas d'énergie. Chronomètre sa prise pour ne pas cannibaliser ton sommeil profond."},
    {"day": 36, "text": "La marche sans écran est le plus puissant réinitialisateur attentionnel. Dix minutes dehors rétablissent la vigilance descendante."},
    {"day": 37, "text": "Chaque onglet ouvert est une boucle ouverte dans ta mémoire de travail. Ferme tout ce qui ne sert pas la tâche active."},
    {"day": 38, "text": "La résistance mentale est maximale dans les cinq premières minutes. Traverse ce mur et la tâche devient fluide."},
    {"day": 39, "text": "Ne lis pas pour accumuler des faits isolés. Cherche les modèles sous-jacents qui relient des domaines différents."},
    {"day": 40, "text": "Mi-parcours. Tu ne subis plus tes impulsions avec la même fatalité. Tu sais désormais ce que coûte chaque distraction."},
    {"day": 41, "text": "Le flow n'est pas un coup de chance, c'est une équation : clarté de but, retour immédiat et niveau de défi adapté."},
    {"day": 42, "text": "Quand la tâche est trop facile, tu t'ennuies et tu switches. Augmente la contrainte de temps ou la précision exigée."},
    {"day": 43, "text": "Quand la tâche est trop difficile, tu paniques et tu fuis. Découpe-la jusqu'à ce que la première sous-tâche soit évidente."},
    {"day": 44, "text": "La métacognition est la capacité de t'observer en train de penser. Remarque quand ton esprit s'échappe sans paniquer."},
    {"day": 45, "text": "Un feedback visuel d'avancement transforme une corvée en jeu d'absorption. Rends tes progrès visibles en direct."},
    {"day": 46, "text": "La pause active ne comporte aucun texte. Bouge, bois de l'eau, regarde au loin, mais ne nourris pas tes yeux de pixels."},
    {"day": 47, "text": "Expliquer un concept complexe à un profane révèle impitoyablement tes zones d'ombre. C'est le test ultime de maîtrise."},
    {"day": 48, "text": "Les notifications de groupe sont la pire invention pour l'attention. Mets en sourdine tout ce qui n'est pas urgent."},
    {"day": 49, "text": "La friction positive t'oblige à décider consciemment. Chaque barrière installée est un hommage à ton travail futur."},
    {"day": 50, "text": "Cinquante jours. Ton attention n'est plus à la merci des algorithmes. Tu as bâti une forteresse opérationnelle."},
    {"day": 51, "text": "La créativité émerge de la collision d'idées bien digérées, pas du zapping continu. Nourris-toi de lectures denses."},
    {"day": 52, "text": "La capacité à rester seul dans une pièce sans divertissement est le super-pouvoir du XXIe siècle."},
    {"day": 53, "text": "La musique instrumentale à tempo régulier stabilise le rythme cardiaque sans surcharger le cortex verbal."},
    {"day": 54, "text": "Quand tu écris, écris d'abord sans corriger. La critique prématurée paralyse le flux de pensée."},
    {"day": 55, "text": "Le test d'interrogation élaborative : demande-toi systématiquement 'Pourquoi ce fait est-il vrai ?' pour l'ancrer en profondeur."},
    {"day": 56, "text": "L'alimentation lourde détourne le flux sanguin vers la digestion. Place tes blocs cognitifs les plus rudes avant les gros repas."},
    {"day": 57, "text": "La qualité de ton travail dépend directement du niveau de focus multiplié par le temps passé sans résidu attentionnel."},
    {"day": 58, "text": "Observer l'architecture d'un lieu t'apprend à décoder les intentions des concepteurs. Rien dans l'espace n'est neutre."},
    {"day": 59, "text": "Deux mois de transformation. Tu as prouvé que ton attention peut être reconstruite méthodiquement."},
    {"day": 60, "text": "Le flow durable demande un rituel d'entrée. Même heure, même bureau, même musique, même intention."},
    {"day": 61, "text": "Transfère les conditions de tes passions dans ton travail : feedback clair, défi calibré et absence totale d'interruption."},
    {"day": 62, "text": "La règle des deux minutes : si une sous-tâche prend moins de deux minutes pendant un bloc de focus, note-la mais ne la fais pas."},
    {"day": 63, "text": "L'interleaving consiste à alterner deux types de problèmes liés. C'est plus dur au début, mais la rétention finale est doublée."},
    {"day": 64, "text": "La lumière naturelle du matin synchronise ton horloge biologique. Expose tes yeux au jour dès le réveil."},
    {"day": 65, "text": "Un bloc de travail réussi se termine par un shutdown propre : notes rangées, prochaine action écrite, écran fermé."},
    {"day": 66, "text": "Ne négocie jamais avec une impulsion en plein vol. Applique la règle établie avant la session."},
    {"day": 67, "text": "La mémoire humaine n'est pas un magnétophone, c'est un processus de reconstruction dynamique. Réactive régulièrement tes acquis."},
    {"day": 68, "text": "Quand le doute s'installe sur un projet, reviens à la ligne d'arrivée minimale. Que faut-il pour que ce soit fini ?"},
    {"day": 69, "text": "Les environnements d'apprentissage doivent être variés pour favoriser la généralisation des concepts."},
    {"day": 70, "text": "Dix semaines. Tu as développé une tolérance exemplaire à l'effort mental prolongé."},
    {"day": 71, "text": "Les meilleurs penseurs ne sont pas plus intelligents, ils protègent mieux leurs fenêtres de concentration."},
    {"day": 72, "text": "L'impulsion de vérifier ses mails cache souvent une peur de s'attaquer au problème fondamental. Affronte le dur."},
    {"day": 73, "text": "La clarté d'exposition est la politesse de l'esprit. Simplifie tes explications sans en trahir la rigueur."},
    {"day": 74, "text": "Prendre une pause complète entre deux projets évite le résidu attentionnel qui pollue la tâche suivante."},
    {"day": 75, "text": "Tes conditions de flow sont désormais identifiées. Tu sais quel levier actionner pour entrer dans la zone."},
    {"day": 76, "text": "Tes règles personnelles ne sont pas des dogmes : ce sont des outils pragmatiques validés par l'expérience."},
    {"day": 77, "text": "La discipline n'est pas une contrainte imposée de l'extérieur, c'est la liberté choisie de diriger ton esprit."},
    {"day": 78, "text": "Relire tes notes de lecture stimule la sérendipité et permet d'associer des idées distantes."},
    {"day": 79, "text": "Le vrai luxe contemporain n'est pas d'avoir accès à tout, c'est de pouvoir s'isoler volontairement."},
    {"day": 80, "text": "Quatre-vingts jours. Ton architecture cognitive est solide. Tu es prêt pour la phase finale d'appropriation."},
    {"day": 81, "text": "Conçois tes journées autour de tes blocs de haute valeur, pas autour des urgences des autres."},
    {"day": 82, "text": "La fatigue décisionnelle s'accumule avec chaque micro-choix. Automatise les détails matériels pour garder ton énergie."},
    {"day": 83, "text": "L'écoute active est une forme suprême d'attention soutenue. Entraîne-toi à ne pas préparer ta réponse pendant qu'on te parle."},
    {"day": 84, "text": "La maîtrise d'un sujet se mesure à ta capacité à en réfuter les thèses adverses avec honnêteté intellectuelle."},
    {"day": 85, "text": "Tu es l'architecte de ton protocole. Choisis les exercices qui résonnent le plus avec tes objectifs de vie."},
    {"day": 86, "text": "La constance bat l'intensité. Mieux vaut une heure de focus chaque jour qu'une nuit blanche chaotique."},
    {"day": 87, "text": "Ce que tu as appris au cours de ces 90 jours ne s'effacera pas si tu maintiens les règles d'environnement clés."},
    {"day": 88, "text": "Le calme mental n'est pas l'absence de pensées, c'est l'absence d'agitation impulsive."},
    {"day": 89, "text": "Demain s'achève le protocole officiel. Ton manuel opératoire personnel deviendra ta boussole permanente."},
    {"day": 90, "text": "Quatre-vingt-dix jours. Tu as reconstruit ton attention. Elle t'appartient désormais."}
]

# 2. 13 CHECKPOINTS / WEEKLY REVIEWS
checkpoints = [
    {
        "week": 1,
        "title": "SEMAINE 01 / CALIBRAGE INITIAL",
        "insight": "La première semaine n'est pas là pour juger ta volonté, mais pour mesurer la réalité de tes impulsions et cartographier tes zones de fragilité.",
        "objective": "Établir la ligne de base de ton attention sans artifice.",
        "questions": [
            "Quelle a été ta durée moyenne avant le premier réflexe de vérification ?",
            "Quel distracteur s'est manifesté le plus souvent ?",
            "Quelle est la principale source de friction repérée dans ton environnement ?"
        ]
    },
    {
        "week": 2,
        "title": "SEMAINE 02 / CONTRÔLE DE L'ENTRÉE",
        "insight": "L'installation des premières frictions physiques réduit la charge mentale automatique de plus de moitié.",
        "objective": "Couper les déclencheurs passifs et protéger le réveil.",
        "questions": [
            "As-tu réussi à garder ton téléphone hors de portée pendant tes sessions ?",
            "Quel changement de notification a eu le plus d'impact ?",
            "Comment s'est passée ta première heure de réveil sans flux ?"
        ]
    },
    {
        "week": 3,
        "title": "SEMAINE 03 / STABILISATION DES BLOCS",
        "insight": "L'attention soutenue commence à se consolider lorsque tu dépasses la friction des cinq premières minutes.",
        "objective": "Atteindre 25 minutes de focus continu sans bascule.",
        "questions": [
            "À quel moment précis de la session ressens-tu la tension de quitter la tâche ?",
            "As-tu appliqué la règle des 60 secondes après une interruption ?",
            "Quelle discipline (Stay, Recall, Nothing) t'a semblé la plus exigeante ?"
        ]
    },
    {
        "week": 4,
        "title": "SEMAINE 04 / BILAN DE FIN DE PHASE 01",
        "insight": "Un mois complet. Les automatismes réflexes sont affaiblis. Le premier tiers du protocole est validé.",
        "objective": "Vérifier le recul mesurable du réflexe numérique.",
        "questions": [
            "Quel est ton nouveau temps médian avant le premier switch ?",
            "Quelle règle d'environnement vas-tu conserver définitivement ?",
            "Quel est ton niveau d'énergie moyen lors des sessions ?"
        ]
    },
    {
        "week": 5,
        "title": "SEMAINE 05 / RESTITUTION ET MÉMOIRE ACTIVE",
        "insight": "Lire sans fermer le livre pour reconstruire est une illusion de compétence. L'effort de rappel est la clé.",
        "objective": "Augmenter la précision de tes synthèses après lecture.",
        "questions": [
            "Arrives-tu à extraire la thèse centrale d'un texte dès la première lecture ?",
            "Quels sont les détails ou mécanismes qui t'échappent le plus souvent ?",
            "La technique 'LIS · FERME · RECONSTRUIS' devient-elle plus naturelle ?"
        ]
    },
    {
        "week": 6,
        "title": "SEMAINE 06 / RÉSISTANCE COGNITIVE",
        "insight": "La difficulté intellectuelle d'une tâche ne doit plus être interprétée comme un signal d'ennui, mais comme un effort d'encodage.",
        "objective": "Maintenir 35 minutes de focus sur une tâche complexe.",
        "questions": [
            "Comment réagis-tu face à une idée difficile ou abstraite ?",
            "Combien de fois as-tu ressenti l'envie de fuir vers un onglet secondaire ?",
            "Quelle stratégie de décomposition as-tu utilisée ?"
        ]
    },
    {
        "week": 7,
        "title": "SEMAINE 07 / AMORÇAGE DU FLOW LAB",
        "insight": "Le flow exige un contrat clair : une définition de fin explicite, un feedback visible et une tâche découpée.",
        "objective": "Définir et lancer ton premier projet Flow avec critères précis.",
        "questions": [
            "Ta définition de 'terminé' était-elle suffisamment concrète ?",
            "Quel mécanisme de feedback as-tu choisi pour mesurer ta progression ?",
            "As-tu perdu la notion du temps pendant ta session de flow ?"
        ]
    },
    {
        "week": 8,
        "title": "SEMAINE 08 / BILAN DE FIN DE PHASE 02",
        "insight": "Deux mois de transformation. Ta capacité attentionnelle a doublé par rapport à la semaine de calibrage.",
        "objective": "Consolider la transition vers le travail en profondeur.",
        "questions": [
            "Quels progrès observes-tu dans ta vitesse de démarrage d'une session ?",
            "Ton sommeil et ton énergie sont-ils mieux synchronisés avec tes blocs ?",
            "Quelles sont les conditions indispensables à ton focus ?"
        ]
    },
    {
        "week": 9,
        "title": "SEMAINE 09 / TRANSFERT DES CONDITIONS DE FLOW",
        "insight": "Les conditions qui te font oublier ton téléphone dans tes loisirs peuvent être importées dans ton travail intellectuel.",
        "objective": "Appliquer tes leviers d'absorption à une tâche administrative ou rébarbative.",
        "questions": [
            "Quel levier (défi, feedback, décomposition) a le mieux fonctionné ?",
            "As-tu ressenti une baisse de friction au démarrage ?",
            "Comment as-tu géré les micro-interruptions internes ?"
        ]
    },
    {
        "week": 10,
        "title": "SEMAINE 10 / TOLÉRANCE AU CALME COMPLET",
        "insight": "Être capable de traverser un temps mort sans chercher de stimulation externe est la marque d'un esprit souverain.",
        "objective": "Réussir des transitions nettes de 5 minutes sans écran entre les tâches.",
        "questions": [
            "Comment vis-tu les moments d'attente imprévus dans ta journée ?",
            "As-tu réussi à faire une pause sans toucher à un média ou un flux ?",
            "Quelle clarté mentale ressens-tu après un exercice Nothing ?"
        ]
    },
    {
        "week": 11,
        "title": "SEMAINE 11 / STRUCTURATION DES RÈGLES PERSONNELLES",
        "insight": "Tes règles personnelles ne doivent pas être des contraintes subies, mais des protocoles protecteurs testés et approuvés.",
        "objective": "Sélectionner et formaliser tes 5 règles de vie attentionnelles pérennes.",
        "questions": [
            "Quelles sont les 3 règles les plus efficaces de ton système ?",
            "Y a-t-il une règle que tu souhaites abandonner ou assouplir ?",
            "Comment réagis-tu face aux sollicitations imprévues de ton entourage ?"
        ]
    },
    {
        "week": 12,
        "title": "SEMAINE 12 / AUTONOMIE ET PROTOCOLE PERSONNEL",
        "insight": "Tu n'as plus besoin d'un cadre rigide imposé : tu conçois toi-même les blocs adaptés à tes projets du moment.",
        "objective": "Piloter une semaine entière selon ton propre calendrier de focus.",
        "questions": [
            "Quelles disciplines choisis-tu spontanément chaque matin ?",
            "Quelle durée de bloc te paraît aujourd'hui la plus productive ?",
            "Comment prépares-tu la transition vers la fin des 90 jours ?"
        ]
    },
    {
        "week": 13,
        "title": "SEMAINE 13 / CLÔTURE ET MANUEL OPÉRATOIRE",
        "insight": "Le protocole de 90 jours s'achève. Ton attention est rééduquée et armée. Ton manuel opératoire personnel prend le relais.",
        "objective": "Consulter ton Manuel Opératoire et entrer en Core Mode permanent.",
        "questions": [
            "Quelle est la plus grande transformation constatée depuis le Jour 1 ?",
            "Quels sont les signaux d'alerte que tu sais désormais repérer immédiatement ?",
            "Comment vas-tu organiser ta pratique hebdomadaire de maintenance ?"
        ]
    }
]

# 3. 210 COACHING MESSAGES (12 Categories, Sharp Voice)
categories = [
    "return", "failure", "low_energy", "progress", "refusal", "overwhelm",
    "boredom", "recall", "strong_result", "missed_day", "experiment", "flow"
]

coaching_messages = []
msg_id = 1

raw_coaching = {
    "return": [
        "Tu as décroché. Pas de drame. Reviens dans les 60 secondes.",
        "Le switch est un réflexe, le retour est un choix. Repose tes yeux sur la tâche.",
        "Ne t'arrête pas au décrochage. La vraie mesure de ta force, c'est la vitesse de ton retour.",
        "L'impulsion a gagné une manche. Reprends la phrase où tu t'étais arrêté.",
        "Chaque retour rapide réécrit le circuit du réflexe. Reviens maintenant.",
        "Tu as touché ton téléphone ? Pose-le à l'envers et termine la minute en cours.",
        "La distraction est un fait, l'abandon est une décision. Reviens.",
        "Un retour immédiat annule le coût de changement d'attention. Reprends.",
        "Pas d'autocritique. Respire et replace ton focus sur l'objectif.",
        "C'est dans le retour que réside l'entraînement. Tu es exactement là où il faut.",
        "Tu as glissé. Rien de grave. Le protocole t'attend.",
        "Ce n'est pas le premier switch qui compte, c'est le temps que tu mets à réagir.",
        "Reviens sans négocier avec l'envie de vérifier un dernier onglet.",
        "L'attention est un muscle : chaque ré-engagement est une répétition.",
        "Ferme la fenêtre parasite. Reprends ton fil.",
        "Tu as senti l'urge ? Parfait. Maintenant, reviens à la tâche principale.",
        "Le décrochage est de l'information. Utilise-le pour durcir ton environnement.",
        "Reviens maintenant. Pas dans cinq minutes."
    ],
    "failure": [
        "L'action a échoué. On ne force pas un mur : on adapte la friction.",
        "Le blocage complet était trop dur ? On passe à une règle de consultation planifiée.",
        "L'échec d'une règle n'est pas un échec de volonté. C'est un problème de conception.",
        "On jette ce qui ne marche pas. On garde ce qui protège ton temps.",
        "Si l'obstacle est le travail ou la famille, le blocage total est absurde. Trouve la nuance.",
        "Une règle trop rigide casse au premier imprévu. Rends-la réaliste.",
        "Pas de culpabilité. On réajuste le niveau de défi dès aujourd'hui.",
        "Tu n'as pas réussi l'action ? Analyse où la friction a cédé.",
        "L'environnement a gagné cette fois. On déplace le verrou.",
        "Une règle contournée est une règle mal calibrée. Simplifie-la.",
        "Reconnaître qu'une méthode ne convient pas est un gain de temps précieux.",
        "On teste le plan B. C'est pour ça qu'il existe.",
        "Ce n'est pas un abandon, c'est un calibrage empirique.",
        "La règle doit servir ton focus, pas flatter une idée abstraite de discipline.",
        "On baisse la contrainte pour restaurer la constance.",
        "Si ton travail exige d'être joignable, sanctuarise une seule heure par jour, pas la journée entière.",
        "Apprends de la brèche. Repars sur un objectif plus ciblé.",
        "L'échec est une donnée. On recalcule la trajectoire."
    ],
    "low_energy": [
        "Énergie basse aujourd'hui. On réduit la durée, pas la qualité de l'attention.",
        "La fatigue n'est pas un manque de volonté. Protège ton cerveau avec un bloc court.",
        "Mieux vaut 10 minutes d'attention pure que 40 minutes de lutte molle.",
        "Ton sommeil était court. Ne place pas ta tâche la plus difficile maintenant.",
        "Journée difficile ? Fais le minimum du protocole et dors plus tôt ce soir.",
        "Quand le carburant est bas, élimine toute friction superflue.",
        "Une session courte mais propre préserve la dynamique sans épuiser tes réserves.",
        "Ne compense pas la fatigue par du café tardif. Respecte le rythme biologique.",
        "Aujourd'hui, l'objectif est de maintenir le cadre, pas de battre un record.",
        "Un esprit fatigué est plus vulnérable aux impulsions. Double la distance avec le téléphone.",
        "Prends l'air cinq minutes avant de poser les mains sur le clavier.",
        "La récupération fait partie intégrante de l'entraînement de l'attention.",
        "Laisse les grands projets pour ta fenêtre de haute énergie. Fais l'essentiel.",
        "Accepte la baisse de régime sans te déconcentrer.",
        "Une pause sans écran restaure plus d'énergie que trente minutes de scroll passif.",
        "Ce soir, le sommeil est ta priorité absolue.",
        "Baisse la voilure, garde le cap.",
        "La constance dans les jours de basse énergie construit la vraie résilience."
    ],
    "progress": [
        "Tu tiens plus longtemps qu'au Jour 1. Ce n'est pas un hasard, c'est de l'entraînement.",
        "Ta capacité de maintien s'étend. Continue de consolider chaque palier.",
        "Moins de bruit, plus de clarté. Ton espace mental s'élargit.",
        "Le réflexe de vérification automatique commence à céder. Remarque la différence.",
        "Tes blocs de travail deviennent plus denses. Tu gagnes du temps de vie.",
        "Tu as franchi un cap d'endurance cognitive. Reste vigilant sur l'environnement.",
        "Le calme devient ton état par défaut pendant les sessions.",
        "Tu ne subis plus les notifications : tu choisis tes moments de connexion.",
        "Chaque semaine valide un niveau de contrôle supérieur.",
        "Ta capacité de restitution s'affine. Tu retiens l'architecture, pas seulement des bribes.",
        "La friction n'est plus une souffrance, c'est un repère familier.",
        "Ce que tu faisais avec effort au début devient une seconde nature.",
        "Tu as prouvé que l'attention se rééduque par la méthode.",
        "Le temps de focus s'allonge naturellement sans forcer.",
        "Continue sur cette lancée. La régularité est ton plus grand levier.",
        "Tu construis une forteresse que les algorithmes ne peuvent plus pénétrer facilement.",
        "Regarde le chemin parcouru depuis le calibrage initial.",
        "La maîtrise s'installe dans la répétition tranquille."
    ],
    "refusal": [
        "Tu as refusé l'intervention ? Pas de problème. On explore une autre voie.",
        "Une consigne qui ne fait pas sens pour toi ne sera jamais appliquée. On ajuste.",
        "Tu connais tes contraintes mieux que quiconque. Choisis ton propre compromis.",
        "Le refus est une décision légitime si elle s'accompagne d'une alternative.",
        "On ne force rien. L'important est de garder le contrôle de ton temps.",
        "Si cette méthode te semble artificielle, revenons aux fondamentaux de l'environnement.",
        "Pas d'injonction dogmatique dans REBOOT. Trouve ce qui fonctionne chez toi.",
        "On supprime cette règle de ton profil et on teste une approche différente.",
        "L'autonomie est le but ultime : tu es le seul juge de tes outils.",
        "Choisis la friction qui te paraît tolérable et durable.",
        "Un système respecté à 80% vaut mieux qu'un idéal théorique abandonné à 100%.",
        "Refuser le superflu fait aussi partie de l'entraînement.",
        "Adapte le protocole à ta réalité professionnelle et personnelle.",
        "On note ton retour et on réoriente les prochaines suggestions.",
        "Ta liberté de choix reste totale. Seul le résultat de focus compte.",
        "Cherche la simplicité plutôt que l'accumulation de contraintes.",
        "Ton retour permet d'affiner l'intelligence de ton parcours.",
        "On avance avec ce qui fait consensus pour toi."
    ],
    "overwhelm": [
        "Trop d'onglets, trop de tâches, trop de signaux. Respire et isole une seule unité.",
        "Le sentiment de submersion vient de la taille perçue de la tâche. Découpe-la.",
        "Tu ne peux pas tout faire aujourd'hui. Fais une seule chose remarquablement bien.",
        "Ferme tout sauf le document en cours. Le reste attendra la fin du bloc.",
        "Quand tout paraît urgent, rien n'est important. Choisis ton unique priorité.",
        "La panique cognitive se dissout dans l'action concrète sur un micro-détail.",
        "Écris les trois premières étapes sur papier. Ton cerveau retrouvera son calme.",
        "La clarté revient dès que tu réduis le champ de vision à la prochaine demi-heure.",
        "Baisse le niveau d'exigence sur la perfection, monte le niveau sur la présence.",
        "Une tâche de dix minutes suffit à relancer la dynamique.",
        "Ne regarde pas la montagne : regarde le prochain pas.",
        "L'encombrement mental se traite comme l'encombrement physique : on jette le bruit.",
        "Accorde-toi le droit de ne traiter qu'un seul problème à la fois.",
        "Ce bloc est sanctuarisé. Les urgences extérieures sont suspendues.",
        "Le soulagement vient de la fermeture des boucles ouvertes, une par une.",
        "Pose tout. Cinq minutes de marche. Puis une seule tâche propre.",
        "La simplicité est le remède absolu à la submersion.",
        "Reviens au sol. Un objet, un geste, un résultat."
    ],
    "boredom": [
        "L'ennui arrive ? C'est le signal que ton cerveau cherche sa dose facile. Reste.",
        "Traverse la zone d'ennui : c'est là que naît la pensée originale.",
        "Ne comble pas chaque seconde vide avec un stimulus passif.",
        "L'ennui n'est pas un vide à fuir, c'est un espace à habiter.",
        "La tolérance au calme est le prérequis de toute grande œuvre intellectuelle.",
        "Quand tu t'ennuies en session, monte légèrement la difficulté ou la précision exigée.",
        "Le réflexe de scroll est une tentative désespérée d'éviter le silence. Accueille le silence.",
        "Dans l'ennui prolongé, ton cerveau commence enfin à relier ses propres idées.",
        "Ce que tu ressens comme un manque est simplement une baisse de stimulation superficielle.",
        "Reste assis sans écran pendant deux minutes. Remarque comment l'esprit s'apaise.",
        "Les esprits les plus créatifs ont tous apprivoisé l'ennui.",
        "Ne fuis pas la lenteur. Les grandes idées ne poussent pas dans la précipitation.",
        "Chaque seconde passée dans le calme sans céder au réflexe renforce ton contrôle.",
        "L'ennui est la porte d'entrée du flow profond si tu ne fais pas demi-tour.",
        "Regarde par la fenêtre. Observe les formes sans chercher à consommer de l'information.",
        "Le vide sensoriel permet la consolidation mnésique. Laisse agir.",
        "Tu n'as pas besoin de nouveau contenu. Tu as besoin d'espace mental.",
        "L'esprit saturé ne crée rien. L'esprit reposé invente."
    ],
    "recall": [
        "Lis avec l'intention de reconstruire. Ton niveau d'attention s'en trouvera décuplé.",
        "Ferme le support avant d'écrire. C'est l'effort de rappel qui crée la mémoire durable.",
        "Ne te contente pas de mots-clés isolés : cherche la chaîne causale qui les relie.",
        "Si tu ne peux pas l'expliquer simplement, c'est que la structure n'est pas encore claire.",
        "La relecture passive donne une illusion de maîtrise. Seul le test réel compte.",
        "Ce qui a été difficile à récupérer en mémoire sera difficile à oublier.",
        "Recherche le contre-exemple ou la limite du concept : c'est là que se loge l'expertise.",
        "Résume le paragraphe en trois points cardinaux avant de tourner la page.",
        "La mémoire n'est pas un réservoir passif, c'est un réseau qu'on active par l'interrogation.",
        "Explique l'idée comme si ton interlocuteur n'avait aucune connaissance préalable.",
        "L'erreur de restitution est ton meilleur guide : elle montre exactement où travailler.",
        "Structure ton résumé : Thèse d'abord, Mécanisme ensuite, Conséquence enfin.",
        "Ne consulte pas la réponse trop vite. Laisse ton cerveau chercher pendant trente secondes.",
        "L'effet de génération : formuler toi-même la réponse ancre le souvenir 3× plus fort.",
        "Relie ce que tu viens de lire à une expérience vécue ou un projet en cours.",
        "La précision du vocabulaire reflète la netteté du modèle mental.",
        "Un bon résumé est plus court et plus dense que le texte original.",
        "Tu apprends pour agir, pas pour empiler des phrases."
    ],
    "strong_result": [
        "Excellente session. Le maintien était net et sans résidu attentionnel.",
        "Zéro switch sur un bloc exigeant : c'est le standard de haute performance.",
        "Ta capacité de restitution a atteint un niveau de précision remarquable.",
        "Tu as tenu ton contrat d'environnement de bout en bout. Félicitations.",
        "Ce niveau de clarté mentale est le résultat direct de ta méthode.",
        "Session propre. Note les conditions exactes qui ont permis cette réussite.",
        "Tu as transformé une friction potentielle en un flux de travail continu.",
        "C'est exactement ce type de bloc qui fait avancer les projets décisifs.",
        "Ton focus a été constant du début à la fin de la fenêtre.",
        "La qualité de ton travail s'en ressent immédiatement.",
        "Conserve ce sentiment de maîtrise pour aborder le prochain bloc.",
        "Tu as prouvé que les conditions adéquates produisent des résultats spectaculaires.",
        "La discipline appliquée produit de la liberté intellectuelle.",
        "Un bloc de cette qualité vaut quatre heures de travail fragmenté.",
        "Prends le temps d'apprécier la sensation d'un travail véritablement achevé.",
        "Le standard monte. Tu sais désormais ce dont tu es capable.",
        "Bravo pour cette démonstration de contrôle de bout en bout.",
        "Ton attention est devenue une arme de précision."
    ],
    "missed_day": [
        "Tu as manqué un jour ? Le programme n'a pas avancé sans toi. Reprends au Jour exact.",
        "Tu n'as rien cassé. Pas de punition, pas de double session. Reviens dans le rythme.",
        "Le protocole est un chemin, pas une chaîne fragile. On reprend là où tu t'es arrêté.",
        "La constance sur 90 jours tolère des imprévus. Ce qui compte, c'est de ne pas laisser le vide s'installer.",
        "Pas de culpabilité inutile. Pose les mains sur le Jour d'aujourd'hui et fais ta session.",
        "Une absence n'annule pas les acquis des semaines précédentes. Rebranche la machine.",
        "Le temps perdu n'existe pas si tu tires les leçons du décrochage.",
        "Reviens avec simplicité. Un seul bloc aujourd'hui suffit pour relancer le moteur.",
        "Ne cherche pas à rattraper en force : fais la session du jour avec une attention totale.",
        "Ton espace REBOOT est intact. Bienvenue de retour.",
        "La vie a créé une friction. Tu as su revenir : c'est cela la vraie compétence.",
        "Un jour off ne détruit pas une habitude si le retour se fait sans délai.",
        "Reprends ton rituel d'entrée : bureau propre, téléphone loin, intention posée.",
        "L'important n'est pas de ne jamais tomber, mais de toujours remonter sur le vélo.",
        "On efface le bruit d'hier. On joue la partition d'aujourd'hui.",
        "Reviens au calme. Ta séance du jour t'attend.",
        "La constance se mesure sur le long terme, pas sur la perfection d'un calendrier.",
        "Bienvenue. On reprend la marche en avant."
    ],
    "experiment": [
        "L'expérience est en cours. Ne change aucun autre paramètre pour garder la mesure propre.",
        "Observe les faits sans juger. Est-ce que le premier switch arrive plus tard ?",
        "Une expérience qui infirme une hypothèse est tout aussi utile qu'un succès.",
        "Note fidèlement tes ressentis après la session : les données guident la règle.",
        "On teste pour savoir, pas pour se conformer à une injonction de productivité.",
        "Si l'effet n'est pas mesurable après trois sessions, on abandonne l'expérience sans regret.",
        "Garde la rigueur du protocole : même contexte, même tâche, seule la condition varie.",
        "Les chiffres ne mentent pas : compare la latence moyenne avec et sans la contrainte.",
        "Tu es ton propre laboratoire attentionnel. Reste curieux et objectif.",
        "L'expérimentation méthodique remplace les croyances vagues par des certitudes opérationnelles.",
        "Une bonne hypothèse doit pouvoir être testée en trois blocs de travail.",
        "Ne conclus rien sur une seule session atypique : attends le volume requis.",
        "La science de ton attention se construit session après session.",
        "Reste neutre face aux résultats : on cherche l'efficacité réelle, pas l'élégance théorique.",
        "Cette expérience affine la compréhension de tes déclencheurs profonds.",
        "La mesure objective bat l'intuition subjective.",
        "Note le résultat dans ton carnet de bord et passe à l'analyse.",
        "Tu es en train de concevoir ton propre manuel d'utilisation."
    ],
    "flow": [
        "Le flow demande une ligne d'arrivée nette. Si tu ne sais pas où tu t'arrêtes, clarifie.",
        "Ajuste le niveau : un peu plus dur que ton habitude, mais jamais insurmontable.",
        "Installe ton retour visuel immédiat : compteur de mots, code qui compile, page qui noircit.",
        "Ne négocie aucune interruption pendant cette fenêtre de flow. Porte fermée.",
        "La tâche doit avoir un sens pour toi. Rappelle-toi pourquoi ce travail compte.",
        "Le flow s'installe quand l'action et la conscience fusionnent sur l'objet.",
        "Pas de téléphone visible, pas d'onglet tiers, pas de musique à paroles. Que l'essentiel.",
        "Découpe le gros bloc en micro-unités de quinze minutes pour entretenir l'élan.",
        "Quand tu perds la notion du temps, tu as touché la zone. Remarque ce qui l'a permis.",
        "Le flow n'est pas magique : c'est la conséquence naturelle de conditions bien réglées.",
        "Si la fatigue arrive, termine proprement l'unité en cours et sors du bloc.",
        "Ne cherche pas le flow avec anxiété : prépare les conditions et laisse l'attention plonger.",
        "Un défi bien calibré absorbe l'esprit sans laisser de place aux pensées parasites.",
        "Observe comment le plaisir émerge de la maîtrise d'une difficulté surmontée.",
        "Garde ton contrat de distraction intact jusqu'à la sonnerie finale.",
        "Le flow est le mode de fonctionnement le plus économique pour le cerveau.",
        "Clôture la session en notant la première action de demain pour faciliter le prochain amorçage.",
        "Tu as goûté à la profondeur. C'est ton nouveau standard de travail."
    ]
}

for cat, msgs in raw_coaching.items():
    for text in msgs:
        coaching_messages.append({
            "id": msg_id,
            "category": cat,
            "text": text,
            "contextCondition": f"condition_{cat}"
        })
        msg_id += 1

# 4. 80 VOID PROMPTS (Contextual, Levels 1 to 8)
void_prompts = []
void_contexts = [
    ("Avant de déverrouiller le téléphone", 1, "Reste 30 secondes sans toucher l'écran."),
    ("Attente du café ou du thé", 2, "Observe la vapeur monter sans sortir ton appareil."),
    ("File d'attente ou ascenseur", 2, "Garde les mains dans les poches et regarde autour de toi."),
    ("Trajet en transport en commun", 5, "Regarde le paysage défiler sans écouteurs ni écran."),
    ("Transition entre deux tâches", 3, "Ferme les yeux et laisse décanter le travail précédent."),
    ("Début de repas", 3, "Mange les premières bouchées en silence complet sans média."),
    ("Marche extérieure courte", 10, "Marche à rythme régulier en écoutant les bruits réels."),
    ("Pause de mi-journée", 15, "Assieds-toi confortablement sans aucune entrée sensorielle artificielle."),
    ("Fin de journée de travail", 10, "Marque la coupure en restant assis dans le calme avant d'allumer quoi que ce soit."),
    ("Avant de dormir", 15, "Reste dans l'obscurité sans écran pour laisser le cerveau basculer.")
]

v_id = 1
for level in range(1, 9):
    for i, (ctx, base_min, desc) in enumerate(void_contexts):
        duration = min(30, max(1, int(base_min * (1 + level * 0.25))))
        void_prompts.append({
            "id": v_id,
            "title": f"VIDE NIVEAU {level:02d} — {ctx.upper()}",
            "prompt": f"{desc} Durée cible : {duration} minute{'s' if duration > 1 else ''}. Pas de nouveau stimulus, pas de texte, pas de musique.",
            "durationMinutes": duration,
            "context": ctx
        })
        v_id += 1
        if v_id > 80:
            break
    if v_id > 80:
        break

# Save all 4 files
with open(os.path.join(CONTENT, "micro_insights.json"), "w", encoding="utf-8") as f:
    json.dump(micro_insights, f, ensure_ascii=False, indent=2)
print(f"Generated micro_insights.json ({len(micro_insights)} items)")

with open(os.path.join(CONTENT, "checkpoints.json"), "w", encoding="utf-8") as f:
    json.dump(checkpoints, f, ensure_ascii=False, indent=2)
print(f"Generated checkpoints.json ({len(checkpoints)} items)")

with open(os.path.join(CONTENT, "coaching_messages.json"), "w", encoding="utf-8") as f:
    json.dump(coaching_messages, f, ensure_ascii=False, indent=2)
print(f"Generated coaching_messages.json ({len(coaching_messages)} items)")

with open(os.path.join(CONTENT, "void_prompts.json"), "w", encoding="utf-8") as f:
    json.dump(void_prompts, f, ensure_ascii=False, indent=2)
print(f"Generated void_prompts.json ({len(void_prompts)} items)")
