import Foundation
import AVFoundation
import Combine

@MainActor
class AudioMonitor: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var monitorTask: Task<Void, Never>?
    
    // Published properties for UI binding
    @Published var decibels: Float = -160.0
    @Published var normalizedLevel: Float = 0.0
    @Published var isMonitoring = false
    @Published var permissionGranted = false
    
    init() {
        // Defer setup to startMonitoring
    }
    
    func startMonitoring() {
        if isMonitoring { return }
        
        let status = AVAudioSession.sharedInstance().recordPermission
        
        switch status {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
                Task { @MainActor [weak self] in
                    self?.permissionGranted = allowed
                    if allowed {
                        self?.setupAndRecord()
                    }
                }
            }
        case .granted:
            permissionGranted = true
            setupAndRecord()
        case .denied:
            permissionGranted = false
            print("Microphone permission denied")
        @unknown default:
            break
        }
    }
    
    private func setupAndRecord() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true)
            
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("temp_audio_monitor.caf")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatAppleLossless),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isMonitoring = true
            startMeteringTask()
            
        } catch {
            print("Audio Monitor Setup Error: \(error.localizedDescription)")
        }
    }
    
    private func startMeteringTask() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { return }
                
                // Update meters
                self.audioRecorder?.updateMeters()
                let power = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
                
                // Ensure UI updates happen on the MainActor
                await MainActor.run {
                    self.decibels = power
                    self.normalizedLevel = self.normalize(power: power)
                }
                
                // Sleep for 0.1s
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }
    
    func stopMonitoring() {
        audioRecorder?.stop()
        monitorTask?.cancel()
        monitorTask = nil
        isMonitoring = false
        
        // Deactivate session to be good citizens
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func normalize(power: Float) -> Float {
        // Typical speech/room noise range: -60dB (quiet) to 0dB (loud)
        let minDb: Float = -60.0
        if power < minDb { return 0.0 }
        if power >= 0.0 { return 1.0 }
        return (power - minDb) / abs(minDb)
    }
    
    deinit {
        // Cleanup
    }
}
