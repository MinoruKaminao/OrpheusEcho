import SwiftUI

public struct SpeciesSelectionView: View {
    @EnvironmentObject var client: APIClient
    @State private var navigateToInfo = false
    @State private var selectedSpecies: Species?

    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("対象の動物種別を選択してください")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                    .padding(.top, 24)

                VStack(spacing: 16) {
                    // Dog Box
                    Button {
                        selectedSpecies = .dog
                        navigateToInfo = true
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "dog.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(Color(red: 0.18, green: 0.42, blue: 1.0))
                            Text("犬 (Dog)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                        }
                        .frame(maxWidth: .infinity, maxHeight: 180)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1.5)
                        )
                    }
                    .minHeightTapTarget()

                    // Cat Box
                    Button {
                        selectedSpecies = .cat
                        navigateToInfo = true
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "cat.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.18))
                            Text("猫 (Cat)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                        }
                        .frame(maxWidth: .infinity, maxHeight: 180)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1.5)
                        )
                    }
                    .minHeightTapTarget()
                }
                .padding(.horizontal, 16)

                Spacer()
            }
        }
        .navigationDestination(isPresented: $navigateToInfo) {
            if let species = selectedSpecies {
                AnimalInfoView(species: species)
            }
        }
    }
}
struct SpeciesSelectionView_Previews: PreviewProvider {
    public static var previews: some View {
        SpeciesSelectionView()
            .environmentObject(APIClient())
    }
}
