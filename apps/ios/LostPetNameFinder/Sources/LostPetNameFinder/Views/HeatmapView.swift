import SwiftUI
import MapKit

public struct HeatmapView: View {
    @EnvironmentObject var client: APIClient
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedSpecies = "all"
    @State private var selectedPoint: HeatmapPoint? = nil
    
    // Default region centered in Tokyo region
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $region, annotationItems: client.heatmapPoints) { point in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)) {
                    Button {
                        withAnimation(.spring()) {
                            selectedPoint = point
                        }
                    } label: {
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(markerColor(for: point.highest_score))
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: point.species == "dog" ? "dog.fill" : "cat.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white)
                            }
                            
                            // Arrow indicator
                            Image(systemName: "triangle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(markerColor(for: point.highest_score))
                                .rotationEffect(.degrees(180))
                                .offset(y: -3)
                        }
                    }
                    .minHeightTapTarget()
                }
            }
            .ignoresSafeArea()
            
            // Floating Overlays (Top segment filters and Bottom details)
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                            .padding(12)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4)
                    }
                    .minHeightTapTarget()
                    
                    Spacer()
                    
                    Picker("Species", selection: $selectedSpecies) {
                        Text("すべて").tag("all")
                        Text("犬").tag("dog")
                        Text("猫").tag("cat")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                    .padding(6)
                    .background(Color.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.1), radius: 4)
                    .onChange(of: selectedSpecies) { val in
                        loadHeatmapData()
                    }
                    
                    Spacer()
                    
                    if client.isOffline {
                        Image(systemName: "wifi.slash")
                            .foregroundStyle(.orange)
                            .padding(12)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4)
                    } else {
                        Spacer().frame(width: 44)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                Spacer()
                
                // Bottom Details Panel (Slide up transition)
                if let point = selectedPoint {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(point.species == "dog" ? "犬の探索ログ" : "猫の探索ログ")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Spacer()
                            Button {
                                withAnimation {
                                    selectedPoint = nil
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.title3)
                            }
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("最有力反応呼称")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(point.best_candidate_name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("最高反応スコア")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.0f%%", point.highest_score * 100))
                                    .font(.system(.title2, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(markerColor(for: point.highest_score))
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            if let noise = point.avg_ambient_noise_db {
                                Label(String(format: "平均騒音: %.1f dB", noise), systemImage: "waveform.path")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Label("騒音データなし", systemImage: "waveform.path")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let dateStr = point.created_at, let date = parseDate(dateStr) {
                                Label(formatDate(date), systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.86, green: 0.89, blue: 0.94), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            loadHeatmapData()
        }
    }
    
    private func markerColor(for score: Double) -> Color {
        if score >= 0.8 {
            return .red
        } else if score >= 0.5 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private func loadHeatmapData() {
        Task {
            let filter = selectedSpecies == "all" ? nil : selectedSpecies
            await client.fetchHeatmapPoints(species: filter)
            
            // UX: Autofit region to the first available point
            if let firstPoint = client.heatmapPoints.first {
                withAnimation(.easeOut(duration: 0.5)) {
                    region.center = CLLocationCoordinate2D(latitude: firstPoint.latitude, longitude: firstPoint.longitude)
                    region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                }
            }
        }
    }
    
    private func parseDate(_ dateStr: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: dateStr) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateStr)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}
