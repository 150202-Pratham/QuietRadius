import SwiftUI
import Combine

struct TimerView: View {
    // Parameters
    let durationMinutes: Int
    let initialCheckpoints: [Checkpoint]
    
    // Theme Colors
    let tealColor = Color(hex: "233D4C")
    let peachColor = Color(hex: "FD802E")
    
    // State
    @State private var timeRemaining: TimeInterval
    @State private var totalTime: TimeInterval
    @State private var isActive: Bool = true
    @State private var progress: CGFloat = 1.0
    @State private var checkpoints: [Checkpoint]
    
    // Noise Level State
    @State private var selectedNoiseLevel: NoiseLevel = .balanced
    
    // Live Audio Monitor
    @StateObject private var audioMonitor = AudioMonitor()
    
    // Suggestion Tracking
    @State private var lastSuggestionTime: Date = Date()
    @State private var quietTimeStart: Date?
    @State private var noisyTimeStart: Date?
    @State private var currentSuggestion: String? // Separate suggestion handling
    
    // Session Stats Tracking
    @State private var totalNoisySeconds: Double = 0
    @State private var noiseDisruptions: [Date] = []
    @State private var cumulativeNoiseLevel: Float = 0
    @State private var noiseSampleCount: Int = 0
    @State private var lastDisruptionTime: Date? = nil
    @State private var sessionStats: SessionStats? = nil
    @State private var showResults: Bool = false
    
    // Session Rating Sheet
    @State private var showRatingSheet: Bool = false
    @State private var pendingRating: Int = 3
    
    // Environment
    @Environment(\.presentationMode) var presentationMode
    
    // Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(durationMinutes: Int, checkpoints: [Checkpoint]) {
        self.durationMinutes = durationMinutes
        self.initialCheckpoints = checkpoints
        
        // Initialize State
        _checkpoints = State(initialValue: checkpoints)
        
