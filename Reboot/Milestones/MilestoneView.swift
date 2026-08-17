import SwiftUI
import SwiftData

/// Cinematic milestones at 30 / 60 / 90 completed protocol sessions.
struct MilestoneView: View {
    let milestone: Milestone
    var onContinue: () -> Void

    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @Query private var progressList: [RebootProgress]
    @State private var showManual = false

    private var progress: RebootProgress? {
        progressList.first
    }

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    RBStatusChip(text: "REBOOT / MILESTONE", color: .signalCyan, pulse: true)
                        .padding(.top, 40)

                    Text(milestone.header)
                        .font(.heroBlack(size: 54))
                        .tracking(-0.8)
                        .foregroundStyle(.signalCyan)
                        .padding(.top, 26)

                    Text(milestoneTitle)
                        .font(.heroBlack(size: 38))
                        .foregroundStyle(.bone)
                        .multilineTextAlignment(.center)
                        .lineSpacing(-3)
                        .padding(.top, 16)

                    RBSignalLine(color: .signalCyan, thickness: 2)
                        .frame(width: 120)
                        .padding(.top, 26)

                    stats
                        .padding(.top, 34)

                    if milestone == .day90 {
                        coreModeChip
                            .padding(.top, 30)

                        Button {
                            showManual = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                Text("CONSULTER MON MANUEL OPÉRATOIRE")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                        }
                        .buttonStyle(.rbSystem)
                        .padding(.top, 14)
                    }

                    Button(action: onContinue) {
                        HStack {
                            Text(milestone == .day90 ? "CLÔTURER LE PROTOCOLE" : "CONTINUER")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(.rbPrimary())
                    .padding(.top, milestone == .day90 ? 14 : 34)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, RBSpacing.screen)
            }
        }
        .sheet(isPresented: $showManual) {
            AttentionOperatingManualView()
        }
        .statusBarHidden()
        .onAppear {
            #if DEBUG
            if UITestDriver.autoTour {
                Task {
                    try? await Task.sleep(nanoseconds: 3_500_000_000)
                    onContinue()
                }
            }
            #endif
        }
    }

    private var milestoneTitle: String {
        switch milestone {
        case .day30:
            return staysLonger ? "TU RESTES\nPLUS\nLONGTEMPS." : "30 SESSIONS.\nPHASE 02\nCOMPLETE."
        case .day60:
            return "60 SESSIONS.\nPHASE 03\nCOMPLETE."
        case .day90:
            return "90 JOURS.\nLE REBOOT\nS'ACHÈVE.\nLA PRATIQUE\nCONTINUE."
        }
    }

    private var staysLonger: Bool {
        guard sessions.count >= 8 else { return false }
        let recent = sessions.prefix(7)
        let older = sessions.dropFirst(7).prefix(7)
        guard !older.isEmpty else { return false }
        let recentAvg = recent.reduce(0) { $0 + $1.actualDurationSeconds } / recent.count
        let olderAvg = older.reduce(0) { $0 + $1.actualDurationSeconds } / older.count
        return recentAvg > olderAvg
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: 12) {
            statRow("SESSIONS", "\(sessions.count)")
            statRow("MINUTES", "\(sessions.reduce(0) { $0 + $1.actualDurationSeconds } / 60)")
            statRow("RESTITUTIONS", "\(sessions.filter { $0.mode == .recall }.count)")
            statRow("MODULES", "\(sessions.filter { $0.mode == .explain }.count)")
            statRow("OBSERVATIONS", "\(sessions.filter { $0.mode == .observe }.count)")
            statRow("CLARTÉ", ProtocolEngine.clarityStatus(sessionsCompleted: sessions.count).label)
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(Color.line, lineWidth: 1)
        )
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.metadata(size: 11))
                .tracking(2)
                .foregroundStyle(.ash)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.bone)
        }
    }

    private var coreModeChip: some View {
        VStack(alignment: .leading, spacing: 8) {
            RBStatusChip(text: "CORE MODE DÉBLOQUÉ", color: .signalCyan, pulse: true)
            Text("Maintenance suggérée : 3 sessions par semaine. Le protocole ne repart pas à zéro : il devient une pratique.")
                .font(.body(size: 14))
                .foregroundStyle(.softBone)
                .lineSpacing(4)
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: RBRadius.sm)
                .stroke(Color.signalCyan.opacity(0.5), lineWidth: 1)
        )
    }
}
