import SwiftUI

public struct HomeView: View {
    @EnvironmentObject var client: MockAPIClient
    @State private var navigateToSelection = false
    @State private var navigateToHistory = false
    @State private var navigateToSettings = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.97, blue: 0.98)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header (Brand Identity)
                    VStack(spacing: 8) {
                        Text("Orpheus Echo")
                            .font(.system(.title, design: .serif))
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))

                        Text("推定呼称探索支援アプリ")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    Spacer()

                    // Main Action Cards
                    VStack(spacing: 16) {
                        Button {
                            navigateToSelection = true
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("新規探索セッション")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text("一般的な名前の呼びかけを開始")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .minHeightTapTarget()
                            .background(Color(red: 0.18, green: 0.42, blue: 1.0))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        }

                        Button {
                            navigateToHistory = true
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.2.circlepath")
                                    .font(.title)
                                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("履歴を見る")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                                    Text("過去の有力呼称候補ログを確認")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .minHeightTapTarget()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                            )
                        }

                        Button {
                            navigateToSettings = true
                        } label: {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                    .font(.title)
                                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("設定")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                                    Text("TTS音声、プライバシー、同期管理")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .minHeightTapTarget()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    // Disclaimer text
                    Text("本システムは呼称の推定を支援する補助ツールであり、特定を保証するものではありません。")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                }
            }
            .navigationDestination(isPresented: $navigateToSelection) {
                SpeciesSelectionView()
            }
            .navigationDestination(isPresented: $navigateToHistory) {
                HistoryView()
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
        }
    }
}

// SwiftUI標準のモディファイアを拡張して44ptのタップターゲットを確保するヘルパー
extension View {
    func minHeightTapTarget() -> some View {
        self.frame(minHeight: 48)
    }
}