        let seconds = Double(durationMinutes * 60)
        _timeRemaining = State(initialValue: seconds)
        _totalTime = State(initialValue: seconds)
    }
    
    // Computed property: Auto-adjust noise level based on completion
    var completionPercentage: Double {
        guard !checkpoints.isEmpty else { return 0 }
        let completed = checkpoints.filter { $0.isCompleted }.count
        return Double(completed) / Double(checkpoints.count)
    }
    
    var autoNoiseLevel: NoiseLevel {
        if audioMonitor.isMonitoring {
            // Use live data if available
            let level = audioMonitor.normalizedLevel
            if level < 0.3 { return .quiet }
            if level < 0.7 { return .balanced }
            return .noisy
        } else {
            // Fallback to progress-based
            let percentage = completionPercentage
            if percentage < 0.34 { return .quiet }
            else if percentage < 0.67 { return .balanced }
            else { return .noisy }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [tealColor, tealColor.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Blur overlay for depth (Mac-like feel)
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.1)
                    .ignoresSafeArea()
                
                if isLandscape {
                    // MARK: - Landscape Layout (Split View)
                    HStack(spacing: 0) {
                        HStack(spacing: 20) {
                            // Removed side noise indicator to move it to center
                            // Timer (Center)
                            TimerPanel(
                                timeRemaining: timeRemaining,
                                isActive: isActive,
                                progress: progress,
                                peachColor: peachColor,
                                audioLevel: audioMonitor.normalizedLevel,
                                currentSuggestion: currentSuggestion,
                                onBack: { presentationMode.wrappedValue.dismiss() }
                            )
                            .frame(maxWidth: .infinity)
                            
                            // Spacer for balance
                            Color.clear.frame(width: 50)
                                .padding(.trailing, 30)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Vertical Divider
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 1)
                            .ignoresSafeArea()
                        
                        ControlSidebar(
                            checkpoints: $checkpoints,
                            selectedNoiseLevel: $selectedNoiseLevel,
                            isActive: $isActive,
                            onDismiss: endSession,
                            tealColor: tealColor,
                            peachColor: peachColor
                        )
                        .frame(width: 350)
                        .background(
                            Color.black.opacity(0.2)
                                .edgesIgnoringSafeArea(.all)
                        )
                        .onChange(of: checkpoints) { _ in
                            // Auto-update noise level based on completion if not monitoring (fallback)
                            if !audioMonitor.isMonitoring {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    selectedNoiseLevel = autoNoiseLevel
                                }
                            }
                        }
                        .onReceive(audioMonitor.$normalizedLevel) { level in
                            // Live update of noise level state
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedNoiseLevel = autoNoiseLevel
                            }
                            checkForSuggestions(level: level)
                        }
                    }
                } else {
                    // MARK: - Portrait Layout (Vertical Stack)
                    VStack(spacing: 0) {
                        // Header for Portrait
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(Circle())
                            }
                            Spacer()
                            Text("Focus Mode")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Color.clear.frame(width: 44, height: 44) // Balance
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        
                        // Timer with Noise Indicator
                        HStack(spacing: 20) {
                            // Timer (Center)
                            TimerPanel(
                                timeRemaining: timeRemaining,
                                isActive: isActive,
                                progress: progress,
                                peachColor: peachColor,
                                audioLevel: audioMonitor.normalizedLevel,
                                currentSuggestion: currentSuggestion,
                                onBack: nil
                            )
                            .frame(maxWidth: .infinity)
                            
                            // Spacer for balance
                            Color.clear.frame(width: 40)
                        }
                        .frame(height: geometry.size.height * 0.45) // Slightly increased height for suggestions
                        .padding(.horizontal, 10)
                        
                        // Controls (Bottom - Fixed, Not Scrollable)
                        ControlSidebar(
                            checkpoints: $checkpoints,
                            selectedNoiseLevel: $selectedNoiseLevel,
                            isActive: $isActive,
                            onDismiss: endSession,
                            tealColor: tealColor,
                            peachColor: peachColor,
                            isPortrait: true
                        )
                        .background(
                            Color.black.opacity(0.2)
                        )
                        .cornerRadius(30, corners: [.topLeft, .topRight])
                        .onChange(of: checkpoints) { _ in
                             if !audioMonitor.isMonitoring {
                                 withAnimation(.easeInOut(duration: 0.5)) {
                                     selectedNoiseLevel = autoNoiseLevel
                                 }
                             }
                        }
                        .onReceive(audioMonitor.$normalizedLevel) { level in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedNoiseLevel = autoNoiseLevel
                            }
                            checkForSuggestions(level: level)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onReceive(timer) { _ in
            guard isActive else { return }
            
            // Track noise stats every second
            let level = audioMonitor.normalizedLevel
            cumulativeNoiseLevel += level
            noiseSampleCount += 1
            
            if level > 0.7 {
                totalNoisySeconds += 1
                // Log disruption with debounce (at most once per 30s)
                if let last = lastDisruptionTime {
                    if Date().timeIntervalSince(last) > 30 {
                        noiseDisruptions.append(Date())
                        lastDisruptionTime = Date()
                    }
                } else {
                    noiseDisruptions.append(Date())
                    lastDisruptionTime = Date()
                }
            }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                // Safety check: ensure totalTime is positive to avoid division by zero or NaN
                if totalTime > 0 {
                    progress = CGFloat(max(0, min(1, timeRemaining / totalTime)))
                } else {
                    progress = 0
                }
            } else {
                isActive = false
                progress = 0
                // Session Complete — prompt rating
                if !showRatingSheet {
                    showRatingSheet = true
                }
            }
        }
        .onAppear {
            audioMonitor.startMonitoring()
        }
        .onDisappear {
            audioMonitor.stopMonitoring()
        }
        .sheet(isPresented: $showRatingSheet) {
            SessionRatingSheet(
                pendingRating: $pendingRating,
                onSave: { rating in
                    saveSession(rating: rating)
                    presentationMode.wrappedValue.dismiss()
                },
                onSkip: {
                    presentationMode.wrappedValue.dismiss()
                },
                peachColor: peachColor,
                tealColor: tealColor
            )
        }
        .fullScreenCover(isPresented: $showResults) {
            if let stats = sessionStats {
                SessionResultView(
                    stats: stats,
                    onDisclaimer: {
                        showResults = false
                        presentationMode.wrappedValue.dismiss()
                    },
                    onNewSession: {
                        showResults = false
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    // Formatting Helper
    func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - End Session
    func endSession() {
        isActive = false
        audioMonitor.stopMonitoring()
        
        let elapsed = totalTime - timeRemaining
        let avgNoise: Float = noiseSampleCount > 0 ? cumulativeNoiseLevel / Float(noiseSampleCount) : 0
        let completed = checkpoints.filter { $0.isCompleted }.count
        
        sessionStats = SessionStats(
            totalDuration: elapsed,
            noisyDuration: totalNoisySeconds,
            tasksCompleted: completed,
            totalTasks: checkpoints.count,
            noiseDisruptions: noiseDisruptions,
            averageNoiseLevel: avgNoise
        )
        
        // Save session to history with default 3-star rating
        saveSession(rating: 3)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showResults = true
        }
    }


    
    // MARK: - Smart Suggestions Logic
    // MARK: - Smart Suggestions Logic
    func checkForSuggestions(level: Float) {
        let now = Date()
        guard now.timeIntervalSince(lastSuggestionTime) > 45 else { return } // Increased cooldown
        
        // 1. High Noise (> 0.7)
        if level > 0.7 {
            if noisyTimeStart == nil { noisyTimeStart = now }
            else if let start = noisyTimeStart, now.timeIntervalSince(start) > 10 {
                // Consistent noise > 10s
                let messages = [
                    "It's loud! Try noise-canceling headphones.",
                    "High noise detected. Maybe switch to shallow work?",
                    "Try playing white noise to mask the background."
                ]
                addSuggestion(messages.randomElement()!)
                noisyTimeStart = nil
                lastSuggestionTime = now
            }
            quietTimeStart = nil
        }
        // 2. Quiet (< 0.2)
        else if level < 0.2 {
            if quietTimeStart == nil { quietTimeStart = now }
            else if let start = quietTimeStart, now.timeIntervalSince(start) > 10 {
                // Consistent quiet > 10s
                let messages = [
                    "Perfect silence. Deep Work time!",
                    "Great environment for complex logic.",
                    "Zone in: Try 25 minutes of intense focus."
                ]
                addSuggestion(messages.randomElement()!)
                quietTimeStart = nil
                lastSuggestionTime = now
            }
            noisyTimeStart = nil
        }
        // 3. Balanced (0.2 - 0.7)
        else {
            // Optional: Suggestions for balanced noise?
             if Int.random(in: 0...100) < 2 { // Rare chance
                 addSuggestion("Ambient noise is good for creative flow.")
                 lastSuggestionTime = now
             }
            quietTimeStart = nil
            noisyTimeStart = nil
        }
    }
    
    func addSuggestion(_ text: String) {
        // Update the separate suggestion state instead of the checklist
        withAnimation {
            currentSuggestion = text
        }
    }
    
    func saveSession(rating: Int) {
        let completed = checkpoints.filter { $0.isCompleted }.count
        let record = SessionRecord(
            durationMinutes: durationMinutes,
            completedCheckpoints: completed,
            totalCheckpoints: max(checkpoints.count, 1),
            starRating: rating
        )
        Task { @MainActor in
            SessionStore.shared.addSession(record)
        }
    }
}

// MARK: - Subviews

struct TimerPanel: View {
    let timeRemaining: TimeInterval
    let isActive: Bool
    let progress: CGFloat
    let peachColor: Color
    let audioLevel: Float
    var currentSuggestion: String?
    let onBack: (() -> Void)? // Optional, only for landscape
    
    var body: some View {
        ZStack {
            // Slight gradient background
            LinearGradient(
                colors: [Color.white.opacity(0.02), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack {
                if let onBack = onBack {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.5))
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 30)
                }
                
                
                // Compact Horizontal Stack: Timer + Sine Wave
                HStack(spacing: 20) {
                    // 1. Compact Timer Circle
                    ZStack {
                        // Background Track
                        Circle()
                            .stroke(Color.white.opacity(0.05), lineWidth: 12)
                        
                        // Progress Track
                        Circle()
                            .trim(from: 0.0, to: progress)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [peachColor, peachColor.opacity(0.8)]),
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                            )
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.linear(duration: 1.0), value: progress)
                        
                        // Time Text (Smaller)
                        VStack(spacing: 2) {
                            Text(formatTime(timeRemaining))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                            
                            Text(isActive ? "FOCUS" : "PAUSE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .frame(width: 140, height: 140)
                    .padding(.leading, 20)
                    
                    // 2. Sine Wave Visualization (Takes remaining space)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("LIVE NOISE MONITOR")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(1)
                            .foregroundColor(.white.opacity(0.5))
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                            
                            LiveSoundWave(
                                audioLevel: audioLevel,
                                color: peachColor
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity) // Ensure it takes available space
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 20)
                
                // Suggestion Area (Under Timer/Visualizer)
                if let suggestion = currentSuggestion {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 14))
                            .padding(.top, 2)
                        
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ControlSidebar: View {
    @Binding var checkpoints: [Checkpoint]
    @Binding var selectedNoiseLevel: NoiseLevel
    @Binding var isActive: Bool
    let onDismiss: () -> Void
    let tealColor: Color
    let peachColor: Color
    var isPortrait: Bool = false
    
    var completionPercentage: Double {
        guard !checkpoints.isEmpty else { return 0 }
        let completed = checkpoints.filter { $0.isCompleted }.count
        return Double(completed) / Double(checkpoints.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 30) {
            
            // Completion Progress Indicator
            if !checkpoints.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Text("\(Int(completionPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                            
                            // Fill
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [peachColor, peachColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * completionPercentage)
                                .animation(.easeInOut(duration: 0.5), value: completionPercentage)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.03))
                )
            }
            
            // 1. Environment Wrapper
            VStack(alignment: .leading, spacing: 20) {
                Text("Environment")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                
                HStack(spacing: 10) { // Horizontal in portrait might be better? No, stick to vertical stack for consistency first
                    if isPortrait {
                        // Horizontal scroll for portrait environment to save space?
                        // Or keep vertical stack. Let's keep vertical stack but compact.
                         ScrollView(.horizontal, showsIndicators: false) {
                             HStack(spacing: 12) {
                                 ForEach(NoiseLevel.allCases, id: \.self) { level in
                                     NoiseOptionCompact(
                                        level: level,
                                        isSelected: selectedNoiseLevel == level,
                                        action: { selectedNoiseLevel = level }
                                     )
                                 }
                             }
                         }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(NoiseLevel.allCases, id: \.self) { level in
                                NoiseOption(
                                    level: level,
                                    isSelected: selectedNoiseLevel == level,
                                    action: { selectedNoiseLevel = level }
                                )
                            }
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.05))
            )
            
            // 2. Checkpoints & Suggestions
            VStack(alignment: .leading, spacing: 15) {
                Text("Goals")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                
                // Checkpoint List (No nested ScrollView)
                checkpointList
            }
            .padding(24)
            .frame(maxHeight: isPortrait ? nil : .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.05))
            )
            
                }
                .padding(20)
                .padding(.bottom, 20)
            }
            
            // 3. Playback Controls (Sticky Footer)
            VStack(spacing: 0) {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                HStack(spacing: 12) {
                // Pause/Resume
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isActive.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: isActive ? "pause.fill" : "play.fill")
                            .font(.headline)
                        Text(isActive ? "Pause" : "Resume")
                            .fontWeight(.bold)
                            .font(.subheadline)
                    }
                    .foregroundColor(tealColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(peachColor)
                    .cornerRadius(12)
                    .shadow(color: peachColor.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                // End Session
                Button(action: onDismiss) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.headline)
                        Text("End Session")
                            .fontWeight(.bold)
                            .font(.subheadline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
            }
                .padding(20)
                .padding(.bottom, isPortrait ? 20 : 0)
            }
            .background(Color(hex: "233D4C").opacity(0.95))
        }
    }
    
    var checkpointList: some View {
        VStack(spacing: 10) {
            if checkpoints.isEmpty {
                Text("No specific goals set.")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.white.opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach($checkpoints) { $checkpoint in
                    ToggleableCheckpointRow(checkpoint: $checkpoint, color: peachColor)
                }
            }
        }
    }
}

