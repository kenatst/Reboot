import SwiftUI
import SwiftData

/// REBOOT / CALIBRATION — a fast conversational diagnosis after the cinematic
/// introduction. Outputs are stored in RebootUserProfile; no scores invented.
struct OnboardingDiagnosisView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var goals: Set<String> = []
    @State private var win = ""
    @State private var distractor = ""
    @State private var moments: Set<String> = []
    @State private var capacity = ""
    @State private var returnDifficulty = 3
    @State private var readsTenPages = ""
    @State private var switching = 3
    @State private var flowActivities: Set<String> = []
    @State private var flowDifference: Set<String> = []
    @State private var phoneLocation = ""
    @State private var notifications = ""
    @State private var tabs = ""
    @State private var screenLimits = ""
    @State private var bestWindow = ""
    @State private var sleep = ""
    @State private var energy = ""
    @State private var caffeine = ""
    @State private var finished = false

    private let goalOptions = [
        "Arrêter de scroller automatiquement", "Mieux travailler", "Mieux étudier",
        "Lire plus longtemps", "Retrouver de la concentration", "Faire du deep work",
        "Mieux apprendre", "Retrouver du calme mental", "Moins dépendre du téléphone",
        "Construire une vraie discipline"
    ]
    private let distractorOptions = ["Instagram", "TikTok", "YouTube", "X", "Reddit", "WhatsApp", "Messages", "Email", "News", "Gaming", "Browser", "Work notifications"]
    private let momentOptions = ["réveil", "lit", "transport", "pendant le travail", "pendant les études", "repas", "attente", "ennui", "conversations", "télévision"]
    private let capacityOptions = ["<5", "5–10", "10–20", "20–30", "30–45", "45–60", "60+"]
    private let flowOptions = ["sport", "gaming", "music", "cooking", "drawing", "coding", "reading", "writing", "crafting", "conversation", "work"]
    private let differenceOptions = ["difficile mais faisable", "je sais quoi faire", "résultat visible", "personne ne m'interrompt", "j'aime vraiment ça", "je vois mes progrès", "avec d'autres", "physiquement engagé", "je perds la notion du temps"]
    private let phoneOptions = ["in-hand", "desk", "pocket", "nearby", "another-room"]
    private let notificationOptions = ["nearly-all", "many", "only-important", "mostly-disabled"]
    private let tabOptions = ["1–3", "4–10", "10–20", "20+"]
    private let sleepOptions = ["<5", "5–6", "6–7", "7–8", "8+"]
    private let windowOptions = ["morning", "late-morning", "afternoon", "evening", "variable"]
    private let energyOptions = ["Low", "Normal", "High"]
    private let caffeineOptions = ["None", "Morning only", "Morning + afternoon", "Late afternoon/evening"]

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            if finished {
                summary
            } else {
                VStack(spacing: 0) {
                    header
                    ScrollView {
                        stepView
                            .padding(.horizontal, RBSpacing.screen)
                            .padding(.top, 24)
                    }
                    footer
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private var header: some View {
        HStack {
            RBStatusChip(text: "REBOOT / CALIBRATION", color: .signalCyan, pulse: true)
            Spacer()
            Text(String(format: "%02d / 14", min(step + 1, 14)))
                .font(.metadata(size: 10))
                .tracking(1.6)
                .foregroundStyle(.ash)
        }
        .padding(.horizontal, RBSpacing.screen)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case 0:
            multiQuestion("POURQUOI ES-TU LÀ ?", subtitle: "Choisis tout ce qui te parle.", options: goalOptions, selection: $goals)
        case 1:
            textQuestion("UNE VICTOIRE DANS 90 JOURS ?", subtitle: "Ce qui serait un vrai win pour toi.", text: $win, placeholder: "travailler 60 minutes sans téléphone…")
        case 2:
            singleQuestion("QU'EST-CE QUI VOLE TON ATTENTION ?", subtitle: "Ton distrait principal.", options: distractorOptions, selection: $distractor)
        case 3:
            multiQuestion("QUAND VÉRIFIES-TU LE PLUS AUTOMATIQUEMENT ?", subtitle: "Les moments réflexes.", options: momentOptions, selection: $moments)
        case 4:
            singleQuestion("COMBIEN DE TEMPS PEUX-TU TRAVAILLER AVANT DE CHANGER ?", subtitle: "Minutes.", options: capacityOptions, selection: $capacity)
        case 5:
            sliderQuestion("QUAND TU ES DISTRAIT, REVENIR EST…", value: $returnDifficulty, low: "FACILE", high: "DIFFICILE")
        case 6:
            singleQuestion("PEUX-TU LIRE 10 PAGES SANS VÉRIFIER TON TÉLÉPHONE ?", subtitle: "", options: ["Oui", "Parfois", "Non"], selection: $readsTenPages)
        case 7:
            sliderQuestion("COMMENCES-TU DES CHOSES ET CHANGES AVANT DE FINIR ?", value: $switching, low: "RAREMENT", high: "TOUT LE TEMPS")
        case 8:
            multiQuestion("QU'EST-CE QUI TE FAIT DÉJÀ OUBLIER TON TÉLÉPHONE ?", subtitle: "Tes activités d'absorption existantes.", options: flowOptions, selection: $flowActivities)
        case 9:
            multiQuestion("QU'EST-CE QUI REND CES ACTIVITÉS DIFFÉRENTES ?", subtitle: "Les conditions de ton flow.", options: differenceOptions, selection: $flowDifference)
        case 10:
            VStack(spacing: 18) {
                singleQuestion("OÙ EST TON TÉLÉPHONE QUAND TU TRAVAILLES ?", subtitle: "", options: phoneOptions, selection: $phoneLocation)
                singleQuestion("NOTIFICATIONS ?", subtitle: "", options: notificationOptions, selection: $notifications)
            }
        case 11:
            VStack(spacing: 18) {
                singleQuestion("COMBIEN D'ONGLETS OUVERTS EN GÉNÉRAL ?", subtitle: "", options: tabOptions, selection: $tabs)
                singleQuestion("LIMITES D'ÉCRAN ACTIVES ?", subtitle: "", options: ["Oui", "Non", "Parfois"], selection: $screenLimits)
            }
        case 12:
            VStack(spacing: 18) {
                singleQuestion("TA MEILLEURE FENÊTRE MENTALE ?", subtitle: "", options: windowOptions, selection: $bestWindow)
                singleQuestion("SOMMEIL TYPIQUE ?", subtitle: "Heures.", options: sleepOptions, selection: $sleep)
            }
        default:
            VStack(spacing: 18) {
                singleQuestion("ÉNERGIE ACTUELLE ?", subtitle: "", options: energyOptions, selection: $energy)
                singleQuestion("CAFÉINE ?", subtitle: "", options: caffeineOptions, selection: $caffeine)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button {
                    withAnimation { step -= 1 }
                } label: {
                    Text("RETOUR")
                        .font(.metadata(size: 10))
                        .tracking(1.4)
                        .foregroundStyle(.ash)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
            }
            Button {
                withAnimation { advance() }
            } label: {
                HStack {
                    Text(step >= 13 ? "TERMINER" : "SUIVANT")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(.rbSystem)
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.4)
        }
        .padding(.horizontal, RBSpacing.screen)
        .padding(.bottom, 18)
    }

    private var canAdvance: Bool {
        switch step {
        case 0: return !goals.isEmpty
        case 1: return !win.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !distractor.isEmpty
        case 3: return !moments.isEmpty
        case 4: return !capacity.isEmpty
        case 6: return !readsTenPages.isEmpty
        case 8: return !flowActivities.isEmpty
        case 10: return !phoneLocation.isEmpty && !notifications.isEmpty
        case 11: return !tabs.isEmpty && !screenLimits.isEmpty
        case 12: return !bestWindow.isEmpty && !sleep.isEmpty
        case 13: return !energy.isEmpty && !caffeine.isEmpty
        default: return true
        }
    }

    private func advance() {
        if step >= 13 {
            save()
            withAnimation(.easeOut(duration: 0.3)) {
                finished = true
            }
        } else {
            step += 1
        }
    }

    private func save() {
        let profile = AdaptiveRebootEngineDriver.ensureProfile(context: modelContext)
        profile.goalsRaw = Array(goals)
        profile.primaryGoal = goals.first ?? ""
        profile.winDescription = win
        profile.primaryDistractor = distractor
        profile.checkMomentsRaw = Array(moments)
        profile.capacityBucket = capacity
        profile.returnDifficulty = returnDifficulty
        profile.readsTenPages = readsTenPages
        profile.switchingFrequency = switching
        profile.existingFlowActivitiesRaw = Array(flowActivities)
        profile.flowDifferenceRaw = Array(flowDifference)
        profile.phoneLocation = phoneLocation
        profile.notificationsLevel = notifications
        profile.openTabsBucket = tabs
        profile.usesScreenTimeLimits = screenLimits
        profile.bestWindow = bestWindow
        profile.typicalSleep = sleep
        profile.currentEnergy = energy
        profile.caffeine = caffeine
        try? modelContext.save()
        AdaptiveRebootEngineDriver.recordEnergyCheckIn(
            energy: energy, sleep: sleep, caffeine: caffeine, window: bestWindow, context: modelContext
        )
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            RBSystemLabel(text: "REBOOT / PROFILE", color: .ash)
                .padding(.top, 34)
            Text("TON\nREBOOT PROFILE.")
                .font(.heroBlack(size: 40))
                .tracking(-0.4)
                .foregroundStyle(.bone)
                .padding(.top, 18)

            VStack(spacing: 12) {
                summaryRow("OBJECTIF PRINCIPAL", goals.first ?? "—")
                summaryRow("DISTRACTEUR PRINCIPAL", distractor)
                summaryRow("CAPACITÉ ACTUELLE", "\(capacity) MIN")
                summaryRow("FAIBLESSE PRINCIPALE", switching >= 4 ? "CHANGEMENT AUTOMATIQUE" : "MAINTIEN")
                summaryRow("MEILLEURE FENÊTRE", bestWindow)
            }
            .padding(16)
            .background(Color.graphiteSurface)
            .clipShape(RBChamferedShape(cut: 16))
            .padding(.top, 26)

            Spacer()
            Button {
                AdaptiveRebootEngineDriver.generatePrescription(forDay: 1, context: modelContext)
                dismiss()
            } label: {
                HStack {
                    Text("BUILD MY REBOOT")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(.rbSystem)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, RBSpacing.screen)
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.metadata(size: 10))
                .tracking(1.6)
                .foregroundStyle(.ash)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .default))
                .foregroundStyle(.bone)
                .multilineTextAlignment(.trailing)
        }
    }

    private func multiQuestion(_ title: String, subtitle: String, options: [String], selection: Binding<Set<String>>) -> some View {
        question(title: title, subtitle: subtitle) {
            ForEach(options, id: \.self) { option in
                selectableRow(option, selected: selection.wrappedValue.contains(option)) {
                    if selection.wrappedValue.contains(option) {
                        selection.wrappedValue.remove(option)
                    } else {
                        selection.wrappedValue.insert(option)
                    }
                }
            }
        }
    }

    private func singleQuestion(_ title: String, subtitle: String, options: [String], selection: Binding<String>) -> some View {
        question(title: title, subtitle: subtitle) {
            ForEach(options, id: \.self) { option in
                selectableRow(option, selected: selection.wrappedValue == option) {
                    selection.wrappedValue = option
                }
            }
        }
    }

    private func sliderQuestion(_ title: String, value: Binding<Int>, low: String, high: String) -> some View {
        question(title: title, subtitle: "") {
            VStack(spacing: 12) {
                Slider(value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0.rounded()) }
                ), in: 1...5, step: 1)
                .tint(.signalCyan)
                HStack {
                    Text(low).font(.metadata(size: 9)).foregroundStyle(.ash)
                    Spacer()
                    Text("\(value.wrappedValue)").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundStyle(.signalCyan)
                    Spacer()
                    Text(high).font(.metadata(size: 9)).foregroundStyle(.ash)
                }
            }
            .padding(.vertical, 12)
        }
    }

    private func textQuestion(_ title: String, subtitle: String, text: Binding<String>, placeholder: String) -> some View {
        question(title: title, subtitle: subtitle) {
            TextField(placeholder, text: text, axis: .vertical)
                .font(.body(size: 16))
                .foregroundStyle(.bone)
                .lineLimit(2...4)
                .padding(16)
                .background(Color.deepCarbon)
                .overlay(Rectangle().stroke(Color.line, lineWidth: 1))
        }
    }

    private func question<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.heroBlack(size: 26))
                .foregroundStyle(.bone)
                .lineSpacing(-2)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.body(size: 13))
                    .foregroundStyle(.ash)
            }
            content()
        }
        .padding(.bottom, 20)
    }

    private func selectableRow(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body(size: 15))
                    .foregroundStyle(selected ? .ink : .bone)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.ink)
                }
            }
            .padding(14)
            .background(selected ? Color.bonePlate : Color.deepCarbon)
            .clipShape(RBChamferedShape(cut: 10))
        }
        .buttonStyle(.plain)
    }
}
