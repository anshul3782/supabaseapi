import SwiftUI

struct StaticEmojiView: View {
    let emojiName: String
    let size: CGFloat
    
    init(emojiName: String, size: CGFloat = 24) {
        self.emojiName = emojiName
        self.size = size
    }
    
    var body: some View {
        // For now, use SF Symbols as fallback
        // In a real implementation, you'd load the first frame of the Lottie animation
        Image(systemName: emojiToSFSymbol(emojiName))
            .font(.system(size: size))
            .foregroundColor(.blue)
    }
}

// Helper function to map emoji names to SF Symbols
func emojiToSFSymbol(_ emojiName: String) -> String {
    switch emojiName {
    case "happy-cry", "grinning", "joy", "laughing":
        return "face.smiling"
    case "angry", "rage":
        return "face.dashed"
    case "cold-face":
        return "snowflake"
    case "crying", "loudly-crying":
        return "cloud.rain"
    case "flushed":
        return "flame"
    case "gasp", "astonished":
        return "exclamationmark.circle"
    case "grimacing":
        return "face.dashed.fill"
    case "sad", "pensive":
        return "face.dashed"
    case "surprised", "astonished":
        return "exclamationmark.triangle"
    case "heart-eyes", "heart-face":
        return "heart.fill"
    case "sleep", "sleepy":
        return "bed.double.fill"
    case "thinking-face":
        return "brain.head.profile"
    case "tired", "weary":
        return "moon.zzz.fill"
    default:
        return "face.smiling"
    }
}
