import SwiftUI

struct AdaptiveText: View {
    let text: String
    let maxFontSize: CGFloat
    let minFontSize: CGFloat
    let preferredFont: Font
    
    init(_ text: String, 
         maxFontSize: CGFloat = 18, 
         minFontSize: CGFloat = 12, 
         preferredFont: Font = .body) {
        self.text = text
        self.maxFontSize = maxFontSize
        self.minFontSize = minFontSize
        self.preferredFont = preferredFont
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: calculateFontSize(), weight: .regular))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func calculateFontSize() -> CGFloat {
        let textLength = text.count
        
        // Scale font size based on text length
        if textLength < 50 {
            return maxFontSize
        } else if textLength < 100 {
            return maxFontSize * 0.9
        } else if textLength < 200 {
            return maxFontSize * 0.8
        } else if textLength < 300 {
            return maxFontSize * 0.7
        } else {
            return max(minFontSize, maxFontSize * 0.6)
        }
    }
}

// MARK: - Scrollable Text for Very Long Content
struct ScrollableText: View {
    let text: String
    let maxHeight: CGFloat
    
    init(_ text: String, maxHeight: CGFloat = 200) {
        self.text = text
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        ScrollView {
            Text(text)
                .font(.body)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: maxHeight)
    }
}

// MARK: - Expandable Text with "Show More" functionality
struct ExpandableText: View {
    let text: String
    let maxLines: Int
    @State private var isExpanded = false
    @State private var shouldShowButton = false
    
    init(_ text: String, maxLines: Int = 3) {
        self.text = text
        self.maxLines = maxLines
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.body)
                .lineLimit(isExpanded ? nil : maxLines)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    // Invisible view to measure text height
                    Text(text)
                        .font(.body)
                        .lineLimit(maxLines)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0)
                        .overlay(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        // Check if text is truncated
                                        let fullTextHeight = text.height(withConstrainedWidth: geometry.size.width, font: UIFont.systemFont(ofSize: 17))
                                        let limitedTextHeight = text.height(withConstrainedWidth: geometry.size.width, font: UIFont.systemFont(ofSize: 17), maxLines: maxLines)
                                        shouldShowButton = fullTextHeight > limitedTextHeight
                                    }
                            }
                        )
                )
            
            if shouldShowButton {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Extension to calculate text height
extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont, maxLines: Int? = nil) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        
        let height = ceil(boundingBox.height)
        
        if let maxLines = maxLines {
            let lineHeight = font.lineHeight
            let maxHeight = lineHeight * CGFloat(maxLines)
            return min(height, maxHeight)
        }
        
        return height
    }
}
