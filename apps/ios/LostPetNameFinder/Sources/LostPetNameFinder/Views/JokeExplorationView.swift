import SwiftUI

public struct JokeExplorationView: View {
    @EnvironmentObject var client: APIClient
    @Environment(\.dismiss) var dismiss
    
    @State private var currentIndex = 0
    @State private var smileScore: Double = 0.1
    @State private var laughScore: Double = 0.0
    @State private var isSpeechPlaying = false
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    @State private var navigateToResult = false
    @State private var showExitAlert = false
    
    public init() {}

    public var body: some View {
        ZStack {
            // Camera Preview / Mock Screen Background
            Color.black
                .ignoresSafeArea()
            
            // Mock Front Camera View
            VStack {
                Spacer()
                Image(systemName: "person.fill.viewfinder")
                    .font(.system(size: 120))
                    .foregroundStyle(.white.opacity(0.15))
                Text("フロントカメラ有効 (笑顔検出稼働中)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
            }
            
            // Frosted Glass Overlays (NeXT/HIG blend)
            VStack(spacing: 24) {
                // Header Details
                HStack {
                    Button {
                        showExitAlert = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    if let session = client.currentJokeSession {
                        Text("\(currentIndex + 1) / \(client.jokeCandidates.count)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Image(systemName: client.isOffline ? "wifi.slash" : "wifi")
                        .foregroundStyle(client.isOffline ? .orange : .green)
                        .padding(12)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                Spacer()
                
                // Candidate Name Panel (Main attraction)
                if !client.jokeCandidates.isEmpty && currentIndex < client.jokeCandidates.count {
                    let currentCand = client.jokeCandidates[currentIndex]
                    
                    VStack(spacing: 20) {
                        Text("呼びかけ中...")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .textCase(.uppercase)
                        
                        Text(currentCand.name)
                            .font(.system(size: 48, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .scaleEffect(isSpeechPlaying ? 1.1 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: isSpeechPlaying)
                        
                        // Speech Playback Button
                        Button {
                            playTTS(text: currentCand.name)
                        } label: {
                            Image(systemName: isSpeechPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(isSpeechPlaying ? Color.systemOrange : .white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.1, green: 0.12, blue: 0.18).opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal)
                } else {
                    // Empty state or Loading
                    ProgressView()
                        .tint(.white)
                }
                
                Spacer()
                
                // Indicators & Action Panel
                VStack(spacing: 20) {
                    // Smile Score Indicator (Heuristics meter)
                    VStack(spacing: 8) {
                        HStack {
                            Text("笑顔の反応強度")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            Spacer()
                            Text("\(Int(smileScore * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        
                        // Progress bar with color shift (pink to gold)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.white.opacity(0.15))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.pink, Color.systemOrange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(smileScore), height: 8)
                                    .animation(.easeOut(duration: 0.2), value: smileScore)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 24)
                    
                    // Manual Reaction Input Buttons (Thumb size friendly)
                    HStack(spacing: 16) {
                        // Unamused
                        Button {
                            submitReaction(manualReaction: "reaction_no")
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "face.dashed")
                                    .font(.title2)
                                Text("無反応")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(.white.opacity(0.1))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Meh / Soft Smile
                        Button {
                            submitReaction(manualReaction: "reaction_meh")
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "face.smiling")
                                    .font(.title2)
                                Text("ニヤリ")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(.white.opacity(0.15))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Laugh / Great
                        Button {
                            submitReaction(manualReaction: "reaction_yes")
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "face.smiling.fill")
                                    .font(.title2)
                                    .foregroundStyle(.yellow)
                                Text("大ウケ")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.95, green: 0.6, blue: 0.1))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(timer) { _ in
            simulateSmileMeter()
        }
        .onAppear {
            if !client.jokeCandidates.isEmpty {
                playTTS(text: client.jokeCandidates[currentIndex].name)
            }
        }
        .alert("探索を終了しますか？", isPresented: $showExitAlert) {
            Button("終了する", role: .destructive) {
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("現在のジョークセッションの進行状況は破棄されます。")
        }
        .navigationDestination(isPresented: $navigateToResult) {
            JokeResultView()
        }
    }
    
    private func simulateSmileMeter() {
        // 顔の笑顔の追跡を模して、スコアをランダムに小刻みに変動させる
        // 音声が再生されている間や、笑顔度の初期状態に応じた Heuristics
        let delta = Double.random(in: -0.05...0.06)
        smileScore = max(0.02, min(0.98, smileScore + delta))
    }
    
    private func playTTS(text: String) {
        isSpeechPlaying = true
        // iOS標準の SpeechSynthesizer を用いた簡易的な自動音声読み上げ
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: client.selectedLanguageCode)
        utterance.rate = 0.45
        
        // 再生モックの視覚効果用タイマー
        Task {
            synthesizer.speak(utterance)
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            isSpeechPlaying = false
        }
    }
    
    private func submitReaction(manualReaction: String) {
        guard let session = client.currentJokeSession else { return }
        
        // ウケリアクションを記録
        let candidateId = client.jokeCandidates[currentIndex].joke_profile_id
        
        // 笑顔シミュレータの値をスコアとしてバインド
        let smile = smileScore
        let laugh = Double.random(in: 0.0...0.2) // 笑い声の簡易モック
        
        Task {
            await client.recordJokeReaction(
                jokeSessionId: session.joke_session_id,
                candidateId: candidateId,
                smileScore: smile,
                laughScore: laugh,
                reaction: manualReaction
            )
            
            // 次の候補へ進む
            if currentIndex + 1 < client.jokeCandidates.count {
                currentIndex += 1
                smileScore = 0.1 // 笑顔計のリセット
                playTTS(text: client.jokeCandidates[currentIndex].name)
            } else {
                // すべて終了したら結果の集計・完了
                timer.upstream.connect().cancel()
                navigateToResult = true
            }
        }
    }
}

// iOS用のカラーヘルパー定義
extension Color {
    static let systemOrange = Color(red: 0.95, green: 0.6, blue: 0.1)
}

// AVSpeechSynthesizerを使うためのインポート
import AVFoundation
