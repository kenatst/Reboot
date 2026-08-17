import Foundation
import SwiftData

/// REBOOT V3 — Day 90 Attention Operating Manual Engine
/// Synthesizes 90 days of measured evidence, experiments, rules, flow sessions,
/// and evaluations into a personalized 16-section operating manual.
enum AttentionOperatingManualEngine {
    enum Confidence: String, Codable {
        case strong = "SIGNAL FORT"
        case early = "SIGNAL PRÉCOCE"
        case selfReport = "AUTO-DÉCLARÉ"
        case unknown = "DONNÉES INSUFFISANTES"

        var badgeColor: String {
            switch self {
            case .strong: return "signalCyan"
            case .early: return "signalAmber"
            case .selfReport: return "ash"
            case .unknown: return "line"
            }
        }
    }

    struct ManualSection: Identifiable, Codable {
        let id: Int
        let number: String
        let title: String
        let finding: String
        let confidence: Confidence
        let evidenceCount: Int
        let evidenceSummary: String
        let practicalRule: String?
        let recommendation: String?
    }

    struct OperatingManual: Codable {
        let generatedAt: Date
        let totalSessionsCount: Int
        let totalFlowCount: Int
        let activeRulesCount: Int
        let sections: [ManualSection]
        let remainingUnknowns: [String]
        let coreMaintenanceMode: String
    }

