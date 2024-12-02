import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            // Process the image immediately after selection
                            let processedImage = self?.processImage(uiImage)
                            self?.parent.image = processedImage
                        }
                    }
                }
            }
        }

        private func processImage(_ originalImage: UIImage) -> UIImage? {
            // Determine the maximum dimension for scaling
            let maxDimension: CGFloat = 1024
            let scale = min(maxDimension / originalImage.size.width, maxDimension / originalImage.size.height, 1.0)

            // Calculate the new size
            let newSize = CGSize(width: originalImage.size.width * scale, height: originalImage.size.height * scale)

            // Create a new image context
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            originalImage.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            // Convert the resized image to JPEG data
            guard let jpegData = resizedImage?.jpegData(compressionQuality: 0.8) else {
                return nil
            }

            // Return the image created from JPEG data
            return UIImage(data: jpegData)
        }
    }
}
