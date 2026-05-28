import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct JokeResultView: View {
    @EnvironmentObject var client: APIClient
    @State private var jokeResult: JokeResult? = nil
    @State private var navigateToHome = false
    @State private var isLoadingResult = true
    
    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 0.98)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isLoadingResult {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color(red: 0.95, green: 0.6, blue: 0.1))
                        Text("結果を集計中...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if let result = jokeResult {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            
                            // Warning / Disclaimer Banner
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(Color(red: 0.95, green: 0.6, blue: 0.1))
                                    Text("ジョーク結果（娯楽用途）")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                                }
                                Text("※本結果は人間向けのジョーク・娯楽用であり、人物の特定、正解、または属性の確定を行うものではありません。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .padding(.top, 16)

                            // Result Card Section (Premium Card Design)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ジョーク結果カード")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                
                                // Local or Network Card Preview
                                if let cardImage = getCardBaseImage() {
                                    JokeCardView(
                                        image: cardImage,
                                        bestName: result.top_candidates.first?.name ?? "無し",
                                        score: result.top_candidates.first?.composite_score ?? 0.0,
                                        sessionId: result.joke_session_id
                                    )
                                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
                                    .frame(maxWidth: .infinity)
                                }
                            }

                            // Reaction Rankings (NeXT Bezel List)
                            VStack(alignment: .leading, spacing: 16) {
                                Text("ウケた雰囲気候補ランキング")
                                    .font(.headline)
                                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                                
                                VStack(spacing: 12) {
                                    ForEach(Array(result.top_candidates.enumerated()), id: \.offset) { index, item in
                                        HStack(spacing: 16) {
                                            // Rank Badge
                                            Text("\(index + 1)")
                                                .font(.system(.title3, design: .monospaced))
                                                .fontWeight(.bold)
                                                .foregroundStyle(index == 0 ? Color(red: 0.95, green: 0.6, blue: 0.1) : .secondary)
                                                .frame(width: 24)

                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(item.name)
                                                    .font(.headline)
                                                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))

                                                // Progress bar representing score (参考スコア)
                                                GeometryReader { geo in
                                                    ZStack(alignment: .leading) {
                                                        Capsule()
                                                            .frame(height: 6)
                                                            .foregroundStyle(Color(red: 0.9, green: 0.92, blue: 0.96))
                                                        Capsule()
                                                            .frame(width: geo.size.width * CGFloat(item.composite_score), height: 6)
                                                            .foregroundStyle(Color(red: 0.95, green: 0.6, blue: 0.1))
                                                    }
                                                }
                                                .frame(height: 6)
                                            }

                                            Spacer()

                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(String(format: "%.0f%%", item.composite_score * 100))
                                                    .font(.system(.subheadline, design: .monospaced))
                                                    .fontWeight(.bold)
                                                Text("参考スコア")
                                                    .font(.system(size: 8))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        }
                    }
                    
                    // Bottom Action Panel
                    VStack(spacing: 12) {
                        // Share Card Button
                        Button {
                            triggerShareSheet()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("結果カード画像を共有する")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .minHeightTapTarget()
                            .background(Color.white)
                            .foregroundStyle(Color(red: 0.95, green: 0.6, blue: 0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.95, green: 0.6, blue: 0.1), lineWidth: 1.5)
                            )
                        }
                        .padding(.horizontal, 16)

                        // Return to Home
                        Button {
                            navigateToHome = true
                        } label: {
                            Text("ホームに戻る")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .minHeightTapTarget()
                                .background(Color(red: 0.95, green: 0.6, blue: 0.1))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(Color(red: 0.86, green: 0.89, blue: 0.94)),
                        alignment: .top
                    )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.red)
                        Text("結果の取得に失敗しました")
                            .font(.headline)
                        Button {
                            Task {
                                await loadResults()
                            }
                        } label: {
                            Text("再試行")
                                .fontWeight(.bold)
                                .padding()
                                .background(Color(red: 0.95, green: 0.6, blue: 0.1))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .minHeightTapTarget()
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            Task {
                await loadResults()
            }
        }
        .navigationDestination(isPresented: $navigateToHome) {
            HomeView()
        }
    }
    
    private func getCardBaseImage() -> PlatformImage? {
        if let data = client.lastUploadedJokeImageData {
            return PlatformImage(data: data)
        }
        #if canImport(UIKit)
        return UIImage(systemName: "person.crop.rectangle.fill")
        #elseif canImport(AppKit)
        return NSImage(systemSymbolName: "person.crop.rectangle.fill", accessibilityDescription: nil)
        #else
        return nil
        #endif
    }
    
    private func loadResults() async {
        guard let session = client.currentJokeSession else {
            isLoadingResult = false
            return
        }
        isLoadingResult = true
        let result = await client.fetchJokeResults(jokeSessionId: session.joke_session_id)
        if let res = result {
            self.jokeResult = res
        }
        isLoadingResult = false
    }
    
    @MainActor
    private func renderJokeCardToImage() -> PlatformImage? {
        guard let result = jokeResult, let cardImage = getCardBaseImage() else { return nil }
        let card = JokeCardView(
            image: cardImage,
            bestName: result.top_candidates.first?.name ?? "無し",
            score: result.top_candidates.first?.composite_score ?? 0.0,
            sessionId: result.joke_session_id
        )
        // ImageRenderer for high-quality dynamic rendering
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0 // Match retina screens
        
        #if canImport(UIKit)
        return renderer.uiImage
        #elseif canImport(AppKit)
        return renderer.nsImage
        #else
        return nil
        #endif
    }
    
    private func triggerShareSheet() {
        Task { @MainActor in
            guard let image = renderJokeCardToImage() else {
                print("Failed to render joke card image.")
                return
            }
            
            #if canImport(UIKit)
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                print("Failed to access rootViewController for sharing.")
                return
            }
            
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            
            // iPad popover support
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true, completion: nil)
            #else
            print("--- [SHARE REPORT (Console Fallback)] ---")
            print("Successfully rendered result card image of size \(image.size)")
            print("-----------------------------------------")
            #endif
        }
    }
}

// Premium Card View to be Rendered
struct JokeCardView: View {
    let image: PlatformImage
    let bestName: String
    let score: Double
    let sessionId: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Profile Image with circular border
                Image(platformImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.95, green: 0.6, blue: 0.1).opacity(0.6), lineWidth: 2)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("最優秀ジョーク候補")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 0.95, green: 0.6, blue: 0.1))
                        .textCase(.uppercase)
                    
                    Text(bestName)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("雰囲気参考スコア:")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(Int(score * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(.yellow)
                    }
                }
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Orpheus Echo - Joke Mode Result")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("ID: \(sessionId)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                
                // Mock stamp/seal
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(red: 0.95, green: 0.6, blue: 0.1).opacity(0.8))
            }
        }
        .padding(16)
        .frame(width: 320, height: 180)
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.14, blue: 0.22), Color(red: 0.08, green: 0.09, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.6, blue: 0.1), Color.yellow.opacity(0.5), Color(red: 0.95, green: 0.6, blue: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
    }
}
