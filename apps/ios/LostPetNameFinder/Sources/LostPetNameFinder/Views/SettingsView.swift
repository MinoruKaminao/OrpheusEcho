import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var client: APIClient
    
    // settings variables
    @State private var ttsVolume: Double = 0.8
    @State private var ttsSpeed: Double = 1.0
    @State private var cameraPermission = true
    @State private var locationPermission = false // デフォルトはOFF
    @State private var trainingConsent = false // AI学習用同意

    @State private var showUpdateAlert = false
    @State private var alertMessage = ""
    @State private var updateVersion: String? = nil

    public init() {}

    public var body: some View {
        Form {
            Section("音声再生 (TTS) 設定") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("TTS音量")
                        Spacer()
                        Text(String(format: "%.0f%%", ttsVolume * 100))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $ttsVolume, in: 0...1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("再生速度")
                        Spacer()
                        Text(String(format: "%.1fx", ttsSpeed))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $ttsSpeed, in: 0.5...2.0)
                }
            }

            Section("表示・音声言語") {
                Picker("表示国", selection: $client.selectedCountryCode) {
                    if client.availableCountries.isEmpty {
                        Text("日本").tag("JP")
                        Text("United States").tag("US")
                    } else {
                        ForEach(client.availableCountries) { country in
                            Text(country.name).tag(country.code)
                        }
                    }
                }
                .minHeightTapTarget()
                .onChange(of: client.selectedCountryCode) { newCountry in
                    if let country = client.availableCountries.first(where: { $0.code == newCountry }) {
                        client.selectedLanguageCode = country.default_language
                    } else if newCountry == "US" {
                        client.selectedLanguageCode = "en-US"
                    } else if newCountry == "JP" {
                        client.selectedLanguageCode = "ja-JP"
                    }
                }

                Picker("言語 locale", selection: $client.selectedLanguageCode) {
                    if client.availableLanguages.isEmpty {
                        Text("日本語").tag("ja-JP")
                        Text("English (US)").tag("en-US")
                    } else {
                        ForEach(client.availableLanguages) { lang in
                            Text(lang.name).tag(lang.code)
                        }
                    }
                }
                .minHeightTapTarget()

                Picker("音声プロファイル", selection: $client.selectedTTSProfileId) {
                    Text("デフォルト").tag(nil as String?)
                    ForEach(client.availableTTSProfiles) { profile in
                        Text("\(profile.voice_name) (\(profile.gender == "female" ? "女性" : "男性"))").tag(profile.id as String?)
                    }
                }
                .minHeightTapTarget()
                .onChange(of: client.selectedTTSProfileId) { newProfileId in
                    guard let profileId = newProfileId else { return }
                    Task {
                        if let res = await client.requestTTSPreview(text: "ハロー", profileId: profileId) {
                            print("TTS Preview Audio Link: \(res.audio_url)")
                            NSSoundMock.play()
                        }
                    }
                }
            }

            Section("プライバシー & 権限") {
                Toggle("カメラプレビューの利用", isOn: $cameraPermission)
                
                Toggle("位置情報サービスの利用", isOn: $locationPermission)
                    .help("デフォルトはOFFです。オンにすると、セッションの探索位置がローカルに記録されます。")
                
                Toggle("AI精度向上のための学習データ協力", isOn: $trainingConsent)
            }

            Section("同期設定") {
                Toggle("オフライン動作モード", isOn: $client.isOffline)
                
                if client.isSyncing {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text(client.syncMessage ?? "同期中...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button("即時同期を試行") {
                        Task {
                            await client.syncOfflineData()
                        }
                    }
                    .disabled(client.isOffline)
                    
                    if let msg = client.syncMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("未同期データ: セッション \(client.pendingSessions.count)件 / 試行 \(client.pendingTrials.count)件")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Section("AIモデル更新") {
                HStack {
                    Text("現在のAIモデル")
                    Spacer()
                    Text("v\(client.currentModelVersion)")
                        .foregroundStyle(.secondary)
                }
                
                Button("AIモデル更新を確認") {
                    Task {
                        if let updateRes = await client.checkModelUpdate() {
                            if updateRes.update_available {
                                alertMessage = "新しいAIモデル (v\(updateRes.latest_version)) が利用可能です。"
                                updateVersion = updateRes.latest_version
                                showUpdateAlert = true
                            } else {
                                alertMessage = "すでに最新のAIモデルが適用されています。"
                                updateVersion = nil
                                showUpdateAlert = true
                            }
                        } else {
                            alertMessage = "モデル更新の確認に失敗しました。"
                            updateVersion = nil
                            showUpdateAlert = true
                        }
                    }
                }
                .disabled(client.isOffline)
            }

            Section("情報") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("0.1.0")
                        .foregroundStyle(.secondary)
                }
                
                Link("プライバシーポリシー", destination: URL(string: "https://example.local/privacy")!)
            }
        }
        .navigationTitle("設定")
        .alert("AIモデル更新", isPresented: $showUpdateAlert) {
            if let version = updateVersion {
                Button("アップデートを適用") {
                    Task {
                        let success = await client.applyModelUpdate(version: version)
                        if success {
                            alertMessage = "新しいAIモデル (v\(version)) の適用が完了しました。"
                            updateVersion = nil
                            showUpdateAlert = true
                        } else {
                            alertMessage = "アップデートの適用に失敗しました。"
                            updateVersion = nil
                            showUpdateAlert = true
                        }
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } else {
                Button("OK") {}
            }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            Task {
                await client.fetchCountries()
                await client.fetchLanguages()
                await client.fetchTTSProfiles()
            }
        }
    }
}
