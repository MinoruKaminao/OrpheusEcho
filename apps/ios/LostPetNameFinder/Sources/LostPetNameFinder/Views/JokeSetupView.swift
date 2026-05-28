import SwiftUI
import PhotosUI

public struct JokeSetupView: View {
    @EnvironmentObject var client: APIClient
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCountry = "JP"
    @State private var selectedLanguage = "ja-JP"
    @State private var selectedAgeBand = "30s_like"
    @State private var selectedTone = "casual"
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var inputImage: PlatformImage? = nil
    @State private var isUploading = false
    @State private var navigateToExploration = false
    @State private var showConsentAlert = false
    @State private var consentAgreed = false
    
    let ageBands = [
        ("子ども風", "child_like"),
        ("20代風", "20s_like"),
        ("30代風", "30s_like"),
        ("40代風", "40s_like"),
        ("50代以上風", "50s_like")
    ]
    
    let tones = [
        ("カジュアル", "casual"),
        ("フォーマル", "formal")
    ]

    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Purpose / Warning Banner
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("ジョーク機能（娯楽用途）")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        Text("本機能は娯楽目的であり、本人確認、実名特定、または性別・国籍・民族・出身地などの個人属性の診断・推測は一切行いません。安全なニックネーム候補のみを提示します。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color(red: 1.0, green: 0.98, blue: 0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Options Panel (NeXT Bezel style)
                    VStack(alignment: .leading, spacing: 20) {
                        Text("設定条件")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        
                        // Country Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("国 / 地域")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Country", selection: $selectedCountry) {
                                Text("日本 (JP)").tag("JP")
                                Text("アメリカ (US)").tag("US")
                                Text("イギリス (GB)").tag("GB")
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: selectedCountry) { newCountry in
                                if newCountry == "JP" {
                                    selectedLanguage = "ja-JP"
                                } else if newCountry == "US" {
                                    selectedLanguage = "en-US"
                                } else {
                                    selectedLanguage = "en-GB"
                                }
                            }
                        }
                        
                        // Age Band
                        VStack(alignment: .leading, spacing: 8) {
                            Text("見た目印象カテゴリ (年代)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Age Band", selection: $selectedAgeBand) {
                                ForEach(ageBands, id: \.1) { item in
                                    Text(item.0).tag(item.1)
                                }
                            }
                            .pickerStyle(.menu)
                            .minHeightTapTarget()
                            .padding(.horizontal, 8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                            )
                        }
                        
                        // Tone
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ニックネームのトーン")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Tone", selection: $selectedTone) {
                                ForEach(tones, id: \.1) { item in
                                    Text(item.0).tag(item.1)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Image Input Section
                    VStack(spacing: 16) {
                        Text("人物画像の入力")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                        
                        ZStack {
                            if let img = inputImage {
                                Image(platformImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            } else {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.9, green: 0.92, blue: 0.95))
                                    .frame(width: 200, height: 200)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "person.crop.rectangle.badge.plus")
                                                .font(.largeTitle)
                                                .foregroundStyle(.secondary)
                                            Text("画像がありません")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    )
                            }
                        }
                        
                        HStack(spacing: 16) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Label("写真を選択", systemImage: "photo.on.rectangle")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                                    )
                            }
                            .onChange(of: selectedItem) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        #if canImport(UIKit)
                                        let image = UIImage(data: data)
                                        #elseif canImport(AppKit)
                                        let image = NSImage(data: data)
                                        #else
                                        let image: PlatformImage? = nil
                                        #endif
                                        if let img = image {
                                            inputImage = img
                                        }
                                    }
                                }
                            }
                            
                            Button {
                                // 実機なしテスト用にダミーの顔画像を生成して代入
                                useDemoFaceImage()
                            } label: {
                                Label("デモ顔を使用", systemImage: "face.smiling")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .padding()
                                    .background(Color(red: 0.9, green: 0.92, blue: 0.98))
                                    .foregroundStyle(Color(red: 0.18, green: 0.42, blue: 1.0))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Start Button
                    Button {
                        if !consentAgreed {
                            showConsentAlert = true
                        } else {
                            startJokeProcess()
                        }
                    } label: {
                        HStack {
                            if isUploading {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text("ジョークモードを開始")
                                .fontWeight(.bold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .minHeightTapTarget()
                        .background((inputImage == nil || isUploading) ? Color.secondary.opacity(0.3) : Color(red: 0.95, green: 0.6, blue: 0.1))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(inputImage == nil || isUploading)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("ジョーク設定")
        .navigationBarTitleDisplayMode(.inline)
        .alert("利用規約と同意", isPresented: $showConsentAlert) {
            Button("同意する") {
                consentAgreed = true
                startJokeProcess()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このジョーク機能は、顔写真と選択したメタデータを用いて一時的なニックネームを生成する娯楽機能です。顔写真はセッション結果カード生成のためだけに利用され、個人識別情報の取得、保存、外部送信は一切行われません。開始に同意しますか？")
        }
        .navigationDestination(isPresented: $navigateToExploration) {
            JokeExplorationView()
        }
    }
    
    private func useDemoFaceImage() {
        #if canImport(UIKit)
        // 白地のキャンバスにスマイルのシンボルを描画したダミー画像を生成
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
        let img = renderer.image { ctx in
            // 背景
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
            
            // 外枠
            UIColor.lightGray.setStroke()
            ctx.stroke(CGRect(x: 0, y: 0, width: 200, height: 200), width: 2)
            
            // 笑顔マークのシンボル描画
            let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .bold)
            if let smileSymbol = UIImage(systemName: "face.smiling", withConfiguration: config) {
                let tinted = smileSymbol.withTintColor(.systemOrange, renderingMode: .alwaysOriginal)
                tinted.draw(at: CGPoint(x: 60, y: 60))
            }
        }
        inputImage = img
        #elseif canImport(AppKit)
        // macOS用のダミーイメージ生成
        let img = NSImage(size: NSSize(width: 200, height: 200))
        img.lockFocus()
        NSColor.white.set()
        NSRect(x: 0, y: 0, width: 200, height: 200).fill()
        NSColor.lightGray.set()
        NSRect(x: 0, y: 0, width: 200, height: 200).frame(withWidth: 2)
        if let smileSymbol = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: nil) {
            let rect = NSRect(x: 60, y: 60, width: 80, height: 80)
            smileSymbol.draw(in: rect)
        }
        img.unlockFocus()
        inputImage = img
        #endif
    }
    
    private func startJokeProcess() {
        guard let img = inputImage else { return }
        isUploading = true
        
        Task {
            // 1. セッションの作成
            await client.createJokeSession(
                country: selectedCountry,
                language: selectedLanguage,
                ageBand: selectedAgeBand,
                tone: selectedTone
            )
            
            guard let jokeSession = client.currentJokeSession else {
                isUploading = false
                return
            }
            
            // 2. 画像のアップロード
            #if canImport(UIKit)
            let imageData = img.jpegData(compressionQuality: 0.8)
            #elseif canImport(AppKit)
            let imageData = img.tiffRepresentation
            #else
            let imageData: Data? = nil
            #endif
            
            if let data = imageData {
                let _ = await client.uploadJokeImage(
                    jokeSessionId: jokeSession.joke_session_id,
                    fileName: "face.jpg",
                    fileData: data
                )
            }
            
            // 3. 候補の生成
            await client.fetchJokeCandidates(jokeSessionId: jokeSession.joke_session_id)
            
            isUploading = false
            navigateToExploration = true
        }
    }
}
