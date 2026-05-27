import SwiftUI

public struct CandidateRankingView: View {
    @EnvironmentObject var client: APIClient
    @State private var navigateToDetail = false

    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("呼称候補ランキング")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                            .padding(.top, 16)

                        Text("反応が強かった呼称候補（参考スコア順）")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if client.rankedCandidates.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                                Text("反応ログが記録されていません")
                                    .font(.headline)
                                Text("探索画面で手動反応を入力してください")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(client.rankedCandidates.enumerated()), id: \.element.id) { index, item in
                                    HStack(spacing: 16) {
                                        // Rank Number
                                        Text("\(index + 1)")
                                            .font(.system(.title3, design: .monospaced))
                                            .fontWeight(.bold)
                                            .foregroundStyle(index < 3 ? Color(red: 0.18, green: 0.42, blue: 1.0) : .secondary)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Text(item.name)
                                                    .font(.headline)
                                                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                                                
                                                if item.uncertainty_flag {
                                                    Image(systemName: "questionmark.circle")
                                                        .font(.caption2)
                                                        .foregroundStyle(.orange)
                                                        .help("試行回数が不足しているためスコアの信頼性が低い候補です")
                                                }
                                            }

                                            // Progress bar representing score (参考スコア)
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .frame(height: 6)
                                                        .foregroundStyle(Color(red: 0.9, green: 0.92, blue: 0.96))
                                                    Capsule()
                                                        .frame(width: geo.size.width * CGFloat(item.score), height: 6)
                                                        .foregroundStyle(Color(red: 0.18, green: 0.42, blue: 1.0))
                                                }
                                            }
                                            .frame(height: 6)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(String(format: "%.2f", item.score))
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
                    }
                    .padding(.horizontal, 16)
                }

                // Bottom Action Panel
                VStack(spacing: 12) {
                    // Refine (愛称展開) Button
                    Button {
                        Task {
                            await client.refineCandidates()
                        }
                    } label: {
                        HStack {
                            if client.isLoading {
                                ProgressView().tint(.blue)
                            }
                            Image(systemName: "sparkles")
                            Text("上位候補から愛称・変形を展開")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .minHeightTapTarget()
                        .background(Color(red: 0.93, green: 0.95, blue: 1.0))
                        .foregroundStyle(Color(red: 0.18, green: 0.42, blue: 1.0))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.18, green: 0.42, blue: 1.0).opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(client.isLoading || client.rankedCandidates.isEmpty)
                    .padding(.horizontal, 16)

                    // Complete & Go to details
                    Button {
                        navigateToDetail = true
                    } label: {
                        Text("セッションを保存して詳細へ")
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
        .navigationDestination(isPresented: $navigateToDetail) {
            ResultDetailView()
        }
    }
}
