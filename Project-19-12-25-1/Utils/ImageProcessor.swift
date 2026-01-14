import UIKit
import Foundation

class ImageProcessor {
    static func compressImage(_ image: UIImage, maxDimension: CGFloat = AppConstants.Validation.maxImageDimension, quality: CGFloat = AppConstants.Validation.imageCompressionQuality) -> Data? {
        // Resize if needed
        let resizedImage = resizeImage(image, maxDimension: maxDimension)
        
        // Compress
        return resizedImage.jpegData(compressionQuality: quality)
    }
    
    static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // Check if resizing is needed
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Create graphics context
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    static func validateImageSize(_ data: Data) -> Bool {
        return Int64(data.count) <= AppConstants.Validation.maxImageSize
    }
}
