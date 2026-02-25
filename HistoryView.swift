import SwiftUI

// MARK: - Session Record Model

struct SessionRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let durationMinutes: Int
    let completedCheckpoints: Int
    let totalCheckpoints: Int
    let starRating: Int // 1-5

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        durationMinutes: Int,
        completedCheckpoints: Int,
        totalCheckpoints: Int,
        starRating: Int
    ) {
        self.id = id
        self.date = date
        self.durationMinutes = durationMinutes
        self.completedCheckpoints = completedCheckpoints
        self.totalCheckpoints = totalCheckpoints
        self.starRating = starRating
    }

    /// Effectiveness as a percentage (0–100)
    var effectivenessPercent: Int {
        guard totalCheckpoints > 0 else { return 0 }
        return Int((Double(completedCheckpoints) / Double(totalCheckpoints)) * 100)
    }
}

// MARK: - Session Store (Shared, persisted via UserDefaults)

@MainActor
class SessionStore: ObservableObject {
    static let shared = SessionStore()

    @Published var sessions: [SessionRecord] = []

    private let key = "quietradius_sessions"

    init() {
        load()
        // Inject demo data if empty so the History tab is never blank
        if sessions.isEmpty {
            sessions = SessionStore.demoSessions
            save()
        }
    }

    func addSession(_ record: SessionRecord) {
        sessions.insert(record, at: 0)
        save()
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        sessions.removeAll()
        save()
    }

    /// Last 7 sessions, most recent first
    var recentSessions: [SessionRecord] {
        Array(sessions.prefix(7))
    }

    /// Hour-of-day breakdown: average effectiveness per 4-hour bucket
    var weeklyPatternInsight: String {
        guard !sessions.isEmpty else { return "Complete more sessions to see patterns." }

        let calendar = Calendar.current
        var morningTotal = 0, morningCount = 0
        var afternoonTotal = 0, afternoonCount = 0
        var eveningTotal = 0, eveningCount = 0

        for s in sessions {
            let hour = calendar.component(.hour, from: s.date)
            if hour >= 5 && hour < 12 {
                morningTotal += s.effectivenessPercent; morningCount += 1
            } else if hour >= 12 && hour < 18 {
                afternoonTotal += s.effectivenessPercent; afternoonCount += 1
            } else {
                eveningTotal += s.effectivenessPercent; eveningCount += 1
            }
        }

        let morningAvg = morningCount > 0 ? morningTotal / morningCount : 0
        let afternoonAvg = afternoonCount > 0 ? afternoonTotal / afternoonCount : 0
        let eveningAvg = eveningCount > 0 ? eveningTotal / eveningCount : 0

        let best = max(morningAvg, afternoonAvg, eveningAvg)
        if best == morningAvg && morningCount > 0 {
            return "Best mornings" + (eveningAvg < afternoonAvg && eveningCount > 0 ? ", avoid evenings" : "")
        } else if best == afternoonAvg && afternoonCount > 0 {
            return "Peak focus in afternoons"
        } else {
            return "Evening sessions work best for you"
        }
    }

    // MARK: Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data) {
            sessions = decoded
        }
    }

    // MARK: Demo Data
    static var demoSessions: [SessionRecord] {
        let calendar = Calendar.current
        let now = Date()
        func daysAgo(_ n: Int, hour: Int) -> Date {
            var comps = calendar.dateComponents([.year, .month, .day], from: now)
            comps.hour = hour
            comps.minute = 0
            let base = calendar.date(from: comps) ?? now
            return calendar.date(byAdding: .day, value: -n, to: base) ?? now
        }
        return [
            SessionRecord(date: daysAgo(0, hour: 9),  durationMinutes: 25, completedCheckpoints: 3, totalCheckpoints: 4, starRating: 4),
            SessionRecord(date: daysAgo(1, hour: 19), durationMinutes: 25, completedCheckpoints: 2, totalCheckpoints: 4, starRating: 2),
            SessionRecord(date: daysAgo(2, hour: 8),  durationMinutes: 25, completedCheckpoints: 4, totalCheckpoints: 4, starRating: 5),
            SessionRecord(date: daysAgo(3, hour: 14), durationMinutes: 25, completedCheckpoints: 3, totalCheckpoints: 4, starRating: 3),
            SessionRecord(date: daysAgo(4, hour: 10), durationMinutes: 25, completedCheckpoints: 4, totalCheckpoints: 4, starRating: 5),
            SessionRecord(date: daysAgo(5, hour: 20), durationMinutes: 25, completedCheckpoints: 1, totalCheckpoints: 4, starRating: 1),
            SessionRecord(date: daysAgo(6, hour: 9),  durationMinutes: 25, completedCheckpoints: 3, totalCheckpoints: 4, starRating: 4),
        ]
    }
}

