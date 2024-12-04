import Firebase
import UIKit


extension Timestamp {
    func formatTimestamp() -> String {
        let date = self.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension String {
    static func randomAnonymousID(seed: String, length: Int = 8) -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var result = ""

        // Use the seed string to generate consistent random characters
        var seedValue = seed.utf8.reduce(0) { $0 + UInt32($1) }

        for _ in 0..<length {
            seedValue = seedValue &* 747796405 &+ 2891336453
            let index = Int(seedValue % UInt32(chars.count))
            result += String(chars[chars.index(chars.startIndex, offsetBy: index)])
        }

        return "Anon_\(result)"
    }
}

extension UIImage {
    func convertedToSRGB() -> UIImage? {
        guard let cgImage = self.cgImage else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))

        guard let convertedCGImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: convertedCGImage)
    }
}
