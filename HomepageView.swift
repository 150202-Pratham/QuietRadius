import SwiftUI

struct HomepageView: View {
    // Brand Colors
    let peachColor = Color(hex: "FD802E")
    let tealColor = Color(hex: "233D4C")
    
    var body: some View {
        NavigationStack {
            IntroAnimationView()
        }
        .accentColor(peachColor)
    }
}

// MARK: - Dashboard View (Post-Animation Landing)

struct DashboardView: View {
    let tealColor = Color(hex: "233D4C")
    let peachColor = Color(hex: "FD802E")
    let darkTeal = Color(hex: "1A2E3A")
    
    @ObservedObject var store: SessionStore = .shared
    @State private var animateCards = false
    @State private var animateGreeting = false
    @State private var pulseStart = false
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Night Owl Mode"
        }
    }
    
    private var motivationText: String {
        let count = store.sessions.count
        if count == 0 { return "Ready to start your first focus session?" }
        if count < 5 { return "You're building a great habit. Keep going!" }
        if count < 15 { return "Consistency is key. You're doing amazing!" }
        return "You're a focus champion! 🏆"
    }
    
    private var totalMinutes: Int {
        store.sessions.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var avgEffectiveness: Int {
        guard !store.sessions.isEmpty else { return 0 }
        let total = store.sessions.reduce(0) { $0 + $1.effectivenessPercent }
        return total / store.sessions.count
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        let sessionDays = Set(store.sessions.map { calendar.startOfDay(for: $0.date) })
        
        while sessionDays.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [tealColor, darkTeal]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Ambient floating orbs
            GeometryReader { geo in
                Circle()
                    .fill(peachColor.opacity(0.06))
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                    .offset(x: geo.size.width * 0.6, y: geo.size.height * 0.1)
                
                Circle()
                    .fill(peachColor.opacity(0.04))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.6)
            }
            .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // MARK: — Greeting
                    VStack(alignment: .leading, spacing: 8) {
                        Text(greeting)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(motivationText)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .opacity(animateGreeting ? 1 : 0)
                    .offset(y: animateGreeting ? 0 : 20)
                    
                    // MARK: — Stats Dashboard
                    HStack(spacing: 14) {
                        GlassStatCard(
                            icon: "flame.fill",
                            value: "\(currentStreak)",
                            label: "Day Streak",
                            iconColor: .orange,
                            peachColor: peachColor
                        )
                        
                        GlassStatCard(
                            icon: "clock.fill",
                            value: "\(totalMinutes)m",
                            label: "Total Focus",
                            iconColor: Color(hex: "64B5F6"),
                            peachColor: peachColor
                        )
                        
                        GlassStatCard(
                            icon: "chart.bar.fill",
                            value: "\(avgEffectiveness)%",
                            label: "Avg Focus",
                            iconColor: Color(hex: "81C784"),
                            peachColor: peachColor
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 30)
                    
                    // MARK: — Start Session CTA
                    NavigationLink(destination: MainTabView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(peachColor)
                                    .frame(width: 52, height: 52)
                                    .scaleEffect(pulseStart ? 1.15 : 1.0)
                                    .opacity(pulseStart ? 0.6 : 1.0)
                                
                                Circle()
                                    .fill(peachColor)
                                    .frame(width: 52, height: 52)
                                
                                Image(systemName: "play.fill")
                                    .font(.title3)
                                    .foregroundColor(tealColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start Focus Session")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Plan your goals & begin")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundColor(peachColor)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(
                                            LinearGradient(
                                                colors: [peachColor.opacity(0.4), peachColor.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 30)
                    
                    // MARK: — Recent Sessions
                    if !store.sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Sessions")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                                
                                NavigationLink(destination: MainTabView()) {
                                    Text("See All →")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(peachColor)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 10) {
                                ForEach(store.sessions.prefix(3)) { session in
                                    CompactSessionRow(session: session, peachColor: peachColor)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 30)
                    }
                    
                    // MARK: — Weekly Insight
                    if store.sessions.count >= 3 {
                        HStack(spacing: 14) {
                            Image(systemName: "lightbulb.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Insight")
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
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        .opacity(animateCards ? 1 : 0)
                    }
                    
                    Color.clear.frame(height: 40)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateGreeting = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
                animateCards = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
                pulseStart = true
            }
        }
    }
}

// MARK: - Glass Stat Card

struct GlassStatCard: View {
    let icon: String
    let value: String
    let label: String
    let iconColor: Color
    let peachColor: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Compact Session Row

struct CompactSessionRow: View {
    let session: SessionRecord
    let peachColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            // Effectiveness ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: CGFloat(session.effectivenessPercent) / 100.0)
                    .stroke(effectColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(session.effectivenessPercent)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.durationMinutes) min session")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(formattedDate(session.date))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            // Stars
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= session.starRating ? "star.fill" : "star")
                        .font(.system(size: 10))
                        .foregroundColor(star <= session.starRating ? peachColor : .white.opacity(0.15))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var effectColor: Color {
        switch session.effectivenessPercent {
        case 80...: return Color(hex: "4CAF50")
        case 60..<80: return Color(hex: "FD802E")
        default: return Color(hex: "EF5350")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f.string(from: date)
    }
}

struct HomepageView_Previews: PreviewProvider {
    static var previews: some View {
        HomepageView()
    }
}
