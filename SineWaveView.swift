import SwiftUI

struct SineWaveView: View {
    // Amplitude (0.0 to 1.0)
    var amplitude: Double
    var frequency: Double = 5.0
    var phase: Double
    var color: Color
    
    var body: some View {
        GeometryReader { geo in
            let midHeight = geo.size.height / 2
            let width = geo.size.width
            let wavelength = width / frequency
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                for x in stride(from: 0, to: width, by: 1) {
                    let relativeX = x / wavelength
                    let sine = sin(relativeX * 2 * .pi + phase)
                    let y = midHeight + (sine * (amplitude * midHeight * 0.8)) // Max amplitude 80% of half height
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, lineWidth: 2)
            .shadow(color: color.opacity(0.6), radius: 4, x: 0, y: 0)
        }
    }
}

struct LiveSineWave: View {
    var audioLevel: Float // 0.0 to 1.0
    var color: Color
    
    @State private var phase: Double = 0.0
    
    var body: some View {
        SineWaveView(
            amplitude: Double(max(0.05, audioLevel)), // Minimum subtle movement
            phase: phase,
            color: color
        )
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}