// MARK: - Models & Components

enum NoiseLevel: String, CaseIterable {
    case quiet
    case balanced
    case noisy
    
    var title: String {
        switch self {
        case .quiet: return "Quieter"
        case .balanced: return "Busier"
        case .noisy: return "Noisy"
        }
    }
    
    var icon: String {
        switch self {
        case .quiet: return "leaf.fill"
        case .balanced: return "person.3.fill"
        case .noisy: return "speaker.wave.3.fill"
        }
    }
}

struct NoiseOption: View {
    let level: NoiseLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: level.icon)
                    .font(.system(size: 18))
                    .frame(width: 24)
                    
                Text(level.title == "Quieter" ? "Quieter Atmosphere" : level.title == "Busier" ? "Busier Environment" : "Ultra Noisy")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.footnote.bold())
                }
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct NoiseOptionCompact: View {
    let level: NoiseLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: level.icon)
                    .font(.title3)
                Text(level.title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

struct ToggleableCheckpointRow: View {
    @Binding var checkpoint: Checkpoint
    let color: Color
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                checkpoint.isCompleted.toggle()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: checkpoint.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(checkpoint.isCompleted ? color : .white.opacity(0.3))
                    .font(.title3)
                
                Text(checkpoint.title)
                    .font(.body)
                    .foregroundColor(checkpoint.isCompleted ? .white.opacity(0.4) : .white.opacity(0.9))
                    .strikethrough(checkpoint.isCompleted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Noise Level Indicator

struct NoiseLevelIndicator: View {
    let audioLevel: Float
    let peachColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Label
            HStack {
                Text("LIVE NOISE LEVEL")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Text("\(Int(audioLevel * 100))%")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Horizontal Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)
                    
                    // Active Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [peachColor, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(12, geo.size.width * CGFloat(audioLevel)), height: 12)
                        .animation(.linear(duration: 0.1), value: audioLevel)
                        .shadow(color: peachColor.opacity(0.5), radius: 6, x: 0, y: 0)
                }
            }
            .frame(height: 12)
        }
    }
}



// Extension for partial Corner Radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimerView(durationMinutes: 25, checkpoints: [
                Checkpoint(title: "Read Chapter 1"),
                Checkpoint(title: "Take Notes")
            ])
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("Landscape")
            
            TimerView(durationMinutes: 25, checkpoints: [
                Checkpoint(title: "Read Chapter 1"),
                Checkpoint(title: "Take Notes")
            ])
            .previewInterfaceOrientation(.portrait)
            .previewDisplayName("Portrait")
        }
    }
}
