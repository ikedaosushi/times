import SwiftUI

struct OGPPreviewCard: View {
    let post: Post

    var body: some View {
        if let urlString = post.urlString, let url = URL(string: urlString) {
            VStack(alignment: .leading, spacing: 0) {
                // OGP Image
                if let ogpImageURL = post.ogpImageURL, let imageURL = URL(string: ogpImageURL) {
                    AsyncImage(url: imageURL, transaction: Transaction(animation: .easeIn(duration: 0.2))) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxHeight: 160)
                                .clipped()
                        case .failure:
                            EmptyView()
                        default:
                            Rectangle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(height: 100)
                                .overlay(ProgressView())
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let title = post.ogpTitle {
                        Text(title)
                            .font(.callout.bold())
                            .lineLimit(2)
                    }
                    if let description = post.ogpDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Text(url.host ?? urlString)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(10)
            }
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
            .frame(maxWidth: 300)
        }
    }
}
