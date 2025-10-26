import SwiftUI
import Foundation

// MARK: - Image URL Helper
struct ImageURLHelper {
    
    // MARK: - Sample Image URLs for Testing
    static let sampleImages = [
        "https://via.placeholder.com/600x300/0066CC/FFFFFF?text=Load+Balancer+Diagram",
        "https://via.placeholder.com/600x250/4ECDC4/FFFFFF?text=ACID+Properties+Diagram", 
        "https://via.placeholder.com/600x300/FF6B6B/FFFFFF?text=Cache-Aside+Pattern+Flow",
        "https://via.placeholder.com/600x350/96CEB4/FFFFFF?text=Microservices+Architecture",
        "https://via.placeholder.com/600x280/45B7D1/FFFFFF?text=JWT+Authentication+Flow",
        "https://via.placeholder.com/600x400/8E44AD/FFFFFF?text=Layered+Architecture"
    ]
    
    // MARK: - System Design Diagram URLs (you can replace these with real diagrams)
    static let systemDesignImages = [
        "https://via.placeholder.com/600x300/FF6B6B/FFFFFF?text=System+Architecture+Overview",
        "https://via.placeholder.com/600x400/4ECDC4/FFFFFF?text=Database+Design+Patterns",
        "https://via.placeholder.com/600x350/45B7D1/FFFFFF?text=API+Gateway+Architecture",
        "https://via.placeholder.com/600x300/96CEB4/FFFFFF?text=Message+Queue+Patterns",
        "https://via.placeholder.com/600x400/8E44AD/FFFFFF?text=Microservices+Communication"
    ]
    
    // MARK: - Helper Methods
    static func isValidImageURL(_ urlString: String?) -> Bool {
        guard let urlString = urlString, !urlString.isEmpty else { return false }
        return URL(string: urlString) != nil
    }
    
    static func getRandomSampleImage() -> String {
        return sampleImages.randomElement() ?? sampleImages[0]
    }
    
    static func getRandomSystemDesignImage() -> String {
        return systemDesignImages.randomElement() ?? systemDesignImages[0]
    }
}

// MARK: - Image Loading States
enum ImageLoadingState {
    case loading
    case loaded
    case failed
}

// MARK: - Enhanced Question Image View with Better Error Handling
struct EnhancedQuestionImageView: View {
    let imageUrl: String?
    let imageAlt: String?
    let maxHeight: CGFloat
    
    @State private var loadingState: ImageLoadingState = .loading
    @State private var showFullScreen = false
    
    init(imageUrl: String?, imageAlt: String? = nil, maxHeight: CGFloat = 200) {
        self.imageUrl = imageUrl
        self.imageAlt = imageAlt
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        if let imageUrl = imageUrl, ImageURLHelper.isValidImageURL(imageUrl) {
            VStack(spacing: 8) {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: maxHeight)
                        .cornerRadius(12)
                        .onTapGesture {
                            showFullScreen = true
                        }
                        .onAppear {
                            loadingState = .loaded
                        }
                } placeholder: {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading diagram...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: maxHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Image caption and actions
                HStack {
                    if let imageAlt = imageAlt, !imageAlt.isEmpty {
                        Text(imageAlt)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    if loadingState == .loaded {
                        Button(action: {
                            showFullScreen = true
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .sheet(isPresented: $showFullScreen) {
                FullScreenImageView(
                    imageUrl: imageUrl,
                    imageAlt: imageAlt
                )
            }
        } else {
            // Fallback for invalid or missing images
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundColor(.gray)
                Text("Diagram not available")
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

// MARK: - Full Screen Image View
struct FullScreenImageView: View {
    let imageUrl: String
    let imageAlt: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = value
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = value.translation
                                    }
                            )
                        )
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                if let imageAlt = imageAlt, !imageAlt.isEmpty {
                    ToolbarItem(placement: .principal) {
                        Text(imageAlt)
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        EnhancedQuestionImageView(
            imageUrl: ImageURLHelper.getRandomSampleImage(),
            imageAlt: "This is a sample diagram showing system architecture"
        )
        
        EnhancedQuestionImageView(
            imageUrl: "invalid-url",
            imageAlt: "This will show the fallback"
        )
    }
    .padding()
}
