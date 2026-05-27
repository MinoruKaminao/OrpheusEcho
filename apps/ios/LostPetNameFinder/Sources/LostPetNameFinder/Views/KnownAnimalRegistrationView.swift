import SwiftUI

public struct KnownAnimalRegistrationView: View {
    @EnvironmentObject var client: APIClient
    @Environment(\.dismiss) var dismiss
    
    @State private var species: Species = .dog
    @State private var trueName: String = ""
    @State private var aliasInput: String = ""
    @State private var aliases: [String] = []
    @State private var sex: String = "unknown"
    @State private var ageRange: String = "adult"
    @State private var breed: String = ""
    @State private var coatColor: String = ""
    @State private var consentForTraining = true
    
    @State private var isRegistered = false
    @State private var registeredAnimalId: String?
    @State private var navigateToTraining = false

    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("既知名個体の登録")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                            .padding(.top, 16)

                        Text("名前が分かっている個体を登録して、AIの正例・負例の学習データを収集します。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // Species Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("動物の種別")
                                .font(.subheadline).fontWeight(.bold)
                            Picker("種別", selection: $species) {
                                Text("犬").tag(Species.dog)
                                Text("猫").tag(Species.cat)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Basic Info Form
                        VStack(alignment: .leading, spacing: 16) {
                            Text("基本情報")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("正式名（必須）").font(.caption).foregroundStyle(.secondary)
                                TextField("例: タマ, ポチ", text: $trueName)
                                    .padding()
                                    .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("愛称・呼び方").font(.caption).foregroundStyle(.secondary)
                                HStack {
                                    TextField("例: たまちゃん", text: $aliasInput)
                                        .padding()
                                        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Button {
                                        let trimmed = aliasInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !trimmed.isEmpty && !aliases.contains(trimmed) {
                                            aliases.append(trimmed)
                                            aliasInput = ""
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(Color(red: 0.18, green: 0.42, blue: 1.0))
                                    }
                                    .minHeightTapTarget()
                                }
                                
                                if !aliases.isEmpty {
                                    FlowLayout(items: aliases) { alias in
                                        HStack(spacing: 4) {
                                            Text(alias)
                                                .font(.caption)
                                            Button {
                                                aliases.removeAll(where: { $0 == alias })
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption2)
                                                    .foregroundStyle(.gray)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(red: 0.9, green: 0.92, blue: 0.96))
                                        .clipShape(Capsule())
                                    }
                                    .padding(.top, 4)
                                }
                            }

                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("性別").font(.caption).foregroundStyle(.secondary)
                                    Picker("性別", selection: $sex) {
                                        Text("オス").tag("male")
                                        Text("メス").tag("female")
                                        Text("不明").tag("unknown")
                                    }
                                    .pickerStyle(.menu)
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("年齢層").font(.caption).foregroundStyle(.secondary)
                                    Picker("年齢層", selection: $ageRange) {
                                        Text("幼齢").tag("young")
                                        Text("成齢").tag("adult")
                                        Text("高齢").tag("senior")
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("品種（任意）").font(.caption).foregroundStyle(.secondary)
                                TextField("例: 柴犬, 雑種", text: $breed)
                                    .padding()
                                    .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("毛色（任意）").font(.caption).foregroundStyle(.secondary)
                                TextField("例: 茶白, 黒茶", text: $coatColor)
                                    .padding()
                                    .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                        )

                        // Consent Switch
                        VStack(alignment: .leading, spacing: 12) {
                            Text("データ提供とプライバシー")
                                .font(.headline)
                            
                            Toggle(isOn: $consentForTraining) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("学習データ提供に同意する")
                                        .font(.subheadline).fontWeight(.semibold)
                                    Text("収集されたデータは匿名化され、推定AIモデルの精度向上のみに使用されます。同意はいつでも設定から撤回可能です。")
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

                // Action Bottom Bar
                VStack(spacing: 12) {
                    Button {
                        Task {
                            let consentStr = consentForTraining ? "agreed" : "withdrawn"
                            await client.registerKnownAnimal(
                                species: species,
                                trueName: trueName,
                                aliases: aliases.isEmpty ? nil : aliases,
                                sex: sex,
                                ageRange: ageRange,
                                breed: breed.isEmpty ? nil : breed,
                                coatColor: coatColor.isEmpty ? nil : coatColor,
                                consent: consentStr
                            )
                            
                            if let lastAnimal = client.knownAnimals.last {
                                registeredAnimalId = lastAnimal.known_animal_id
                                isRegistered = true
                            }
                        }
                    } label: {
                        Text("個体を登録する")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .minHeightTapTarget()
                            .background(trueName.isEmpty ? Color.gray : Color(red: 0.18, green: 0.42, blue: 1.0))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(trueName.isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .padding(.top, 12)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color(red: 0.86, green: 0.89, blue: 0.94)),
                    alignment: .top
                )
            }
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .alert("登録完了", isPresented: $isRegistered) {
            Button("学習セッションを開始する") {
                navigateToTraining = true
            }
            Button("ホームに戻る") {
                dismiss()
            }
        } message: {
            Text("個体の登録が成功しました。続けて反応収集（学習セッション）を開始しますか？")
        }
        .navigationDestination(isPresented: $navigateToTraining) {
            if let animalId = registeredAnimalId {
                TrainingSessionView(knownAnimalId: animalId, trueName: trueName, aliases: aliases)
            }
        }
    }
}

// FlowLayout helper for tag display
struct FlowLayout: View {
    let items: [String]
    let viewForItem: (String) -> AnyView

    init<V: View>(items: [String], @ViewBuilder viewForItem: @escaping (String) -> V) {
        self.items = items
        self.viewForItem = { AnyView(viewForItem($0)) }
    }

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(self.items, id: \.self) { item in
                    self.viewForItem(item)
                        .alignmentGuide(.leading, computeValue: { d in
                            if (abs(width - d.width) > geometry.size.width) {
                                width = 0
                                height -= d.height + 6
                            }
                            let result = width
                            if item == self.items.last! {
                                width = 0
                            } else {
                                width -= d.width + 6
                            }
                            return result
                        })
                        .alignmentGuide(.top, computeValue: { _ in
                            let result = height
                            if item == self.items.last! {
                                height = 0
                            }
                            return result
                        })
                }
            }
        }
        .frame(height: 40)
    }
}