// MARK: - History View

struct HistoryView: View {
    let tealColor = Color(hex: "233D4C")
    let peachColor = Color(hex: "FD802E")

    @ObservedObject var store: SessionStore = .shared
    @State private var showClearConfirm: Bool = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [tealColor, tealColor.opacity(0.85)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Session cards
                    sessionListSection

                    // Weekly pattern card
                    if !store.sessions.isEmpty {
                        weeklyPatternCard
                    }

                    // Empty state
                    if store.sessions.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .alert("Clear All History?", isPresented: $showClearConfirm) {
            Button("Clear All", role: .destructive) {
                withAnimation { store.clearAll() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all session records.")
        }
    }

    // MARK: Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("History")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("\(store.sessions.count) Sessions")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            if !store.sessions.isEmpty {
                Button(action: { showClearConfirm = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("Clear All")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: Session List
    private var sessionListSection: some View {
        VStack(spacing: 12) {
            ForEach(Array(store.sessions.enumerated()), id: \.element.id) { index, session in
                SessionRowCard(
                    session: session,
                    sessionNumber: store.sessions.count - index,
                    peachColor: peachColor,
                    onDelete: {
                        withAnimation(.spring()) {
                            store.deleteSession(id: session.id)
                        }
                    }
                )
            }
        }
    }

    // MARK: Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.2))
            Text("No sessions yet")
                .font(.headline)
                .foregroundColor(.white.opacity(0.4))
            Text("Complete a focus session to see your history here.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: Weekly Pattern Card
    private var weeklyPatternCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundColor(peachColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Pattern")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)

                Text(store.weeklyPatternInsight)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(peachColor.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Session Row Card

struct SessionRowCard: View {
    let session: SessionRecord
    let sessionNumber: Int
    let peachColor: Color
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showDeleteButton: Bool = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button revealed on swipe
            if showDeleteButton {
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 72, height: 72)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(18)
                }
                .transition(.opacity)
            }

            // Main card content
            HStack(spacing: 16) {
                // Session number badge
                ZStack {
                    Circle()
                        .fill(peachColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text("\(sessionNumber)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(peachColor)
                }

                // Middle: label + checkmarks
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Session \(sessionNumber)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text("·")
                            .foregroundColor(.white.opacity(0.3))

                        Text(formattedDate(session.date))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }

                    // Checkmark indicators
                    HStack(spacing: 4) {
                        ForEach(0..<session.totalCheckpoints, id: \.self) { i in
                            Image(systemName: i < session.completedCheckpoints ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 13))
                                .foregroundColor(i < session.completedCheckpoints ? peachColor : .white.opacity(0.2))
                        }
                    }
                }

                Spacer()

                // Right: effectiveness + stars
                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(session.effectivenessPercent)%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(effectivenessColor(session.effectivenessPercent))

                    StarRatingView(rating: session.starRating, peachColor: peachColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(showDeleteButton ? 0.02 : 0.05))
            )
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                        } else if showDeleteButton {
                            offset = min(value.translation.width - 80, 0)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3)) {
                            if value.translation.width < -50 {
                                offset = -80
                                showDeleteButton = true
                            } else {
                                offset = 0
                                showDeleteButton = false
                            }
                        }
                    }
            )
        }
        .clipped()
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    private func effectivenessColor(_ pct: Int) -> Color {
        switch pct {
        case 80...: return Color(hex: "4CAF50")   // green
        case 60..<80: return Color(hex: "FD802E") // peach/orange
        default: return Color(hex: "EF5350")       // red
        }
    }
}

// MARK: - Star Rating View

struct StarRatingView: View {
    let rating: Int
    let peachColor: Color

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: 11))
                    .foregroundColor(star <= rating ? peachColor : .white.opacity(0.2))
            }
        }
    }
}

// MARK: - Preview

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
