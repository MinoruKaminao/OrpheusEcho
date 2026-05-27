import SwiftUI

@main
struct LostPetNameFinderApp: App {
    // 共有の API クライアントインスタンスを作成
    @StateObject private var client = APIClient()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(client)
        }
    }
}
