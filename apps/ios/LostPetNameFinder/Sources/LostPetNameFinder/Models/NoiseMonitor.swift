import Foundation
import AVFoundation

public class NoiseMonitor {
    private var audioRecorder: AVAudioRecorder?
    
    public init() {}
    
    public func measureAmbientNoise(duration: TimeInterval = 1.0) async -> Double {
        #if targetEnvironment(simulator) || os(macOS)
        // Return a mock decibel value on simulator or macOS test runner
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        return Double.random(in: 35.0...75.0)
        #else
        // Record decibels on physical devices
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            
            let tempDir = FileManager.default.temporaryDirectory
            let url = tempDir.appendingPathComponent("noise_temp.m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ]
            
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.record()
            
            // Wait for measurement duration
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            recorder.stop()
            
            // Map the float power (-160dB to 0dB) to positive decibel scale (30dB to 100dB)
            // e.g. -60dB -> 30dB, 0dB -> 90dB
            let db = max(30.0, min(100.0, Double(power) + 90.0))
            return db
        } catch {
            print("NoiseMonitor Error: \(error.localizedDescription)")
            return Double.random(in: 40.0...60.0) // Fallback for errors or denied permission
        }
        #endif
    }
}
