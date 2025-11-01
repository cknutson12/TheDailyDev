import SwiftUI

struct DraggableItemCard: View {
    let item: MatchingItem
    let isMatched: Bool
    
    var body: some View {
        Text(item.text)
            .font(.body)
            .foregroundColor(.white)
            .padding()
            .frame(minWidth: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isMatched ? Color.gray.opacity(0.3) : Theme.Colors.subtleBlue.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isMatched ? Color.gray : Theme.Colors.subtleBlue, lineWidth: 2)
            )
            .opacity(isMatched ? 0.5 : 1.0)
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

