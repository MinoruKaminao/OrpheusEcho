import SwiftUI

public struct ExplorationView: View {
    @EnvironmentObject var client: APIClient
    @State private var currentIndex = 0
    @State private var navigateToRanking = false
    
    // カメラのパーミッション状態モック
    @State private var isCameraAuthorized = true
    @State private var isMuted = false
    
    // Phase 8: 屋外環境騒音測定と動的TTS
    @State private var noiseMonitor = NoiseMonitor()
    @State private var currentNoiseDb: Double = 40.0
    @State private var isSpeechPlaying = false
    @State private var isMeasuringNoise = false

    public init() {}

    public var body: some View {
        ZStack {
            // Background: Camera Preview Mock or Silhouette
            if isCameraAuthorized {
                Color(red: 0.1, green: 0.12, blue: 0.15)
                    .ignoresSafeArea()
                
                // カメラ映像のプレースホルダ（PWA/Mobileポリシー準拠のオーバーレイ）
                VStack {
                    Spacer()
                    Image(systemName: "video.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.15))
                    Text("カメラ映像プレビュー（モック）")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                }
            } else {
                Color(red: 0.2, green: 0.22, blue: 0.25)
                    .ignoresSafeArea()
                VStack(spacing: 12) {
                    Image(systemName: "camera.metering.unknown")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("カメラが利用できません")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("設定でカメラ権限を許可してください")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Top Status Overlay
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.currentSession?.species == .dog ? "探索対象: 犬" : "探索対象: 猫")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("Session: \(client.currentSession?.session_id ?? "未設定")")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    
                    // Offline Indicator
                    if client.isOffline {
                        HStack(spacing: 4) {
                            Circle().frame(width: 8, height: 8).foregroundStyle(.orange)
                            Text("オフライン")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                    }
                }
                .padding()
                .background(.black.opacity(0.4))
                
                Spacer()
            }

            // Center Panel: Current candidate name player (Frosted Glass influence)
            VStack {
                Spacer()
                
                if !client.candidates.isEmpty {
                    let currentCand = client.candidates[currentIndex]
                    
                    VStack(spacing: 16) {
                        Text("呼びかけ呼称候補")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.7))
                            .textCase(.uppercase)

                        Text(currentCand.name)
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)

                        // TTS Audio Playback Button
                        Button {
                            playTTS(text: currentCand.name)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isSpeechPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.circle.fill")
                                Text(isMeasuringNoise ? "騒音測定中..." : (isSpeechPlaying ? "再生中..." : "音声を再生"))
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(isSpeechPlaying ? Color.orange : Color(red: 0.18, green: 0.42, blue: 1.0))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                        .disabled(isSpeechPlaying || isMeasuringNoise)
                        .minHeightTapTarget()
                        
                        // AI特徴量（推定動作マーカー）表示エリア
                        if let features = client.lastFeatures {
                            VStack(spacing: 6) {
                                Text("推定動作マーカー (AI解析値)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.6))
                                
                                HStack(spacing: 12) {
                                    VStack {
                                        Text("視線移動")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.white.opacity(0.5))
                                        Text(String(format: "%.2f", features.gaze_shift_score))
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundStyle(.white)
                                    }
                                    VStack {
                                        Text("頭の回転")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.white.opacity(0.5))
                                        Text(String(format: "%.2f", features.head_turn_score))
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundStyle(.white)
                                    }
                                    VStack {
                                        Text("耳の動き")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.white.opacity(0.5))
                                        Text(String(format: "%.2f", features.ear_motion_score))
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundStyle(.white)
                                    }
                                    VStack {
                                        Text("接近度")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.white.opacity(0.5))
                                        Text(String(format: "%.2f", features.approach_score))
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundStyle(.white)
                                    }
                                    VStack {
                                        Text("周囲の騒音")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.white.opacity(0.5))
                                        Text(String(format: "%.1f dB", currentNoiseDb))
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundStyle(currentNoiseDb > 60.0 ? .orange : .green)
                                    }
                                }
                                .padding(8)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal, 32)
                }

                Spacer()
            }

            // Bottom Action Control Panel (Reaction Buttons)
            VStack {
                Spacer()

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Reaction: None
                        Button {
                            recordReaction("reaction_no")
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                Text("反応なし")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.15))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .minHeightTapTarget()

                        // Reaction: Weak
                        Button {
                            recordReaction("reaction_weak")
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.title2)
                                Text("反応弱い")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.25))
                            .foregroundStyle(.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .minHeightTapTarget()

                        // Reaction: Yes
                        Button {
                            recordReaction("reaction_yes")
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                Text("反応あり")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.18, green: 0.42, blue: 1.0))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .minHeightTapTarget()
                    }
                    .padding(.horizontal, 16)

                    // Session Finish button
                    Button {
                        navigateToRanking = true
                    } label: {
                        Text("探索を完了して結果を見る")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .minHeightTapTarget()
                            .background(Color.white)
                            .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                }
                .background(Color.black.opacity(0.75))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(.white.opacity(0.15)),
                    alignment: .top
                )
            }
        }
        .navigationBarBackButtonHidden()
        .navigationDestination(isPresented: $navigateToRanking) {
            CandidateRankingView()
        }
        .onAppear {
            Task {
                await client.fetchCandidates(species: client.currentSession?.species ?? .dog)
            }
        }
    }

    private func recordReaction(_ reaction: String) {
        guard !client.candidates.isEmpty else { return }
        let currentCand = client.candidates[currentIndex]
        
        Task {
            await client.recordTrial(
                candidateId: currentCand.candidate_id,
                name: currentCand.name,
                reaction: reaction,
                ambientNoiseDb: currentNoiseDb
            )
            
            // 次の候補へ
            if currentIndex < client.candidates.count - 1 {
                currentIndex += 1
            } else {
                // 最後まで到達したらランキングへ
                navigateToRanking = true
            }
        }
    }
    
    private func playTTS(text: String) {
        isSpeechPlaying = true
        isMeasuringNoise = true
        
        Task {
            // 再生直前に騒音レベルを計測 (0.6 秒)
            let db = await noiseMonitor.measureAmbientNoise(duration: 0.6)
            self.currentNoiseDb = db
            self.isMeasuringNoise = false
            
            let synthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: client.selectedLanguageCode)
            
            // 環境音による動的最適化
            if db < 45.0 {
                // 静かな環境
                utterance.volume = 0.6
                utterance.pitchMultiplier = 1.0
                utterance.rate = 0.5
            } else if db <= 60.0 {
                // 通常の屋外環境
                utterance.volume = 0.85
                utterance.pitchMultiplier = 1.0
                utterance.rate = 0.45
            } else {
                // 騒音の大きい環境 (高音にし、聞き取りやすいようハッキリ発音)
                utterance.volume = 1.0
                utterance.pitchMultiplier = 1.15
                utterance.rate = 0.4
            }
            
            synthesizer.speak(utterance)
            
            // 再生模擬
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            isSpeechPlaying = false
        }
    }
}

// ダミー音声再生クラス
class NSSoundMock {
    static func play() {
        // 音声を再生するダミーロジック
    }
}
import AVFoundation
