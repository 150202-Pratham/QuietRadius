import SwiftUI

struct SessionStats {
    var totalDuration: TimeInterval
    var noisyDuration: TimeInterval
    var tasksCompleted: Int
    var totalTasks: Int
    var noiseDisruptions: [Date]
    var averageNoiseLevel: Float
    
    var effectiveDuration: TimeInterval {
        totalDuration - noisyDuration
    }
    
    var effectivePercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return effectiveDuration / totalDuration
    }
}

struct SessionResultView: View {
    let stats: SessionStats
    let onDisclaimer: () -> Void
    let onNewSession: () -> Void
    
    // Theme Colors
    let tealColor = Color(hex: "233D4C")
    let peachColor = Color(hex: "FD802E")
    
    var body: some View {
        ZStack {
            // Background
            tealColor.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                Text("Session Complete! 🎉")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // 1. Effective Study Time Card
                        VStack(spacing: 10) {
                            Text("EFFECTIVE STUDY TIME")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1.5)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text(formatTime(stats.effectiveDuration))
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundColor(peachColor)
                            
                            Text("(\(Int(stats.effectivePercentage * 100))% Focus)")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.vertical, 8)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Total Time")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                    Text(formatTime(stats.totalDuration))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Noisy Distractions")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                    Text(formatTime(stats.noisyDuration))
                                        .fontWeight(.bold)
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        
                        // 2. Task Completion
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Tasks Done",
                                value: "\(stats.tasksCompleted)/\(stats.totalTasks)",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Avg Noise",
                                value: String(format: "%.0f%%", stats.averageNoiseLevel * 100),
                                icon: "waveform.path.ecg",
                                color: .blue
                            )
                        }
                        
                        // 3. Insights
                        VStack(alignment: .leading, spacing: 16) {
                            Text("INSIGHTS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1.5)
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                
                                if stats.noiseDisruptions.isEmpty {
                                    Text("Great job! No major noise disruptions detected.")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                } else {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Noise disrupted you at:")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        ForEach(stats.noiseDisruptions.prefix(3), id: \.self) { date in
                                            Text("• " + formatDate(date))
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        if stats.noiseDisruptions.count > 3 {
                                            Text("...and \(stats.noiseDisruptions.count - 3) more times")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Footer Buttons
                VStack(spacing: 12) {
                    Button(action: onNewSession) {
                        Text("New Session")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(peachColor)
                            .foregroundColor(tealColor)
                            .cornerRadius(16)
                    }
                    
                    Button(action: onDisclaimer) {
                        Text("Done")
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(24)
            }
        }
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02dm %02ds", minutes, seconds)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Session Rating Sheet

struct SessionRatingSheet: View {
    @Binding var pendingRating: Int
    let onSave: (Int) -> Void
    let onSkip: () -> Void
    let peachColor: Color
    let tealColor: Color

    var body: some View {
        ZStack {
            tealColor.ignoresSafeArea()

            VStack(spacing: 28) {
                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                Text("Rate Your Session")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("How productive did this session feel?")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                // Star Picker
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                pendingRating = star
                            }
                        }) {
                            Image(systemName: star <= pendingRating ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundColor(star <= pendingRating ? peachColor : .white.opacity(0.3))
                                .scaleEffect(star <= pendingRating ? 1.1 : 1.0)
                                .animation(.spring(response: 0.2), value: pendingRating)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)

                // Save Button
                Button(action: { onSave(pendingRating) }) {
                    Text("Save to History")
                        .fontWeight(.bold)
                        .foregroundColor(tealColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(peachColor)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)

                // Skip
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()
            }
        }
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.hidden)
    }
}
