import SwiftUI

struct DraggableItemCard: View {
    let item: MatchingItem
    let isMatched: Bool
    
    var body: some View {
        Text(item.text)
            .font(.body)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minWidth: 140, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isMatched ? Color.gray.opacity(0.3) : Theme.Colors.subtleBlue.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isMatched ? Color.gray : Theme.Colors.accentGreen,
                        lineWidth: isMatched ? 1.5 : 2.5
                    )
            )
            .opacity(isMatched ? 0.5 : 1.0)
            .shadow(color: isMatched ? Color.clear : Theme.Colors.accentGreen.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        DraggableItemCard(
            item: MatchingItem(id: "1", text: "Write-through cache", isDraggable: true),
            isMatched: false
        )
        
        DraggableItemCard(
            item: MatchingItem(id: "2", text: "Write-behind cache", isDraggable: true),
            isMatched: true
        )
    }
    .padding()
}