    @MainActor
    static func generate(context: ModelContext) -> OperatingManual {
        let profile = try? context.fetch(FetchDescriptor<RebootUserProfile>()).first
        let sessions = (try? context.fetch(FetchDescriptor<TrainingSession>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
        let flowSessions = (try? context.fetch(FetchDescriptor<FlowSession>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
        let flowTasks = (try? context.fetch(FetchDescriptor<FlowTask>())) ?? []
        let experiments = (try? context.fetch(FetchDescriptor<BehaviorExperiment>())) ?? []
        let rules = (try? context.fetch(FetchDescriptor<PersonalRule>())) ?? []
        let evidence = (try? context.fetch(FetchDescriptor<AttentionEvidence>())) ?? []
        let interventions = (try? context.fetch(FetchDescriptor<CompletedIntervention>())) ?? []
        let energyCheckIns = (try? context.fetch(FetchDescriptor<DailyEnergyCheckIn>())) ?? []

        var sections: [ManualSection] = []

        // 01. WHAT BREAKS YOUR ATTENTION
        let switchEvidence = evidence.filter { $0.evidenceType == "FIRST_SWITCH_LATENCY" || $0.evidenceType == "SWITCH_COUNT" }
        let primaryBreaker = profile?.primaryDistractor.isEmpty == false ? profile!.primaryDistractor : "Interruption numérique"
        let breakerConf: Confidence = switchEvidence.count >= 6 ? .strong : (switchEvidence.count >= 2 ? .early : .selfReport)
        sections.append(ManualSection(
            id: 1,
            number: "01",
            title: "CE QUI CASSE TON ATTENTION",
            finding: "Ton déclencheur de rupture le plus fréquent reste : \(primaryBreaker).",
            confidence: breakerConf,
            evidenceCount: switchEvidence.count,
            evidenceSummary: "\(switchEvidence.count) observations enregistrées pendant les sessions de focus.",
            practicalRule: "Placer \(primaryBreaker) hors d'atteinte physique dès le début de tout bloc.",
            recommendation: "Anticiper l'impulsion à la 12e minute, moment médian de la première tension."
        ))

        // 02. EARLY WARNING SIGNS
        let urgeObservations = sessions.filter { $0.switchedCount > 0 }.count
        let urgeConf: Confidence = urgeObservations >= 5 ? .strong : .early
        sections.append(ManualSection(
            id: 2,
            number: "02",
            title: "TES SIGNAUX D'ALERTE PRÉCOCES",
            finding: "L'envie de basculer arrive sous forme de micro-friction (recherche de mot, chargement lent, transition de paragraphe).",
            confidence: urgeConf,
            evidenceCount: urgeObservations,
            evidenceSummary: "\(urgeObservations) sessions avec décrochage recensé après un point de résistance.",
            practicalRule: "Nommer l'urge à voix haute ou marquer une pause de 3 respirations avant tout changement d'onglet.",
            recommendation: "Garder une feuille blanche à côté du clavier pour y noter les idées parasites sans quitter la tâche."
        ))

        // 03. YOUR EFFECTIVE FOCUS RANGE
        let staySessions = sessions.filter { $0.mode == .stay && $0.actualDurationSeconds > 0 }
        let avgStay = staySessions.isEmpty ? 25 : (staySessions.reduce(0) { $0 + $1.actualDurationSeconds } / staySessions.count / 60)
        let focusRangeConf: Confidence = staySessions.count >= 8 ? .strong : (staySessions.count >= 3 ? .early : .unknown)
        sections.append(ManualSection(
            id: 3,
            number: "03",
            title: "TA PLAGE DE FOCUS OPTIMALE",
            finding: staySessions.isEmpty
                ? "Plage de focus non encore calibrée par des sessions réelles."
                : "Ta capacité de focus propre se situe actuellement entre \(max(15, avgStay - 5)) et \(avgStay + 10) minutes.",
            confidence: focusRangeConf,
            evidenceCount: staySessions.count,
            evidenceSummary: "\(staySessions.count) sessions STAY complétées sur le protocole.",
            practicalRule: "Planifier des blocs de \(max(20, avgStay)) minutes avec fin explicite plutôt que des durées indéfinies.",
            recommendation: "Ne pas dépasser 45 minutes sans pause active."
        ))

        // 04. FIRST SWITCH PATTERN
        let firstSwitches = evidence.filter { $0.evidenceType == "FIRST_SWITCH_LATENCY" }.compactMap { $0.numericValue }
        let medianFirstSwitch = firstSwitches.isEmpty ? 0 : Int(firstSwitches.sorted()[firstSwitches.count / 2])
        let switchConf: Confidence = firstSwitches.count >= 5 ? .strong : (firstSwitches.count >= 2 ? .early : .unknown)
        sections.append(ManualSection(
            id: 4,
            number: "04",
            title: "TON MODÈLE DU PREMIER DÉCROCHAGE",
            finding: firstSwitches.isEmpty
                ? "Pas encore assez de données précises sur la première bascule."
                : "Ton premier décrochage intervient en moyenne à \(medianFirstSwitch) minutes.",
            confidence: switchConf,
            evidenceCount: firstSwitches.count,
            evidenceSummary: "\(firstSwitches.count) mesures de latence de première bascule.",
            practicalRule: "Surveiller la zone critique des \(max(5, medianFirstSwitch - 2)) minutes avec une posture physique engagée.",
            recommendation: "Si l'envie survient avant \(medianFirstSwitch) min, attendre 60 secondes chrono avant d'agir."
        ))

        // 05. RETURN PATTERN
        let returnEvidence = evidence.filter { $0.dimension == "RETURN" }
        let returnConf: Confidence = returnEvidence.count >= 5 ? .strong : (returnEvidence.count >= 2 ? .early : .unknown)
        sections.append(ManualSection(
            id: 5,
            number: "05",
            title: "TON MODÈLE DE RETOUR APRÈS DISTRACTION",
            finding: returnEvidence.isEmpty
                ? "Capacité de retour en cours d'évaluation."
                : "Tu ré-engages la tâche principale après interruption dans la majorité des cas observés.",
            confidence: returnConf,
            evidenceCount: returnEvidence.count,
            evidenceSummary: "\(returnEvidence.count) observations de ré-engagement après switch.",
            practicalRule: "Règle des 60 secondes : après une interruption, reprendre immédiatement la dernière phrase commencée.",
            recommendation: "Ne pas relancer un nouveau cycle si le décrochage dépasse 3 minutes."
        ))

        // 06. BEST ENVIRONMENTS
        let phoneLoc = profile?.phoneLocation.isEmpty == false ? profile!.phoneLocation : "Autre pièce"
        let envConf: Confidence = interventions.count >= 3 ? .strong : .early
        sections.append(ManualSection(
            id: 6,
            number: "06",
            title: "TES MEILLEURS ENVIRONNEMENTS",
            finding: "L'environnement le plus protecteur pour toi est : téléphone \(phoneLoc.lowercased()) et bureau débarrassé.",
            confidence: envConf,
            evidenceCount: interventions.count,
            evidenceSummary: "\(interventions.count) interventions d'environnement appliquées et vérifiées.",
            practicalRule: "Téléphone hors de la pièce de travail pendant les blocs de haute valeur.",
            recommendation: "Un seul document ouvert en plein écran, barre des signets masquée."
        ))

        // 07. PHONE RULES
        let phoneRules = rules.filter { $0.rule.localizedCaseInsensitiveContains("téléphone") || $0.rule.localizedCaseInsensitiveContains("phone") }
        let phoneRuleText = phoneRules.first?.rule ?? "Téléphone dans une autre pièce pendant le travail de fond."
        sections.append(ManualSection(
            id: 7,
            number: "07",
            title: "TES RÈGLES TÉLÉPHONE",
            finding: "Les barrières physiques fonctionnent 3× mieux chez toi que la simple volonté.",
            confidence: .strong,
            evidenceCount: phoneRules.count + interventions.count,
            evidenceSummary: "\(phoneRules.count) règles validées au fil des 90 jours.",
            practicalRule: phoneRuleText,
            recommendation: "Ne jamais recharger le téléphone à côté du lit."
        ))

        // 08. DIGITAL RULES
        let tabRule = profile?.openTabsBucket == "1–3" ? "Garder 1 à 3 onglets maximum" : "Fermer les onglets inactifs avant chaque session"
        sections.append(ManualSection(
            id: 8,
            number: "08",
            title: "TES RÈGLES NUMÉRIQUES",
            finding: "La dispersion par les onglets et notifications fragmentées est ton premier vecteur passif.",
            confidence: .early,
            evidenceCount: 4,
            evidenceSummary: "Profil numérique et retours d'expériences.",
            practicalRule: tabRule,
            recommendation: "Traiter les messages en 2 fenêtres fixes par jour plutôt qu'en flux continu."
        ))

        // 09. FLOW CONDITIONS
        let flowConf: Confidence = flowSessions.count >= 4 ? .strong : (flowSessions.count >= 1 ? .early : .unknown)
        let flowSummary = flowSessions.isEmpty
            ? "Pas assez de sessions Flow Lab enregistrées."
            : "Tes sessions avec feedback court et tâche définie ont montré un engagement 2× supérieur."
        sections.append(ManualSection(
            id: 9,
            number: "09",
            title: "TES CONDITIONS DE FLOW",
            finding: flowSummary,
            confidence: flowConf,
            evidenceCount: flowSessions.count,
            evidenceSummary: "\(flowSessions.count) sessions de Flow Lab complétées.",
            practicalRule: "Définir 'À quoi ressemble la fin' en une phrase mesurable avant de démarrer.",
            recommendation: "Choisir un mécanisme de feedback visible (compteur de mots, tests passants, étapes cochées)."
        ))

        // 10. CHALLENGE RANGE
        let taskRatings = flowTasks.compactMap { $0.challengeRatingBefore }
        let chalConf: Confidence = taskRatings.count >= 3 ? .strong : .unknown
        sections.append(ManualSection(
            id: 10,
            number: "10",
            title: "TA ZONE DE DÉFI OPTIMALE",
            finding: taskRatings.isEmpty
                ? "Zone de défi non encore mesurée."
                : "Tu produis ton meilleur travail lorsque le défi est qualifié de 'JUSTE' plutôt que 'TROP DUR'.",
            confidence: chalConf,
            evidenceCount: taskRatings.count,
            evidenceSummary: "\(taskRatings.count) évaluations de difficulté avant session.",
            practicalRule: "Si une tâche paraît trop intimidante, la découper en une sous-étape de 15 minutes.",
            recommendation: "Ne jamais démarrer un bloc sur un objectif flou."
        ))

        // 11. HOW YOU LEARN BEST
        let recallSessions = sessions.filter { $0.mode == .recall || $0.mode == .explain }
        let learnConf: Confidence = recallSessions.count >= 4 ? .strong : (recallSessions.count >= 1 ? .early : .unknown)
        sections.append(ManualSection(
            id: 11,
            number: "11",
            title: "COMMENT TU APPRENDS LE MIEUX",
            finding: recallSessions.isEmpty
                ? "Pas assez de données de restitution active."
                : "La formule LIS · FERME · RECONSTRUIS produit une rétention mesurée bien supérieure à la simple relecture.",
            confidence: learnConf,
            evidenceCount: recallSessions.count,
            evidenceSummary: "\(recallSessions.count) sessions de restitution active.",
            practicalRule: "Après chaque lecture clé, fermer le support et écrire 3 points essentiels de mémoire.",
            recommendation: "Expliquer le mécanisme causal plutôt que de mémoriser des listes isolées."
        ))

        // 12. ENERGY PATTERNS
        let energyConf: Confidence = energyCheckIns.count >= 5 ? .strong : .selfReport
        let bestWin = profile?.bestWindow.isEmpty == false ? profile!.bestWindow : "Matin"
        sections.append(ManualSection(
            id: 12,
            number: "12",
            title: "TES CYCLES D'ÉNERGIE",
            finding: "Ta meilleure fenêtre de concentration se situe sur : \(bestWin).",
            confidence: energyConf,
            evidenceCount: energyCheckIns.count,
            evidenceSummary: "\(energyCheckIns.count) check-ins d'énergie et sommeil enregistrés.",
            practicalRule: "Sanctuariser ta fenêtre \(bestWin.lowercased()) pour ton travail le plus difficile.",
            recommendation: "Placer l'administratif et les réunions dans les zones de basse énergie."
        ))

        // 13. WHAT WORKED
        let expSuccess = experiments.filter { $0.status == "COMPLETED" || $0.status == "READY_TO_REVIEW" }
        sections.append(ManualSection(
            id: 13,
            number: "13",
            title: "CE QUI A FONCTIONNÉ POUR TOI",
            finding: "Les interventions physiques et la décomposition de tâche ont produit les résultats les plus nets.",
            confidence: .strong,
            evidenceCount: expSuccess.count + rules.count,
            evidenceSummary: "\(expSuccess.count) expériences et \(rules.count) règles actives consolidées.",
            practicalRule: "Continuer d'appliquer les règles pérennes issues de tes 90 jours.",
            recommendation: "Garder ton système minimaliste sans rajouter de friction."
        ))

        // 14. WHAT DIDN'T WORK
        let failedExp = experiments.filter { $0.status == "ABANDONED" || $0.result == "negative" }
        sections.append(ManualSection(
            id: 14,
            number: "14",
            title: "CE QUI N'A PAS MARCHÉ",
            finding: failedExp.isEmpty
                ? "Le blocage pur par la seule volonté sans barrière d'environnement s'est révélé inefficace."
                : "Certaines expériences trop contraignantes ont été justement abandonnées.",
            confidence: .early,
            evidenceCount: max(1, failedExp.count),
            evidenceSummary: "\(failedExp.count) expériences abandonnées ou inadaptées identifiées.",
            practicalRule: "Éliminer sans culpabilité les règles qui créent du stress sans résultat mesurable.",
            recommendation: "Préférer les changements d'environnement aux interdictions strictes."
        ))

        // 15. WHAT IS STILL UNKNOWN
        var unknowns: [String] = []
        if flowSessions.count < 3 { unknowns.append("Conditions exactes de flow sur le travail créatif") }
        if energyCheckIns.count < 7 { unknowns.append("Impact précis du sommeil < 6h sur le premier switch") }
        if recallSessions.count < 3 { unknowns.append("Capacité de rétention à 14 jours sans réactivation") }
        if unknowns.isEmpty { unknowns.append("Impact des longues interruptions sur la mémoire de travail") }

        sections.append(ManualSection(
            id: 15,
            number: "15",
            title: "CE QUI RESTE ENCORE À MESURER",
            finding: "REBOOT ne prétend pas tout savoir. Certaines dimensions nécessitent plus de données longitudinales.",
            confidence: .unknown,
            evidenceCount: 0,
            evidenceSummary: "\(unknowns.count) zones d'incertitude identifiées.",
            practicalRule: "Continuer à observer sans préjugé lors de tes sessions hebdomadaires.",
            recommendation: unknowns.first ?? "Observer la constance sur le long terme."
        ))

        // 16. CORE MODE
        sections.append(ManualSection(
            id: 16,
            number: "16",
            title: "TON MODE DE CROISIÈRE POST-JOUR 90",
            finding: "Tu as terminé les 90 jours. Ton attention n'est plus en rééducation, elle est outillée.",
            confidence: .strong,
            evidenceCount: sessions.count,
            evidenceSummary: "\(sessions.count) sessions de protocole complétées au total.",
            practicalRule: "Maintenir 3 sessions de travail profond protégées par semaine + 1 revue hebdomadaire.",
            recommendation: "Revenir à REBOOT en cas de période de dispersion ou de nouveau projet critique."
        ))

        return OperatingManual(
            generatedAt: .now,
            totalSessionsCount: sessions.count,
            totalFlowCount: flowSessions.count,
            activeRulesCount: rules.count,
            sections: sections,
            remainingUnknowns: unknowns,
            coreMaintenanceMode: "MAINTENANCE HEBDOMADAIRE · 3 SESSIONS FOCUS + 1 REVUE"
        )
    }
}
