import SwiftUI

struct IntroAnimationView: View {
    // Brand Colors
    let tealColor = Color(hex: "233D4C")
    let peachColor = Color(hex: "FD802E")
    
    @State private var particles: [Particle] = []
    @State private var ringProgress: CGFloat = 0.0
    @State private var showGlow: Bool = false
    @State private var showTitle: Bool = false
    @State private var showStartButton: Bool = false
    @State private var showLogo: Bool = false
    @State private var time: TimeInterval = 0
    
    let particleCount = 70
    let ringRadius: CGFloat = 100
    
    // Timer for constant updates (approx 60fps)
    let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                tealColor.ignoresSafeArea()
                
                Canvas { context, size in
                    // Draw Particles
                    for particle in particles {
                        let particleRect = CGRect(
                            x: particle.position.x - particle.size / 2,
                            y: particle.position.y - particle.size / 2,
                            width: particle.size,
                            height: particle.size
                        )
                        
                        // varying opacity based on time to twinkle slightly
                        let opacity = 0.6 + sin(time * particle.speedFactor) * 0.3
                        
                        context.opacity = opacity
                        context.fill(Path(ellipseIn: particleRect), with: .color(peachColor))
                    }
                }
                .onAppear {
                    if particles.isEmpty {
                        initializeParticles(in: geometry.size)
                    }
                }
                
                // Ring
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(peachColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: ringRadius * 2, height: ringRadius * 2)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 2.0), value: ringProgress)
                
                // Central Glow
                if showGlow {
                    Circle()
                        .fill(peachColor)
                        .frame(width: ringRadius * 1.5, height: ringRadius * 1.5)
                        .blur(radius: 40)
                        .opacity(0.4)
                        .transition(.opacity)
                }
                
                // Logo Image - Replaces Glow or sits on top
                if showLogo {
                    Image("Logo_Final")
                        .resizable()
                        .scaledToFit()
                        .frame(width: ringRadius * 1.85, height: ringRadius * 1.85) // Larger size fitting ring
                        .transition(.opacity.animation(.easeIn(duration: 1.0)))
                }
                
                // Title and UI
                VStack {
                    Spacer()
                    // Spacer helps push content down, but we want precise control relative to center
                    // We can use a fixed spacing from the center or just more padding
                }
                
                // Overlay tailored for positioning
                VStack(spacing: 20) {
                    Spacer()
                    
                    if showTitle {
                        Text("QuietRadius")
                            .font(.largeTitle)
                            .fontWeight(.light)
                            .foregroundColor(peachColor)
                            // Move it significantly down to avoid overlap with center ring (radius 100)
                            // Center Y is roughly screen height / 2
                            // We need to be below center + 100 + spacing
                            .padding(.top, 250) // Increased padding to ensure it's below circle
                            .transition(.opacity)
                    }
                    
                    if showStartButton {
                        NavigationLink(destination: DashboardView()) {
                            Text("Start")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(tealColor)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(peachColor)
                                .cornerRadius(12)
                                .padding(.horizontal, 40)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.bottom, 50) // Push button up from bottom edge
                        .transition(.opacity)
                    }
                }
            }
            .onReceive(timer) { date in
                time = date.timeIntervalSinceReferenceDate
                updateParticles(in: geometry.size)
            }
            .onAppear {
                startAnimationSequence()
            }
        }
    }
    
    // ... Initialize Particles and Update Particles functions remain same ...
    func initializeParticles(in size: CGSize) {
        particles = []
        for _ in 0..<particleCount {
            let p = Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                velocity: CGVector(
                    dx: Double.random(in: -2.0...2.0),
                    dy: Double.random(in: -2.0...2.0)
                ),
                size: CGFloat.random(in: 3...6),
                speedFactor: Double.random(in: 1...3)
            )
            particles.append(p)
        }
    }
    
    func updateParticles(in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        for i in particles.indices {
            var particle = particles[i]
            
            particle.position.x += particle.velocity.dx
            particle.position.y += particle.velocity.dy
            
            if particle.position.x < 0 || particle.position.x > size.width { particle.velocity.dx *= -1 }
            if particle.position.y < 0 || particle.position.y > size.height { particle.velocity.dy *= -1 }
            
            let distance = hypot(particle.position.x - center.x, particle.position.y - center.y)
            
            if ringProgress >= 1.0 {
                if distance < ringRadius {
                    particle.velocity.dx *= 0.90
                    particle.velocity.dy *= 0.90
                    particle.velocity.dx += Double.random(in: -0.02...0.02)
                    particle.velocity.dy += Double.random(in: -0.02...0.02)
                } else {
                    if abs(particle.velocity.dx) < 0.2 { particle.velocity.dx *= 1.1 }
                    if abs(particle.velocity.dy) < 0.2 { particle.velocity.dy *= 1.1 }
                }
            }
            particles[i] = particle
        }
    }
    
    func startAnimationSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 2.0)) { ringProgress = 1.0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeIn(duration: 1.0)) { 
                showGlow = true 
                showLogo = true // Reveal logo with glow
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeIn(duration: 1.0)) { showTitle = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeIn(duration: 0.5)) { showStartButton = true }
        }
    }
}

struct Particle {
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var speedFactor: Double
}

struct IntroAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        IntroAnimationView()
    }
}


