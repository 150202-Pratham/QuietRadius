import SwiftUI

struct SoundWaveView: View {
    // Amplitude (0.0 to 1.0)
    var amplitude: Double
    var color: Color
    
    // Random seeds for bar heights to make it look organic
    let barCount = 20
    @State private var barHeights: [CGFloat] = Array(repeating: 0.1, count: 20)
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let spacing: CGFloat = 4
            let barWidth = (width - (spacing * CGFloat(barCount - 1))) / CGFloat(barCount)
            
            HStack(spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: max(2, barWidth))
                        .frame(height: max(4, height * barHeights[index] * CGFloat(max(0.2, amplitude))))
                        .animation(.easeInOut(duration: 0.1), value: amplitude)
                }
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            // Update bar heights randomly based on amplitude
            withAnimation(.easeInOut(duration: 0.1)) {
                barHeights = (0..<barCount).map { _ in
                    CGFloat.random(in: 0.3...1.0)
                }
            }
        }
    }
}

struct LiveSoundWave: View {
    var audioLevel: Float // 0.0 to 1.0
    var color: Color
    
    var body: some View {
        SoundWaveView(
            amplitude: Double(audioLevel),
            color: color
        )
    }
}
