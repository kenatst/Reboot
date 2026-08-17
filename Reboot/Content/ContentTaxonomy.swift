import Foundation

/// REBOOT V3 — Core Content Taxonomy & Skill Classification
enum ContentTaxonomy {
    enum Domain: String, CaseIterable, Codable, Identifiable {
        case attentionControl = "ATTENTION_CONTROL"
        case digitalReflex = "DIGITAL_REFLEX"
        case sustainedFocus = "SUSTAINED_FOCUS"
        case returnSkill = "RETURN"
        case deepWork = "DEEP_WORK"
        case reading = "READING"
        case recall = "RECALL"
        case learning = "LEARNING"
        case flowConditions = "FLOW_CONDITIONS"
        case environment = "ENVIRONMENT"
        case boredomTolerance = "BOREDOM_TOLERANCE"
        case energy = "ENERGY"
        case recovery = "RECOVERY"
        case selfRegulation = "SELF_REGULATION"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .attentionControl: return "Contrôle de l'Attention"
            case .digitalReflex: return "Réflexe Numérique"
            case .sustainedFocus: return "Attention Soutenue"
            case .returnSkill: return "Retour après Distraction"
            case .deepWork: return "Travail en Profondeur"
            case .reading: return "Lecture Active"
            case .recall: return "Restitution & Mémoire"
            case .learning: return "Modèles d'Apprentissage"
            case .flowConditions: return "Conditions de Flow"
            case .environment: return "Design d'Environnement"
            case .boredomTolerance: return "Tolérance au Calme"
            case .energy: return "Gestion de l'Énergie"
            case .recovery: return "Récupération & Pause"
            case .selfRegulation: return "Auto-Régulation"
            }
        }
    }

    struct SubSkill: Codable, Hashable, Identifiable {
        let id: String
        let domain: Domain
        let name: String
        let description: String
    }

    static let allSubSkills: [SubSkill] = [
        // ATTENTION CONTROL
        SubSkill(id: "att_starting", domain: .attentionControl, name: "Amorçage", description: "Capacité à entrer dans une tâche sans friction excessive."),
        SubSkill(id: "att_staying", domain: .attentionControl, name: "Maintien", description: "Capacité à rester sur un seul objet attentionnel sans bascule."),
        SubSkill(id: "att_noticing", domain: .attentionControl, name: "Détection d'Urge", description: "Repérage immédiat de l'impulsion avant l'acte de décrochage."),
        SubSkill(id: "att_intentional_switch", domain: .attentionControl, name: "Bascule Intentionnelle", description: "Changement de tâche planifié et propre."),
        SubSkill(id: "att_returning", domain: .attentionControl, name: "Ré-engagement", description: "Retour immédiat sur la tâche après interruption."),

        // DIGITAL REFLEX
        SubSkill(id: "dig_checking_impulse", domain: .digitalReflex, name: "Impulsion de Vérification", description: "Contrôle du geste automatique vers l'écran."),
        SubSkill(id: "dig_feed_reflex", domain: .digitalReflex, name: "Réflexe de Flux", description: "Résistance au scroll infini et à la stimulation passive."),
        SubSkill(id: "dig_notification_response", domain: .digitalReflex, name: "Réponse aux Notifications", description: "Gestion des signaux entrants sans interruption."),
        SubSkill(id: "dig_idle_checking", domain: .digitalReflex, name: "Vérification dans les Temps Morts", description: "Maintien du calme pendant les micro-attentes."),
        SubSkill(id: "dig_morning_feed", domain: .digitalReflex, name: "Téléphone au Réveil", description: "Protection de la première heure sans sollicitation numérique."),
        SubSkill(id: "dig_bedtime_feed", domain: .digitalReflex, name: "Téléphone au Lit", description: "Sanctuarisation de l'espace de sommeil."),

        // DEEP WORK
        SubSkill(id: "dw_clear_objective", domain: .deepWork, name: "Objectif Unitaire", description: "Définition précise de l'action en cours."),
        SubSkill(id: "dw_task_decomposition", domain: .deepWork, name: "Décomposition", description: "Division du travail en unités finies et mesurables."),
        SubSkill(id: "dw_interruption_protection", domain: .deepWork, name: "Isolation", description: "Protection physique et numérique du bloc de travail."),
        SubSkill(id: "dw_duration_capacity", domain: .deepWork, name: "Capacité de Durée", description: "Allongement progressif de la fenêtre de focus."),
        SubSkill(id: "dw_cognitive_difficulty", domain: .deepWork, name: "Résistance Cognitive", description: "Tolérance à l'effort mental difficile."),
        SubSkill(id: "dw_finish_line", domain: .deepWork, name: "Ligne d'Arrivée", description: "Clôture nette de la session avec critères atteints."),

        // RECALL & READING
        SubSkill(id: "rec_thesis", domain: .recall, name: "Thèse Principale", description: "Identification de l'argument central."),
        SubSkill(id: "rec_structure", domain: .recall, name: "Architecture d'Idées", description: "Cartographie des grandes étapes du raisonnement."),
        SubSkill(id: "rec_causal_chains", domain: .recall, name: "Mécanismes Causaux", description: "Explication de comment A produit B."),
        SubSkill(id: "rec_examples", domain: .recall, name: "Génération d'Exemples", description: "Illustration concrète du concept."),
        SubSkill(id: "rec_counterarguments", domain: .recall, name: "Limites & Objections", description: "Repérage des failles et contre-exemples."),
        SubSkill(id: "rec_transfer", domain: .recall, name: "Transfert Pratique", description: "Application d'un modèle mental à un autre domaine."),

        // FLOW CONDITIONS
        SubSkill(id: "fl_clear_goals", domain: .flowConditions, name: "Objectif Immédiat", description: "Savoir exactement quoi faire dans les 5 prochaines minutes."),
        SubSkill(id: "fl_challenge_skill", domain: .flowConditions, name: "Ajustement Défi × Compétence", description: "Équilibre entre ennui et submersion."),
        SubSkill(id: "fl_immediate_feedback", domain: .flowConditions, name: "Feedback Court", description: "Boucle de résultat rapide sur l'action."),
        SubSkill(id: "fl_progress_visibility", domain: .flowConditions, name: "Progression Visible", description: "Constat clair de l'avancement."),
        SubSkill(id: "fl_absorption_transfer", domain: .flowConditions, name: "Transfert d'Absorption", description: "Importation des conditions de jeu/sport dans le travail."),

        // ENVIRONMENT & BOREDOM
        SubSkill(id: "env_phone_distance", domain: .environment, name: "Distance Physique", description: "Téléphone hors du champ de vision et d'atteinte."),
        SubSkill(id: "env_workspace_clarity", domain: .environment, name: "Espace de Travail", description: "Élimination des stimuli concurrents."),
        SubSkill(id: "env_tab_discipline", domain: .environment, name: "Discipline d'Onglets", description: "Travail sur un seul document ou flux."),
        SubSkill(id: "bor_waiting_tolerance", domain: .boredomTolerance, name: "Attente sans Écran", description: "Tolérance au vide sensoriel."),
        SubSkill(id: "bor_sensory_reset", domain: .boredomTolerance, name: "Pause Sans Entrée", description: "Repos cognitif complet sans média."),

        // ENERGY & RECOVERY
        SubSkill(id: "eng_sleep_protection", domain: .energy, name: "Hygiène de Sommeil", description: "Régularité et protection des nuits."),
        SubSkill(id: "eng_caffeine_timing", domain: .energy, name: "Timing Caféine", description: "Consommation stratégique sans perturbation du repos."),
        SubSkill(id: "eng_movement_breaks", domain: .recovery, name: "Mouvement & Posture", description: "Pauses physiques réelles entre les blocs."),
        SubSkill(id: "eng_meal_context", domain: .energy, name: "Contexte Digestif", description: "Alignement des repas lourds hors des blocs critiques.")
    ]

    static func subSkill(id: String) -> SubSkill? {
        allSubSkills.first { $0.id == id }
    }
}
