import SwiftUI

// MARK: - Question Image Component
struct QuestionImageView: View {
    let imageUrl: String?
    let imageAlt: String?
    let maxHeight: CGFloat
    
    @State private var isLoading = true
    @State private var hasError = false
    
    init(imageUrl: String?, imageAlt: String? = nil, maxHeight: CGFloat = 200) {
        self.imageUrl = imageUrl
        self.imageAlt = imageAlt
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        if let imageUrl = imageUrl, !imageUrl.isEmpty {
            VStack(spacing: 8) {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: maxHeight)
                        .cornerRadius(12)
                        .onAppear {
                            isLoading = false
                            hasError = false
                        }
                } placeholder: {
                    if isLoading {
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading image...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: maxHeight)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                if let imageAlt = imageAlt, !imageAlt.isEmpty {
                    Text(imageAlt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if hasError {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Image unavailable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: maxHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Expandable Question Image
struct ExpandableQuestionImageView: View {
    let imageUrl: String?
    let imageAlt: String?
    let maxHeight: CGFloat
    
    @State private var isExpanded = false
    
    init(imageUrl: String?, imageAlt: String? = nil, maxHeight: CGFloat = 200) {
        self.imageUrl = imageUrl
        self.imageAlt = imageAlt
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        if let imageUrl = imageUrl, !imageUrl.isEmpty {
            VStack(spacing: 8) {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: isExpanded ? 400 : maxHeight)
                        .cornerRadius(12)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }
                } placeholder: {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading image...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: maxHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                HStack {
                    if let imageAlt = imageAlt, !imageAlt.isEmpty {
                        Text(imageAlt)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Image Gallery (for multiple images)
struct QuestionImageGallery: View {
    let imageUrls: [String]
    let imageAlts: [String]?
    let maxHeight: CGFloat
    
    @State private var selectedIndex = 0
    
    init(imageUrls: [String], imageAlts: [String]? = nil, maxHeight: CGFloat = 200) {
        self.imageUrls = imageUrls
        self.imageAlts = imageAlts
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        if !imageUrls.isEmpty {
            VStack(spacing: 12) {
                // Main image
                AsyncImage(url: URL(string: imageUrls[selectedIndex])) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: maxHeight)
                        .cornerRadius(12)
                } placeholder: {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading image...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: maxHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Image caption
                if let imageAlts = imageAlts, selectedIndex < imageAlts.count, !imageAlts[selectedIndex].isEmpty {
                    Text(imageAlts[selectedIndex])
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Thumbnail navigation (if multiple images)
                if imageUrls.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0..<imageUrls.count, id: \.self) { index in
                                AsyncImage(url: URL(string: imageUrls[index])) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedIndex == index ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedIndex = index
                                            }
                                        }
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Single image
        QuestionImageView(
            imageUrl: "https://via.placeholder.com/400x200/0066CC/FFFFFF?text=Sample+Diagram",
            imageAlt: "This is a sample diagram showing system architecture"
        )
        
        // Expandable image
        ExpandableQuestionImageView(
            imageUrl: "https://via.placeholder.com/400x300/FF6B6B/FFFFFF?text=Expandable+Image",
            imageAlt: "Tap to expand this image"
        )
        
        // Image gallery
        QuestionImageGallery(
            imageUrls: [
                "https://via.placeholder.com/400x200/4ECDC4/FFFFFF?text=Image+1",
                "https://via.placeholder.com/400x200/45B7D1/FFFFFF?text=Image+2",
                "https://via.placeholder.com/400x200/96CEB4/FFFFFF?text=Image+3"
            ],
            imageAlts: ["First diagram", "Second diagram", "Third diagram"]
        )
    }
    .padding()
}
