import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let target: MatchingItem
    let matchedItem: MatchingItem?
    let onDrop: (String) -> Bool
    let onRemove: () -> Void
    
    @State private var isTargeted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Target label
            Text(target.text)
                .font(.body)
                .foregroundColor(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Drop zone area
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: matchedItem == nil ? [8, 4] : []
                        )
                    )
                    .foregroundColor(isTargeted ? Theme.Colors.accentGreen : Theme.Colors.border)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                matchedItem != nil
                                    ? Theme.Colors.subtleBlue.opacity(0.1)
                                    : (isTargeted ? Theme.Colors.accentGreen.opacity(0.1) : Color.clear)
                            )
                    )
                    .frame(height: 60)
                
                // Content
                if let matched = matchedItem {
                    // Show matched item
                    HStack {
                        Text(matched.text)
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: onRemove) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.Colors.stateIncorrect)
                        }
                    }
                    .padding(.horizontal, 12)
                } else {
                    // Show placeholder
                    Text("Drop here")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
        .dropDestination(for: String.self) { items, location in
            guard let itemId = items.first else { return false }
            return onDrop(itemId)
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Empty drop zone
        DropZoneView(
            target: MatchingItem(
                id: "target1",
                text: "High read frequency, critical data consistency",
                isDraggable: false
            ),
            matchedItem: nil,
            onDrop: { _ in true },
            onRemove: {}
        )
        
        // Filled drop zone
        DropZoneView(
            target: MatchingItem(
                id: "target2",
                text: "High write frequency, eventual consistency OK",
                isDraggable: false
            ),
            matchedItem: MatchingItem(
                id: "source1",
                text: "Write-behind cache",
                isDraggable: true
            ),
            onDrop: { _ in true },
            onRemove: {}
        )
    }
    .padding()
}

