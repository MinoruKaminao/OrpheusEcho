import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct ResultDetailView: View {
    @EnvironmentObject var client: APIClient
    @State private var navigateToHome = false
    
    // Privacy and Sharing state
    @State private var showShareConfirmation = false
    @State private var shareIncludeLocation = false
    @State private var shareIncludeMedia = false
    @State private var shareIncludeNotes = false
    
    // Consent status
    @State private var consentForTraining = false

    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("探索セッション結果サマリ")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                            .padding(.top, 16)

                        // Info card
                        VStack(spacing: 12) {
                            HStack {
                                Text("セッションID")
                                    .font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text(client.currentSession?.session_id ?? "未設定")
                                    .font(.system(.caption, design: .monospaced))
                            }
                            Divider()
                            HStack {
                                Text("ステータス")
                                    .font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text("保存完了")
                                    .font(.caption).fontWeight(.bold).foregroundStyle(.green)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                        )

                        // Top ranked list summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("有力呼称候補")
                                .font(.headline)
                            
                            ForEach(client.rankedCandidates.prefix(3)) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(item.name)
                                            .font(.subheadline).fontWeight(.bold)
                                        
                                        if let confidence = item.confidence {
                                            Text(confidence == "high" ? "高信頼" : confidence == "medium" ? "中信頼" : "要追試")
                                                .font(.system(size: 8, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(confidence == "high" ? Color.green.opacity(0.15) : confidence == "medium" ? Color.orange.opacity(0.15) : Color.gray.opacity(0.15))
                                                .foregroundColor(confidence == "high" ? .green : confidence == "medium" ? .orange : .gray)
                                                .clipShape(Capsule())
                                        }
                                        
                                        Spacer()
                                        
                                        Text(String(format: "%.2f", item.score))
                                            .font(.system(.subheadline, design: .monospaced))
                                        Text("参考スコア")
                                            .font(.system(size: 8)).foregroundStyle(.secondary)
                                    }
                                    
                                    if let explanation = item.explanation, !explanation.isEmpty {
                                        Text(explanation)
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                        )

                        // Consent toggle (AI/ML training agreement)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("データ提供とプライバシー")
                                .font(.headline)
                            
                            Toggle(isOn: $consentForTraining) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI推定精度の向上のためデータを提供する")
                                        .font(.subheadline).fontWeight(.semibold)
                                    Text("探索ログ（呼びかけ音声の反応情報）をモデル改善用に匿名の教師データとして提供することに同意します。いつでも設定から撤回できます。")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .tint(Color(red: 0.18, green: 0.42, blue: 1.0))
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                }

                // Bottom Action buttons
                VStack(spacing: 12) {
                    Button {
                        showShareConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("探索レポートを共有・出力")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .minHeightTapTarget()
                        .background(Color.white)
                        .foregroundStyle(Color(red: 0.18, green: 0.42, blue: 1.0))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.18, green: 0.42, blue: 1.0), lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal, 16)

                    Button {
                        Task {
                            await client.closeSession()
                            navigateToHome = true
                        }
                    } label: {
                        Text("ホームに戻る")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .minHeightTapTarget()
                            .background(Color(red: 0.18, green: 0.42, blue: 1.0))
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
            }
        }
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showShareConfirmation) {
            // セキュリティ／プライバシー確認シート（オプトイン）
            NavigationStack {
                VStack(alignment: .leading, spacing: 20) {
                    Text("共有データのプライバシー確認")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("レポートを外部に共有する前に、含める項目をオプトインで選択してください。選択しない項目は自動的にマスクされます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 12) {
                        Toggle("位置情報を含める", isOn: $shareIncludeLocation)
                        Toggle("メディア（動画・音声）を含める", isOn: $shareIncludeMedia)
                        Toggle("個体備考メモを含める", isOn: $shareIncludeNotes)
                    }
                    .tint(Color(red: 0.18, green: 0.42, blue: 1.0))
                    
                    Spacer()
                    
                    Button {
                        showShareConfirmation = false
                        // 共有シートの呼び出しなど
                        triggerShareSheet()
                    } label: {
                        Text("この設定で共有する")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .minHeightTapTarget()
                            .background(Color(red: 0.18, green: 0.42, blue: 1.0))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.bottom)
                }
                .padding()
            }
            .presentationDetents([.medium])
        }
        .navigationDestination(isPresented: $navigateToHome) {
            HomeView()
        }
    }
    
    private func triggerShareSheet() {
        let text = client.exportShareText(
            includeLocation: shareIncludeLocation,
            includeMedia: shareIncludeMedia,
            includeNotes: shareIncludeNotes
        )
        
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            print("Failed to access rootViewController for sharing.")
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        // Support iPad popovers
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootVC.present(activityVC, animated: true, completion: nil)
        #else
        print("--- [SHARE REPORT (Console Fallback)] ---")
        print(text)
        print("-----------------------------------------")
        #endif
    }
}
