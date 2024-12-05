import SwiftUI

struct RatingStars: View {
    let rating: Double
    let maxRating: Int = 5
    let starSize: CGFloat
    let spacing: CGFloat

    init(rating: Double, starSize: CGFloat = 14, spacing: CGFloat = 4) {
        self.rating = rating
        self.starSize = starSize
        self.spacing = spacing
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<maxRating, id: \.self) { index in
                PartialStar(fillPercentage: getFillPercentage(for: index))
                    .foregroundColor(.yellow)
                    .frame(width: starSize, height: starSize)
            }
        }
    }

    private func getFillPercentage(for index: Int) -> Double {
        let fillAmount = rating - Double(index)
        if fillAmount >= 1 {
            return 1
        } else if fillAmount > 0 {
            return fillAmount
        }
        return 0
    }
}

private struct PartialStar: View{
    let fillPercentage: Double // 0.0 to 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Empty star
                Image(systemName: "star")
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                // Filled star with clip
                Image(systemName: "star.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(
                        Rectangle()
                            .size(
                                width: geometry.size.width * fillPercentage,
                                height: geometry.size.height
                            )
                    )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RatingStars(rating: 3.7)
        RatingStars(rating: 2.5)
        RatingStars(rating: 4.2)
        RatingStars(rating: 1.8)
    }
    .padding()
}