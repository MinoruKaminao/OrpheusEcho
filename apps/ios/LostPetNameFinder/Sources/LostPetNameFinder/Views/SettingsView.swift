import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var client: APIClient
    
    // settings variables
    @State private var ttsVolume: Double = 0.8
    @State private var ttsSpeed: Double = 1.0
    @State private var cameraPermission = true
    @State private var locationPermission = false // デフォルトはOFF
    @State private var trainingConsent = false // AI学習用同意

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

            Section("プライバシー & 権限") {
                Toggle("カメラプレビューの利用", isOn: $cameraPermission)
                
                Toggle("位置情報サービスの利用", isOn: $locationPermission)
                    .help("デフォルトはOFFです。オンにすると、セッションの探索位置がローカルに記録されます。")
                
                Toggle("AI精度向上のための学習データ協力", isOn: $trainingConsent)
            }

            Section("同期設定") {
                Toggle("オフライン動作モード", isOn: $client.isOffline)
                
                Button("即時同期を試行") {
                    // 同期シミュレーション
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
    }
}
