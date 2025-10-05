import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    
    var body: some View {
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
    }
}

#Preview {
    HomeView()
        .environmentObject(HealthKitManager())
}
