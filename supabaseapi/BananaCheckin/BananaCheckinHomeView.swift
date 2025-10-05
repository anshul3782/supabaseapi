import SwiftUI

struct BananaCheckinHomeView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    HealthStatsBar()
                        .environmentObject(healthManager)

                    EmotionalTimeline()

                    CardFeedView()
                        .frame(height: 380)
                        .padding(.top, 12)

                    MusicWidget()
                        .padding(.top, 12)

                    Spacer(minLength: 80)
                }
            }
            .navigationTitle("Checkin")
        }
    }
}

#Preview {
    BananaCheckinHomeView()
        .environmentObject(HealthKitManager())
}
