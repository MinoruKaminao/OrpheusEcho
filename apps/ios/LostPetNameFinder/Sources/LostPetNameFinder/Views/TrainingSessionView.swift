import SwiftUI

public struct TrainingSessionView: View {
    @EnvironmentObject var client: APIClient
    @Environment(\.dismiss) var dismiss
    
    let knownAnimalId: String
    let trueName: String
    let aliases: [String]
    
    // Configuration State
    @State private var speakerType = "owner"
    @State private var environmentType = "indoor"
    @State private var purpose = "positive_negative_collection"
    @State private var isSessionActive = false
    
    // Execution State
    @State private var currentStep = 0
    @State private var callNames: [CallNameItem] = []
    @State private var recordSuccess = false
    
    struct CallNameItem: Hashable {
        let name: String
        let isTrueName: Bool
        let isAlias: Bool
    }
    
    public init(knownAnimalId: String, trueName: String, aliases: [String]) {
        self.knownAnimalId = knownAnimalId
        self.trueName = trueName
        self.aliases = aliases
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 0.98)
                .ignoresSafeArea()
            
            VStack {
                if !isSessionActive {
                    // 1. Setup
                    setupView
                } else if currentStep < callNames.count {
                    // 2. Collection
                    collectionView(item: callNames[currentStep])
                } else {
                    // 3. Completion
                    completionView
                }
            }
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear {
            prepareCallNames()
        }
    }
    
    private var setupView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("学習データ収集の開始")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                    .padding(.top, 16)
                
                Text("名前のわかっている個体に対して、正しい名前と無関係な名前を呼びかけて反応を収集します。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("収集環境の設定")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("呼びかける人").font(.caption).foregroundStyle(.secondary)
                        Picker("話者種別", selection: $speakerType) {
                            Text("飼い主").tag("owner")
                            Text("家族").tag("family")
                            Text("第三者").tag("stranger")
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("撮影場所").font(.caption).foregroundStyle(.secondary)
                        Picker("環境", selection: $environmentType) {
                            Text("屋内").tag("indoor")
                            Text("屋外").tag("outdoor")
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                )
                
                Button {
                    Task {
                        await client.createTrainingSession(
                            knownAnimalId: knownAnimalId,
                            speaker: speakerType,
                            environment: environmentType,
                            purpose: purpose
                        )
                        isSessionActive = true
                    }
                } label: {
                    Text("収集セッションを開始する")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .minHeightTapTarget()
                        .background(Color(red: 0.18, green: 0.42, blue: 1.0))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func collectionView(item: CallNameItem) -> some View {
        VStack(spacing: 24) {
            HStack {
                Text("ステップ \(currentStep + 1) / \(callNames.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(.red)
                    Text("REC")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Spacer()
            
            VStack(spacing: 16) {
                Text(item.isTrueName ? "正名・愛称 (正例)" : "関係のない名前 (負例)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(item.isTrueName ? .green : .orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(item.isTrueName ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                
                Text(item.name)
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                
                Text("この名前で呼びかけてください")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("動物の反応を選択してください")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                
                HStack(spacing: 12) {
                    reactionButton(title: "反応あり", icon: "checkmark.circle.fill", color: .green, value: "reaction_yes")
                    reactionButton(title: "弱い", icon: "questionmark.circle.fill", color: .orange, value: "reaction_weak")
                    reactionButton(title: "反応なし", icon: "xmark.circle.fill", color: .gray, value: "reaction_no")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func reactionButton(title: String, icon: String, color: Color, value: String) -> some View {
        Button {
            Task {
                let currentItem = callNames[currentStep]
                await client.recordTrainingTrial(
                    calledName: currentItem.name,
                    isTrueName: currentItem.isTrueName,
                    isAlias: currentItem.isAlias,
                    modulation: "normal",
                    source: "owner_live_voice",
                    reaction: value
                )
                currentStep += 1
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
            )
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 70))
                .foregroundStyle(.green)
                .padding(.top, 40)
            
            Text("収集セッション完了")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
            
            Text("正名・誤名に対する反応データの収集が正常に完了しました。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button {
                Task {
                    await client.completeTrainingSession()
                    recordSuccess = true
                }
            } label: {
                Text("データを確定して保存する")
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
        .alert("保存完了", isPresented: $recordSuccess) {
            Button("ホームに戻る") {
                dismiss()
            }
        } message: {
            Text("収集した学習データが保存されました。通信状態が良いときに自動でサーバーに同期されます。")
        }
    }
    
    private func prepareCallNames() {
        var items: [CallNameItem] = []
        
        items.append(CallNameItem(name: trueName, isTrueName: true, isAlias: false))
        
        if let firstAlias = aliases.first {
            items.append(CallNameItem(name: firstAlias, isTrueName: true, isAlias: true))
        }
        
        items.append(CallNameItem(name: "チョコ", isTrueName: false, isAlias: false))
        items.append(CallNameItem(name: "レオ", isTrueName: false, isAlias: false))
        
        self.callNames = items.shuffled()
    }
}
