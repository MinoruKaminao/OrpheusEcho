import SwiftUI

public struct AnimalInfoView: View {
    @EnvironmentObject var client: APIClient
    public let species: Species

    @State private var tempAnimalId = ""
    @State private var locationText = ""
    @State private var coatColor = ""
    @State private var ageHint = ""
    @State private var notes = ""
    @State private var navigateToExploration = false

    public init(species: Species) {
        self.species = species
    }

    public var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("個体情報の入力")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                            .padding(.top, 16)

                        Text("探索中の記録や共有用メモとして活用されます（全項目任意）")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 16) {
                            // Temp ID
                            VStack(alignment: .leading, spacing: 6) {
                                Text("仮個体ID")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                TextField("例: DOG-TMP-001", text: $tempAnimalId)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .minHeightTapTarget()
                            }

                            // Location
                            VStack(alignment: .leading, spacing: 6) {
                                Text("保護場所・発見場所")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                TextField("例: 那覇市首里", text: $locationText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .minHeightTapTarget()
                            }

                            // Coat Color
                            VStack(alignment: .leading, spacing: 6) {
                                Text("毛色")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                TextField("例: 茶白、黒", text: $coatColor)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .minHeightTapTarget()
                            }

                            // Age Hint
                            VStack(alignment: .leading, spacing: 6) {
                                Text("年齢ヒント")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                TextField("例: 子犬、成猫、高齢期", text: $ageHint)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .minHeightTapTarget()
                            }

                            // Country Selector
                            VStack(alignment: .leading, spacing: 6) {
                                Text("探索対象国")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                Picker("探索対象国", selection: $client.selectedCountryCode) {
                                    if client.availableCountries.isEmpty {
                                        Text("日本").tag("JP")
                                        Text("United States").tag("US")
                                    } else {
                                        ForEach(client.availableCountries) { country in
                                            Text(country.name).tag(country.code)
                                        }
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
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
                            }

                            // Language Selector
                            VStack(alignment: .leading, spacing: 6) {
                                Text("探索言語")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                Picker("探索言語", selection: $client.selectedLanguageCode) {
                                    if client.availableLanguages.isEmpty {
                                        Text("日本語").tag("ja-JP")
                                        Text("English (US)").tag("en-US")
                                    } else {
                                        ForEach(client.availableLanguages) { lang in
                                            Text(lang.name).tag(lang.code)
                                        }
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .minHeightTapTarget()
                            }

                            // Notes
                            VStack(alignment: .leading, spacing: 6) {
                                Text("特徴・備考メモ")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                TextField("首輪あり、おとなしい等", text: $notes, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(3...6)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                }

                // Bottom Action Bar (Fixed at bottom for single-hand operations)
                VStack {
                    Button {
                        Task {
                            await client.createSession(
                                species: species,
                                tempId: tempAnimalId.isEmpty ? nil : tempAnimalId,
                                notes: notes.isEmpty ? nil : notes
                            )
                            // 完了したら探索画面へ遷移
                            navigateToExploration = true
                        }
                    } label: {
                        HStack {
                            if client.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text("探索を開始する")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .minHeightTapTarget()
                        .background(Color(red: 0.18, green: 0.42, blue: 1.0))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    }
                    .disabled(client.isLoading)
                    .padding()
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
        .navigationDestination(isPresented: $navigateToExploration) {
            ExplorationView()
        }
        .onAppear {
            Task {
                await client.fetchCountries()
                await client.fetchLanguages()
            }
        }
    }
}
