import SwiftUI

struct HealthStatsBar: View {
    @EnvironmentObject var healthManager: HealthKitManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCapsule(
                    icon: "figure.walk",
                    value: "Steps",
                    color: .green
                )
                
                StatCapsule(
                    icon: "heart.fill",
                    value: "Heart Rate",
                    color: .red
                )
                
                StatCapsule(
                    icon: "bed.double.fill",
                    value: "Sleep",
                    color: .blue
                )
                
                StatCapsule(
                    icon: "flame.fill",
                    value: "Calories",
                    color: .orange
                )
                
                StatCapsule(
                    icon: "location.fill",
                    value: "Distance",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
        .frame(height: 60)
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "green": return .green
        case "red": return .red
        case "pink": return .pink
        case "orange": return .orange
        case "cyan": return .cyan
        case "purple": return .purple
        case "blue": return .blue
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "teal": return .teal
        default: return .gray
        }
    }
}

struct StatCapsule: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

#Preview {
    HealthStatsBar()
        .environmentObject(HealthKitManager())
}