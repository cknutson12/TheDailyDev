import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let target: MatchingItem
    let matchedItem: MatchingItem?
    let onDrop: (String) -> Bool
    let onRemove: () -> Void
    
    @State private var isTargeted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Target label
            Text(target.text)
                .font(.body)
                .foregroundColor(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Drop zone area - made bigger and more prominent
            ZStack {
                // Background with larger hit area
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        style: StrokeStyle(
                            lineWidth: 2.5,
                            dash: matchedItem == nil ? [8, 4] : []
                        )
                    )
                    .foregroundColor(isTargeted ? Theme.Colors.accentGreen : Theme.Colors.border)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                matchedItem != nil
                                    ? Theme.Colors.subtleBlue.opacity(0.15)
                                    : (isTargeted ? Theme.Colors.accentGreen.opacity(0.15) : Color.clear)
                            )
                    )
                    .frame(minHeight: 80) // Increased from 60 to 80
                    .frame(maxWidth: .infinity) // Make it full width
                
                // Content
                if let matched = matchedItem {
                    // Show matched item
                    HStack {
                        Text(matched.text)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                        
                        Button(action: onRemove) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(Color.theme.textSecondary)
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                } else {
                    // Show placeholder
                    Text("Drop here")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.vertical, 12)
                }
            }
        }
        .contentShape(Rectangle()) // Make entire area tappable/droppable
        .dropDestination(for: String.self) { items, location in
            // Accept drop if any part of the dragged item touches the drop zone
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

