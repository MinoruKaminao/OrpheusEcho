import SwiftUI

public struct HistoryView: View {
    @EnvironmentObject var client: APIClient

    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if client.history.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("探索履歴がありません")
                            .font(.headline)
                        Text("新しくセッションを開始して呼称を記録してください")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(client.history) { session in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: session.species == .dog ? "dog.fill" : "cat.fill")
                                        .foregroundStyle(session.species == .dog ? .blue : .orange)
                                    
                                    Text(session.species == .dog ? "犬 (Dog)" : "猫 (Cat)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                    
                                    // Sync status
                                    if session.session_id.contains("offline") {
                                        HStack(spacing: 4) {
                                            Circle().frame(width: 6, height: 6).foregroundStyle(.orange)
                                            Text("未同期")
                                                .font(.system(size: 10))
                                                .foregroundStyle(.orange)
                                        }
                                    } else {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 10))
                                                .foregroundStyle(.blue)
                                            Text("同期済み")
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }

                                Text("ID: \(session.session_id)")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                
                                if let notes = session.notes {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Text(session.created_at, style: .date)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .navigationTitle("探索履歴")
    }
}
