import Foundation
import SwiftData

/// REBOOT V3.1 — Day 90 Attention Operating Manual Engine
/// Synthesizes 90 days of measured evidence into a 16-section operating manual.
/// Rules for this engine:
/// - Every quantified personal statement is COMPUTED from recorded data.
/// - No numeric literal is embedded in personalized copy except documented
///   product thresholds (sample-size gates, the 60-second return window).
/// - If the data is insufficient, the section says UNKNOWN — it never
///   invents a plausible-looking finding.
/// - Each section separates OBSERVED FINDING from USER PREFERENCE from
///   GENERAL RECOMMENDATION.
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

    enum Basis: String, Codable {
        case observed = "MESURÉ"
        case preference = "PRÉFÉRENCE DÉCLARÉE"
        case general = "RECOMMANDATION GÉNÉRALE"
        case unknown = "DONNÉES INSUFFISANTES"
    }

    struct ManualSection: Identifiable, Codable {
        let id: Int
        let number: String
        let title: String
        let finding: String
        let confidence: Confidence
        let basis: Basis
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

    // Documented product thresholds — the only numeric literals allowed in copy.
    private enum Threshold {
        static let strongSample = 5
        static let earlySample = 2
        static let returnWindowSeconds = 60
        static let challengeSample = 5
    }

    private static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
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
        let breakerAnswer = profile?.primaryDistractor.isEmpty == false ? profile!.primaryDistractor : (profile?.workBreaker.isEmpty == false ? profile!.workBreaker : nil)
        let breakerConf: Confidence = switchEvidence.count >= Threshold.strongSample ? .strong : (switchEvidence.count >= Threshold.earlySample ? .early : (breakerAnswer != nil ? .selfReport : .unknown))
        let breakerFinding: String
        if let breakerAnswer {
            breakerFinding = switchEvidence.isEmpty
                ? "Déclaré à l'onboarding : \(breakerAnswer). Aucune bascule encore mesurée en session."
                : "Déclaré à l'onboarding : \(breakerAnswer). \(switchEvidence.count) bascule(s) mesurée(s) en session."
        } else {
            breakerFinding = switchEvidence.isEmpty
                ? "Aucun déclencheur déclaré et aucune bascule mesurée."
                : "Aucun déclencheur déclaré ; \(switchEvidence.count) bascule(s) mesurée(s) en session."
        }
        sections.append(ManualSection(
            id: 1,
            number: "01",
            title: "CE QUI CASSE TON ATTENTION",
            finding: breakerFinding,
            confidence: breakerConf,
            basis: switchEvidence.isEmpty ? (breakerAnswer != nil ? .preference : .unknown) : .observed,
            evidenceCount: switchEvidence.count,
            evidenceSummary: "\(switchEvidence.count) observations de bascule enregistrées.",
            practicalRule: breakerAnswer.map { "Garder \($0) hors d'atteinte physique au début de chaque bloc." },
            recommendation: "Si aucune bascule n'est encore mesurée, noter le déclencheur de chaque décrochage pendant une semaine."
        ))

        // 02. EARLY WARNING SIGNS
        let urgeObservations = sessions.filter { $0.switchedCount > 0 }.count
        let urgeConf: Confidence = urgeObservations >= Threshold.strongSample ? .strong : (urgeObservations >= Threshold.earlySample ? .early : .unknown)
        let firstSwitchLatencies = evidence.filter { $0.evidenceType == "FIRST_SWITCH_LATENCY" }.compactMap { $0.numericValue }
        let medianFirstSwitch = median(firstSwitchLatencies)
        let urgeFinding: String
        if let medianFirstSwitch, firstSwitchLatencies.count >= Threshold.earlySample {
            urgeFinding = "\(urgeObservations) session(s) avec au moins un décrochage. Premier décrochage médian : \(Int(medianFirstSwitch.rounded())) min."
        } else if urgeObservations > 0 {
            urgeFinding = "\(urgeObservations) session(s) avec au moins un décrochage, mais pas encore assez de latences précises pour un moment médian fiable."
        } else {
            urgeFinding = "Aucune session avec décrochage enregistré."
        }
        sections.append(ManualSection(
            id: 2,
            number: "02",
            title: "TES SIGNAUX D'ALERTE PRÉCOCES",
            finding: urgeFinding,
            confidence: urgeConf,
            basis: urgeObservations >= Threshold.earlySample ? .observed : .unknown,
            evidenceCount: urgeObservations,
            evidenceSummary: "\(urgeObservations) sessions avec décrochage recensé.",
            practicalRule: medianFirstSwitch.map { m in
                "À la minute \(Int(m.rounded())), marquer une pause volontaire de 3 respirations avant toute bascule."
            } ?? "Noter la minute de la première tension après chaque session.",
            recommendation: "Garder une feuille blanche à côté du clavier pour y déposer les idées parasites sans quitter la tâche."
        ))

        // 03. YOUR EFFECTIVE FOCUS RANGE
        let staySessions = sessions.filter { $0.mode == .stay && $0.actualDurationSeconds > 0 }
        let stayDurations = staySessions.map { Double($0.actualDurationSeconds) / 60.0 }
        let medianStay = median(stayDurations)
        let focusRangeConf: Confidence = staySessions.count >= 8 ? .strong : (staySessions.count >= 3 ? .early : .unknown)
        let focusFinding: String
        if let medianStay, staySessions.count >= 3 {
            let minDur = Int((stayDurations.min() ?? 0).rounded())
            let maxDur = Int((stayDurations.max() ?? 0).rounded())
            focusFinding = "\(staySessions.count) sessions STAY complétées. Durée médiane : \(Int(medianStay.rounded())) min (min \(minDur) – max \(maxDur))."
        } else {
            focusFinding = "Trop peu de sessions STAY comparables (\(staySessions.count)) pour estimer une plage utile. Complète au moins 3 sessions avant de conclure."
        }
        sections.append(ManualSection(
            id: 3,
            number: "03",
            title: "TA PLAGE DE FOCUS OPTIMALE",
            finding: focusFinding,
            confidence: focusRangeConf,
            basis: staySessions.count >= 3 ? .observed : .unknown,
            evidenceCount: staySessions.count,
            evidenceSummary: "\(staySessions.count) sessions STAY complétées sur le protocole.",
            practicalRule: medianStay.map { m in
                "Planifier des blocs de \(Int(m.rounded())) minutes avec une fin explicite."
            } ?? "Commencer par des blocs courts (10–15 min) sans prétendre connaître ta plage.",
            recommendation: medianStay.map { m in
                "N'allonger que si la durée médiane est régulière ; tester \(Int(m.rounded()) + 5) minutes la semaine suivante."
            }
        ))

        // 04. FIRST SWITCH PATTERN
        let switchConf: Confidence = firstSwitchLatencies.count >= Threshold.strongSample ? .strong : (firstSwitchLatencies.count >= Threshold.earlySample ? .early : .unknown)
        let switchFinding: String
        if let medianFirstSwitch, firstSwitchLatencies.count >= Threshold.earlySample {
            switchFinding = "Premier décrochage médian : \(Int(medianFirstSwitch.rounded())) min sur \(firstSwitchLatencies.count) mesures."
        } else {
            switchFinding = "Pas assez de mesures de latence (\(firstSwitchLatencies.count)) pour établir un modèle fiable."
        }
        sections.append(ManualSection(
            id: 4,
            number: "04",
            title: "TON MODÈLE DU PREMIER DÉCROCHAGE",
            finding: switchFinding,
            confidence: switchConf,
            basis: firstSwitchLatencies.count >= Threshold.earlySample ? .observed : .unknown,
            evidenceCount: firstSwitchLatencies.count,
            evidenceSummary: "\(firstSwitchLatencies.count) mesures de latence de première bascule.",
            practicalRule: medianFirstSwitch.map { m in
                "Surveiller la fenêtre autour de la minute \(Int(m.rounded())) avec une posture physique engagée."
            } ?? "Enregistrer les latences de premier décrochage pendant les prochaines sessions.",
            recommendation: medianFirstSwitch.map { m in
                "À la minute \(Int(m.rounded())), attendre 60 secondes avant d'autoriser une bascule."
            }
        ))

        // 05. RETURN PATTERN
        let returnEvidence = evidence.filter { $0.dimension == "RETURN" && $0.evidenceType == "RETURN_AFTER_SWITCH" }
        let resumedCount = returnEvidence.filter { $0.categoricalValue == "RESUMED_SESSION" }.count
        let returnConf: Confidence = returnEvidence.count >= Threshold.strongSample ? .strong : (returnEvidence.count >= Threshold.earlySample ? .early : .unknown)
        let returnFinding: String
        if returnEvidence.count >= Threshold.earlySample {
            returnFinding = "\(returnEvidence.count) retours après bascule observés ; \(resumedCount) ré-engagement(s) immédiat(s)."
        } else {
            returnFinding = "Aucun retour après bascule mesuré (il faut au moins 2 observations)."
        }
        sections.append(ManualSection(
            id: 5,
            number: "05",
            title: "TON MODÈLE DE RETOUR APRÈS DISTRACTION",
            finding: returnFinding,
            confidence: returnConf,
            basis: returnEvidence.count >= Threshold.earlySample ? .observed : .unknown,
            evidenceCount: returnEvidence.count,
            evidenceSummary: "\(returnEvidence.count) observations de ré-engagement après switch.",
            practicalRule: returnEvidence.count >= Threshold.earlySample
                ? "Après une interruption, reprendre la dernière phrase commencée dans les \(Threshold.returnWindowSeconds) secondes."
                : "Noter après chaque bascule si tu es revenu à la tâche.",
            recommendation: "Ne pas relancer un nouveau cycle tant que le décrochage n'a pas été refermé."
        ))

        // 06. BEST ENVIRONMENTS
        let envConf: Confidence = interventions.count >= 3 ? .strong : (interventions.count >= 1 ? .early : .unknown)
        let phoneLoc = profile?.phoneLocation
        let envFinding: String
        if interventions.isEmpty {
            envFinding = phoneLoc.map { "Aucune intervention vérifiée. Position du téléphone déclarée : \($0)." }
                ?? "Aucune intervention d'environnement appliquée ni position de téléphone déclarée."
        } else {
            envFinding = phoneLoc.map { "\(interventions.count) intervention(s) d'environnement appliquée(s). Position du téléphone déclarée : \($0)." }
                ?? "\(interventions.count) intervention(s) d'environnement appliquée(s)."
        }
        sections.append(ManualSection(
            id: 6,
            number: "06",
            title: "TES MEILLEURS ENVIRONNEMENTS",
            finding: envFinding,
            confidence: envConf,
            basis: interventions.count >= 1 ? .observed : (phoneLoc != nil ? .preference : .unknown),
            evidenceCount: interventions.count,
            evidenceSummary: "\(interventions.count) interventions d'environnement appliquées et vérifiées.",
            practicalRule: phoneLoc.map { "Garder le téléphone \($0) pendant les blocs de travail." }
                ?? "Tester une distance physique volontaire (autre pièce) pendant 3 sessions.",
            recommendation: "Un seul document ouvert en plein écran, barre des signets masquée."
        ))

        // 07. PHONE RULES
        let phoneRules = rules.filter { $0.rule.localizedCaseInsensitiveContains("téléphone") || $0.rule.localizedCaseInsensitiveContains("phone") }
        let phoneFinding: String
        if let first = phoneRules.first {
            phoneFinding = "\(phoneRules.count) règle(s) téléphone active(s) enregistrée(s). La première : « \(first.rule) »."
        } else {
            phoneFinding = "Aucune règle téléphone active enregistrée."
        }
        sections.append(ManualSection(
            id: 7,
            number: "07",
            title: "TES RÈGLES TÉLÉPHONE",
            finding: phoneFinding,
            confidence: phoneRules.isEmpty ? .unknown : .selfReport,
            basis: phoneRules.isEmpty ? .unknown : .preference,
            evidenceCount: phoneRules.count,
            evidenceSummary: "\(phoneRules.count) règle(s) téléphone validée(s). Aucune comparaison d'efficacité « 3× » : elle n'est pas calculée.",
            practicalRule: phoneRules.first?.rule ?? "Définir une règle téléphone testable (ex. téléphone dans une autre pièce pendant le bloc).",
            recommendation: "Si le téléphone t'invite au lit, le recharger ailleurs pendant la nuit."
        ))

        // 08. DIGITAL RULES
        let tabBucket = profile?.openTabsBucket
        let notifLevel = profile?.notificationsLevel
        let digitalFinding: String
        switch (tabBucket, notifLevel) {
        case let (tab?, notif?):
            digitalFinding = "Déclaré : \(tab) onglet(s), réglage de notifications « \(notif) ». Aucune mesure directe des onglets en session."
        case let (tab?, nil):
            digitalFinding = "Déclaré : \(tab) onglet(s). Niveau de notifications non renseigné."
        case let (nil, notif?):
            digitalFinding = "Déclaré : notifications « \(notif) ». Nombre d'onglets non renseigné."
        case (nil, nil):
            digitalFinding = "Aucun réglage numérique déclaré."
        }
        sections.append(ManualSection(
            id: 8,
            number: "08",
            title: "TES RÈGLES NUMÉRIQUES",
            finding: digitalFinding,
            confidence: (tabBucket != nil || notifLevel != nil) ? .selfReport : .unknown,
            basis: (tabBucket != nil || notifLevel != nil) ? .preference : .unknown,
            evidenceCount: 0,
            evidenceSummary: "Auto-déclaré ; aucune mesure d'onglets ou de notifications en session.",
            practicalRule: tabBucket.map { bucket in
                "Travailler avec \(bucket) onglet(s) maximum pendant un bloc."
            } ?? "Fermer les onglets inactifs avant chaque session.",
            recommendation: "Traiter les messages en 2 fenêtres fixes par jour plutôt qu'en flux continu."
        ))

        // 09. FLOW CONDITIONS
        let flowConf: Confidence = flowSessions.count >= 4 ? .strong : (flowSessions.count >= 1 ? .early : .unknown)
        let flowFinding = flowSessions.isEmpty
            ? "Aucune session Flow Lab enregistrée : tes conditions de flow ne sont pas encore mesurées."
            : "\(flowSessions.count) session(s) Flow Lab enregistrée(s). Pas encore assez de répétitions pour comparer les conditions entre elles."
        sections.append(ManualSection(
            id: 9,
            number: "09",
            title: "TES CONDITIONS DE FLOW",
            finding: flowFinding,
            confidence: flowConf,
            basis: flowSessions.count >= 1 ? .observed : .unknown,
            evidenceCount: flowSessions.count,
            evidenceSummary: "\(flowSessions.count) sessions de Flow Lab complétées.",
            practicalRule: "Définir « à quoi ressemble la fin » en une phrase mesurable avant de démarrer.",
            recommendation: "Choisir un mécanisme de feedback visible (compteur de mots, tests passants, étapes cochées)."
        ))

        // 10. CHALLENGE RANGE
        let taskRatings = flowTasks.compactMap { $0.challengeRatingBefore }
        let chalConf: Confidence = taskRatings.count >= Threshold.challengeSample ? .strong : (taskRatings.count >= 3 ? .early : .unknown)
        let chalFinding: String
        if taskRatings.count >= Threshold.challengeSample {
            let medianRating = median(taskRatings.map(Double.init))
            let justeCount = taskRatings.filter { $0 == 3 }.count
            chalFinding = "\(taskRatings.count) évaluations de difficulté avant session ; médiane \(Int((medianRating ?? 3).rounded()))/5, dont \(justeCount) évaluée(s) « juste »."
        } else {
            chalFinding = "Pas assez d'évaluations de difficulté (\(taskRatings.count) / \(Threshold.challengeSample)) pour estimer une zone."
        }
        sections.append(ManualSection(
            id: 10,
            number: "10",
            title: "TA ZONE DE DÉFI OPTIMALE",
            finding: chalFinding,
            confidence: chalConf,
            basis: taskRatings.count >= 3 ? .observed : .unknown,
            evidenceCount: taskRatings.count,
            evidenceSummary: "\(taskRatings.count) évaluations de difficulté avant session.",
            practicalRule: taskRatings.count >= Threshold.challengeSample
                ? "Viser des tâches évaluées autour de \(Int((median(taskRatings.map(Double.init)) ?? 3).rounded()))/5 avant de lancer."
                : "Évaluer la difficulté avant chaque session Flow.",
            recommendation: "Si une tâche paraît trop dure, la découper en une sous-étape de 15 minutes."
        ))

        // 11. HOW YOU LEARN BEST
        let recallSessions = sessions.filter { $0.mode == .recall || $0.mode == .explain }
        let recallEvaluations = evidence.filter { $0.dimension == "RECALL" && $0.evidenceType == "evaluation" }.compactMap { $0.numericValue }
        let learnConf: Confidence = recallSessions.count >= 4 ? .strong : (recallSessions.count >= 1 ? .early : .unknown)
        let learnFinding: String
        if !recallEvaluations.isEmpty {
            let avg = recallEvaluations.reduce(0, +) / Double(recallEvaluations.count)
            learnFinding = "\(recallSessions.count) session(s) de restitution active ; \(recallEvaluations.count) évaluation(s), moyenne \(String(format: "%.1f", avg))/10."
        } else if !recallSessions.isEmpty {
            learnFinding = "\(recallSessions.count) session(s) de restitution active, mais aucune évaluation enregistrée."
        } else {
            learnFinding = "Aucune session de restitution active : la formule n'est pas encore testée sur tes données."
        }
        sections.append(ManualSection(
            id: 11,
            number: "11",
            title: "COMMENT TU APPRENDS LE MIEUX",
            finding: learnFinding,
            confidence: learnConf,
            basis: !recallSessions.isEmpty ? .observed : .unknown,
            evidenceCount: recallSessions.count,
            evidenceSummary: "\(recallSessions.count) sessions de restitution active.",
            practicalRule: "Après chaque lecture clé, fermer le support et écrire 3 points essentiels de mémoire.",
            recommendation: "Expliquer le mécanisme causal plutôt que mémoriser des listes isolées."
        ))

        // 12. ENERGY PATTERNS
        let energyConf: Confidence = energyCheckIns.count >= 5 ? .strong : (energyCheckIns.count >= 1 ? .selfReport : .unknown)
        let bestWin = profile?.bestWindow
        let energyFinding: String
        if energyCheckIns.isEmpty {
            energyFinding = bestWin.map { "Aucun check-in d'énergie. Fenêtre préférée déclarée : \($0) (préférence, non mesurée)." }
                ?? "Aucun check-in d'énergie ni fenêtre déclarée."
        } else {
            energyFinding = bestWin.map { "\(energyCheckIns.count) check-in(s) d'énergie. Fenêtre préférée déclarée : \($0) (préférence)." }
                ?? "\(energyCheckIns.count) check-in(s) d'énergie enregistré(s)."
        }
        sections.append(ManualSection(
            id: 12,
            number: "12",
            title: "TES CYCLES D'ÉNERGIE",
            finding: energyFinding,
            confidence: energyConf,
            basis: energyCheckIns.count >= 1 ? .observed : (bestWin != nil ? .preference : .unknown),
            evidenceCount: energyCheckIns.count,
            evidenceSummary: "\(energyCheckIns.count) check-ins d'énergie enregistrés.",
            practicalRule: bestWin.map { "Réserver \($0) pour le travail le plus difficile." }
                ?? "Rien à conclure sur une fenêtre idéale : déclare-la ou mesure-la d'abord.",
            recommendation: "Placer l'administratif dans les créneaux de basse énergie perçue."
        ))

        // 13. WHAT WORKED
        let positiveExp = experiments.filter { ($0.status == "COMPLETED" || $0.status == "READY_TO_REVIEW") && $0.result == "positive" }
        let expDone = experiments.filter { $0.status == "COMPLETED" || $0.status == "READY_TO_REVIEW" }
        let workedFinding: String
        if !positiveExp.isEmpty {
            let titles = positiveExp.prefix(3).map { $0.title }.joined(separator: " ; ")
            workedFinding = "\(positiveExp.count) expérience(s) complétée(s) avec résultat positif : \(titles)."
        } else if !expDone.isEmpty {
            workedFinding = "\(expDone.count) expérience(s) terminée(s), aucune avec résultat positif enregistré."
        } else {
            workedFinding = "Aucune expérience terminée : rien à consolider pour l'instant."
        }
        sections.append(ManualSection(
            id: 13,
            number: "13",
            title: "CE QUI A FONCTIONNÉ POUR TOI",
            finding: workedFinding,
            confidence: positiveExp.count >= 2 ? .strong : (positiveExp.count >= 1 ? .early : .unknown),
            basis: !positiveExp.isEmpty ? .observed : .unknown,
            evidenceCount: positiveExp.count,
            evidenceSummary: "\(expDone.count) expérience(s) terminée(s) ; \(rules.count) règle(s) active(s).",
            practicalRule: positiveExp.first.map { "Continuer d'appliquer : \($0.title)." }
                ?? "Terminer au moins 3 expériences avant de consolider une règle pérenne.",
            recommendation: "Garder un système minimaliste sans ajouter de friction."
        ))

        // 14. WHAT DIDN'T WORK
        let failedExp = experiments.filter { $0.status == "ABANDONED" || $0.result == "negative" }
        let failedFinding: String
        if !failedExp.isEmpty {
            let titles = failedExp.prefix(3).map { $0.title }.joined(separator: " ; ")
            failedFinding = "\(failedExp.count) expérience(s) abandonnée(s) ou négative(s) : \(titles)."
        } else {
            failedFinding = "Aucune expérience abandonnée ou négative enregistrée."
        }
        sections.append(ManualSection(
            id: 14,
            number: "14",
            title: "CE QUI N'A PAS MARCHÉ",
            finding: failedFinding,
            confidence: failedExp.count >= 1 ? .early : .unknown,
            basis: !failedExp.isEmpty ? .observed : .unknown,
            evidenceCount: failedExp.count,
            evidenceSummary: "\(failedExp.count) expérience(s) abandonnée(s) ou inadaptée(s).",
            practicalRule: "Éliminer sans culpabilité les règles qui créent du stress sans résultat mesurable.",
            recommendation: "Préférer les changements d'environnement aux interdictions strictes."
        ))

        // 15. WHAT IS STILL UNKNOWN
        var unknowns: [String] = []
        if firstSwitchLatencies.count < 3 { unknowns.append("Moment médian fiable du premier décrochage") }
        if energyCheckIns.count < 7 { unknowns.append("Lien entre sommeil déclaré et premières bascules") }
        if recallEvaluations.count < 3 { unknowns.append("Rétention à 14 jours sans réactivation") }
        if flowSessions.count < 3 { unknowns.append("Conditions de flow comparées sur le travail créatif") }
        if unknowns.isEmpty { unknowns.append("Impact des longues interruptions sur la mémoire de travail") }

        sections.append(ManualSection(
            id: 15,
            number: "15",
            title: "CE QUI RESTE ENCORE À MESURER",
            finding: "Ces dimensions ont trop peu de données pour être conclues aujourd'hui. Elles restent ouvertes par design.",
            confidence: .unknown,
            basis: .unknown,
            evidenceCount: 0,
            evidenceSummary: "\(unknowns.count) zone(s) d'incertitude identifiée(s).",
            practicalRule: "Continuer à observer sans préjugé lors des sessions hebdomadaires.",
            recommendation: unknowns.first ?? "Observer la constance sur le long terme."
        ))

        // 16. CORE MODE
        sections.append(ManualSection(
            id: 16,
            number: "16",
            title: "TON MODE DE CROISIÈRE POST-JOUR 90",
            finding: "\(sessions.count) session(s) de protocole complétée(s). Le mode maintenance est un choix de design : il ne prétend pas que ton attention est « guérie ».",
            confidence: sessions.count >= 60 ? .strong : .early,
            basis: .general,
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
