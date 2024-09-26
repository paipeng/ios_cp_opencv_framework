//
//  UIImage+extension.swift
//  ProductChain
//
//  Created by Pai Peng on 2024/3/15.
//

import Foundation
import UIKit
import Accelerate
import SDWebImageWebPCoder


enum FilterType : String {
    case Chrome = "CIPhotoEffectChrome"
    case Fade = "CIPhotoEffectFade"
    case Instant = "CIPhotoEffectInstant"
    case Mono = "CIPhotoEffectMono"
    case Noir = "CIPhotoEffectNoir"
    case Process = "CIPhotoEffectProcess"
    case Tonal = "CIPhotoEffectTonal"
    case Transfer =  "CIPhotoEffectTransfer"
    case Blur = "CIGaussianBlur"
}

// Define the t_bitmap_header structure (might need adjustments)
// 4*11 + 5*2 = 44 + 10 = 54
struct t_bitmap_header {
  var fileType: UInt16? // 2
  var fileSize: UInt32? // 4
  var reserved1: UInt16? // 2
  var reserved2: UInt16? // 2
  var bitmapOffset: UInt32?
  var headerSize: UInt32?
  var width: UInt32?
  var height: UInt32?
  var colorPlanes: UInt16?
  var bitsPerPixel: UInt16?
  var compression: UInt32?
  var bitmapSize: UInt32?
  var horizontalResolution: UInt32?
  var verticalResolution: UInt32?
  var colorsUsed: UInt32?
  var colorsImportant: UInt32?
}


extension UIImage {
    func addFilter(filter : FilterType) -> UIImage {
        let filter = CIFilter(name: filter.rawValue)
        // convert UIImage to CIImage and set as input
        let ciInput = CIImage(image: self)
        filter?.setValue(ciInput, forKey: "inputImage")
        // get output CIImage, render as CGImage first to retain proper UIImage scale
        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        //Return the image
        return UIImage(cgImage: cgImage!, scale: 1, orientation: .right)
    }
    
    func encodeBase64BMP() -> String {
        let bmpData = self.bitmapDataWithFileHeader()
        return bmpData!.base64EncodedString()
    }
    
    func encodeBase64(quality: Float) -> String {
        print("encodeBase64: \(quality)")
        var q: CGFloat = CGFloat(quality)
        if quality == 0 {
            q = 100
        }
        print("encodeBase64: \(quality)")
        print("image size: \(self.size.width)-\(self.size.height)")
        return self.jpegData(compressionQuality: CGFloat(q/100.0))?.base64EncodedString() ?? ""
    }
    
    func encodeBase64Png() -> String {
        print("encodeBase64Png")        
        return self.pngData()?.base64EncodedString() ?? ""
    }
    
    func decodeBase64(imageBase64String:String) -> UIImage {
        let imageData = Data(base64Encoded: imageBase64String)
        let image = UIImage(data: imageData!)
        return image!
    }
    
    
    func encodeBase64WebP(lossless: Bool) -> String {
        print("encodeBase64WebP: \(lossless)")
        print("image size: \(self.size.width)-\(self.size.height)")
        
        let WebPCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(WebPCoder)
        
        
        if (lossless) {
            let webpData = SDImageWebPCoder.shared.encodedData(with: self, format: .webP, options: [.encodeWebPLossless: true])
            print("losslessWebpData size: \(webpData?.count)")
            return webpData?.base64EncodedString() ?? ""
        } else {
            let webpData = SDImageWebPCoder.shared.encodedData(with: self, format: .webP, options: [.encodeCompressionQuality: 0.9]) // [0, 1]
            print("losslessWebpData size: \(webpData?.count)")
            return webpData?.base64EncodedString() ?? ""
        }
    }
    
    func decodeBase64WebP(imageBase64String:String) -> UIImage {
        let imageData = Data(base64Encoded: imageBase64String)
        
        let WebPCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(WebPCoder)
        let image = SDImageWebPCoder.shared.decodedImage(with: imageData, options: nil)        
        return image!
    }
    
    static func convert(pixelBuffer: CVPixelBuffer, orientation: UIImage.Orientation) -> UIImage {
        let ciContext = CIContext()
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        
        let cgimage: CGImage? = ciContext.createCGImage(ciImage, from: ciImage.extent)
        return UIImage(cgImage: cgimage!, scale: 1.0, orientation: orientation)
    }
    
    static func convert(pixelBuffer: UnsafeRawPointer, width: Int, height: Int, orientation: UIImage.Orientation) -> UIImage? {
        
        let colorSpace = CGColorSpaceCreateDeviceGray() // Force unwrapping safe color space
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        var cropBuffer = unsafeBitCast(pixelBuffer, to: UnsafeMutablePointer<Pixel_8>.self)
                
        
        // Create bitmap content with current image size and grayscale colorspace
        //let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        if let context: CGContext = CGContext(data: cropBuffer, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) {
            // Draw image into current context, with specified rectangle
            // using previously defined context (with grayscale colorspace)
         
            let cgImage = context.makeImage()
            return UIImage(cgImage: cgImage!, scale: 1.0, orientation: orientation)
        }
    
        return nil
    }
    
    func convertToGrayscale() -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        let filter = CIFilter(name: "CIPhotoEffectMono")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else { return nil }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    func getPixelData() -> [UInt8]? {
        guard let cgImage = self.cgImage,
              let provider = cgImage.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else { return nil }

        let bitsPerPixel = cgImage.bitsPerPixel
        let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height

        // Allocate memory for all pixel data
        var pixelData = [UInt8](repeating: 0, count: width * height * (bitsPerPixel/8))

        // Copy pixel data from original image to our array
        memcpy(&pixelData, bytes, CFDataGetLength(data))

        return pixelData
    }
    
    func getRGBPixelData() -> [UInt8]? {
        guard let cgImage = self.cgImage,
              let provider = cgImage.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else { return nil }

        //let bitsPerPixel = cgImage.bitsPerPixel
        //let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height

        // Allocate memory for all pixel data
        var pixelData = [UInt8](repeating: 0, count: width * height * 3)

        // Copy pixel data from original image to our array
        // BGRA 4bytes iOS
        for i in 0..<height {
            for j in 0..<width {
                pixelData[i*width*3+j*3] = bytes[i*width*4+j*4 + 2];
                pixelData[i*width*3+j*3+1] = bytes[i*width*4+j*4 + 1];
                pixelData[i*width*3+j*3+2] = bytes[i*width*4+j*4];
            }
        }
        //memcpy(&pixelData, bytes, CFDataGetLength(data))

        return pixelData
    }
    
    
    func getGrayPixelData() -> [UInt8]? {
        guard let cgImage = self.cgImage,
              let provider = cgImage.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else { return nil }

        let bitsPerPixel = cgImage.bitsPerPixel
        let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height

        // Allocate memory for all pixel data
        var pixelData = [UInt8](repeating: 0, count: width * height)

        // Copy pixel data from original image to our array
        
        for i in 0..<height {
            for j in 0..<width {
                pixelData[i*width+j] = bytes[i*width*4+j*4]/3 + bytes[i*width*4+j*4 + 1]/3 + bytes[i*width*4+j*4 + 2]/3;
            }
        }
        //memcpy(&pixelData, bytes, CFDataGetLength(data))

        return pixelData
    }
    
    static func convertGray(pixels: [UInt8], width: Int, height: Int) -> UIImage? {
        guard width > 0 && height > 0 else { return nil }
        guard pixels.count == width * height else { return nil }

        let grayColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 8

        var data = pixels // Copy to mutable []
        guard let providerRef = CGDataProvider(data: NSData(bytes: &data,
                                length: data.count)
            )
            else { return nil }

        guard let cgim = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: width,
            space: grayColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
            )
            else { return nil }

        return UIImage(cgImage: cgim)
    }
    
    func rotateRight() -> UIImage? {
        
        
        guard let cgImage = self.cgImage,
              let provider = cgImage.dataProvider,
              let colorSpace = cgImage.colorSpace,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else { return nil }
        
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let channel = 3
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        let bitsPerPixel = cgImage.bitsPerPixel
        let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height
        let bytePerPixel = bitsPerPixel/cgImage.bitsPerComponent
        
        var pixelData = [UInt8](repeating: 0, count: width * height * channel)

        for i in 0..<height {
            for j in 0..<width {
                for k in 0..<channel {
                    let offset = height - 1 - i
                    pixelData[j * height * channel + offset * channel + k] = bytes[i * bytesPerRow + j * bytePerPixel + k]
                }
            }
        }
        
        let rgbData = CFDataCreate(nil, pixelData, pixelData.count)!
        
        guard let providerRef = CGDataProvider(data: rgbData) else { return nil }

        guard let cgim = CGImage(
            width: height,
            height: width,
            bitsPerComponent: cgImage.bitsPerComponent,
            bitsPerPixel: cgImage.bitsPerComponent * channel,//bitsPerPixel,
            bytesPerRow: height * channel,
            space: rgbColorSpace,//colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
            )
            else { return nil }


        return UIImage(cgImage: cgim)
    }
    
    
    func rotateLeft() -> UIImage? {
        
        
        guard let cgImage = self.cgImage,
              let provider = cgImage.dataProvider,
              let colorSpace = cgImage.colorSpace,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else { return nil }
        
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let channel = 3
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        let bitsPerPixel = cgImage.bitsPerPixel
        let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height
        let bytePerPixel = bitsPerPixel/cgImage.bitsPerComponent
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytePerPixel)

        for i in 0..<height {
            for j in 0..<width {
                for k in 0..<channel {
                    pixelData[j * height * channel + i * channel + k] = bytes[i * bytesPerRow + j * bytePerPixel + k]
                }
            }
        }
        
        let rgbData = CFDataCreate(nil, pixelData, pixelData.count)!
        
        guard let providerRef = CGDataProvider(data: rgbData) else { return nil }

        guard let cgim = CGImage(
            width: height,
            height: width,
            bitsPerComponent: cgImage.bitsPerComponent,
            bitsPerPixel: cgImage.bitsPerComponent * channel,
            bytesPerRow: height * channel,
            space: rgbColorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
            )
            else { return nil }


        return UIImage(cgImage: cgim)
    }
    
    
    func bitmapData(bytesPerLine: Int) -> Data? {

        //let bytesPerPixel = 3
        //let bytesPerRow = width * bytesPerPixel

        //var rawData: UnsafeMutableRawPointer? = calloc(height * bytesPerRow, MemoryLayout<UInt8>.size)
        //guard let rawDataPtr = rawData else { return nil }
        //defer { free(rawData) }


        guard let cgImage = self.cgImage,
              let provider = cgImage.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else { return nil }

        let bitsPerPixel = cgImage.bitsPerPixel
        let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height
        let bytePerPixel = bitsPerPixel/8
        
        // Allocate memory for all pixel data
        var pixelData = [UInt8](repeating: 0, count: bytesPerLine * height)

        // Copy pixel data from original image to our array
        
        for i in stride(from: height-1, to: 0, by: -1) {
            for j in 0..<width {
                pixelData[i * bytesPerLine + j * 3 + 2] = bytes[i * bytesPerRow + j * bytePerPixel]
                pixelData[i * bytesPerLine + j * 3 + 1] = bytes[i * bytesPerRow + j * bytePerPixel + 1]
                pixelData[i * bytesPerLine + j * 3    ] = bytes[i * bytesPerRow + j * bytePerPixel + 2]
            }
        }
        return Data(bytes: pixelData, count: pixelData.count)
        
    }

    func bitmapFileHeaderData(width: Int, height: Int, bytesPerLine: Int) -> Data {
        var data = [UInt8](repeating: 0, count: 54)
        
        // fileType
        // var fileType = 0x4D42
        data[0] = 0x42
        data[1] = 0x4D
        // fileSize
        let fileSize = (UInt32)(height * bytesPerLine * 3) + 54
        data[5] = (UInt8)((fileSize >> 24) & 0xFF)
        data[4] = (UInt8)((fileSize >> 16) & 0xFF)
        data[3] = (UInt8)((fileSize >> 8) & 0xFF)
        data[2] = (UInt8)(fileSize & 0xFF)
        
        // var reserved1: UInt16? // 2
        data[6] = 0x00
        data[7] = 0x00
        // var reserved2: UInt16? // 2
        data[8] = 0x00
        data[9] = 0x00
        let bitmapOffset: UInt32 = 0x36
        data[13] = (UInt8)((bitmapOffset >> 24) & 0xFF)
        data[12] = (UInt8)((bitmapOffset >> 16) & 0xFF)
        data[11] = (UInt8)((bitmapOffset >> 8) & 0xFF)
        data[10] = (UInt8)(bitmapOffset & 0xFF)

        let headerSize: UInt32  = 0x28 // 40 bytes
        data[17] = (UInt8)((headerSize >> 24) & 0xFF)
        data[16] = (UInt8)((headerSize >> 16) & 0xFF)
        data[15] = (UInt8)((headerSize >> 8) & 0xFF)
        data[14] = (UInt8)(headerSize & 0xFF)
        
        //var width: UInt32?
        data[21] = (UInt8)((width >> 24) & 0xFF)
        data[20] = (UInt8)((width >> 16) & 0xFF)
        data[19] = (UInt8)((width >> 8) & 0xFF)
        data[18] = (UInt8)(width & 0xFF)

        //var height: UInt32?
        let h = -height
        data[25] = (UInt8)((h >> 24) & 0xFF)
        data[24] = (UInt8)((h >> 16) & 0xFF)
        data[23] = (UInt8)((h >> 8) & 0xFF)
        data[22] = (UInt8)(h & 0xFF)
        
        let colorPlanes: UInt16 = 0x0001
        data[27] = (UInt8)((colorPlanes >> 8) & 0xFF)
        data[26] = (UInt8)(colorPlanes & 0xFF)
        
        let bitsPerPixel: UInt16 = 0x0018 // 24bits
        data[29] = (UInt8)((bitsPerPixel >> 8) & 0xFF)
        data[28] = (UInt8)(bitsPerPixel & 0xFF)
        
        //var compression: UInt32?
        data[30] = 0x00
        data[31] = 0x00
        data[32] = 0x00
        data[33] = 0x00
        
        let bitmapSize: UInt32 = UInt32(width * height * 3)
        data[37] = (UInt8)((bitmapSize >> 24) & 0xFF)
        data[36] = (UInt8)((bitmapSize >> 16) & 0xFF)
        data[35] = (UInt8)((bitmapSize >> 8) & 0xFF)
        data[34] = (UInt8)(bitmapSize & 0xFF)
        
        let horizontalResolution: UInt32 = 1200
        data[41] = (UInt8)((horizontalResolution >> 24) & 0xFF)
        data[40] = (UInt8)((horizontalResolution >> 16) & 0xFF)
        data[39] = (UInt8)((horizontalResolution >> 8) & 0xFF)
        data[38] = (UInt8)(horizontalResolution & 0xFF)
        
        let verticalResolution: UInt32 = 1200
        data[45] = (UInt8)((verticalResolution >> 24) & 0xFF)
        data[44] = (UInt8)((verticalResolution >> 16) & 0xFF)
        data[43] = (UInt8)((verticalResolution >> 8) & 0xFF)
        data[42] = (UInt8)(verticalResolution & 0xFF)
        
        let colorsUsed: UInt32 = 0
        data[49] = (UInt8)((colorsUsed >> 24) & 0xFF)
        data[48] = (UInt8)((colorsUsed >> 16) & 0xFF)
        data[47] = (UInt8)((colorsUsed >> 8) & 0xFF)
        data[46] = (UInt8)(colorsUsed & 0xFF)
        let colorsImportant: UInt32 = 0
        data[53] = (UInt8)((colorsImportant >> 24) & 0xFF)
        data[52] = (UInt8)((colorsImportant >> 16) & 0xFF)
        data[51] = (UInt8)((colorsImportant >> 8) & 0xFF)
        data[50] = (UInt8)(colorsImportant & 0xFF)
        
        //return Data(bytes: &header, count: MemoryLayout<t_bitmap_header>.size)
        /*
        for i in 0..<54 {
            print(String(format:"%02X", data[i]))
        }
         */
        return Data(bytes: data, count: data.count)
    }

    func bitmapDataWithFileHeader() -> Data? {
        guard let cgImage = self.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        let bitpp = 24
        let bytesPerLine = 4*((width*bitpp+31)/32);
        
        guard let bitmapData = bitmapData(bytesPerLine: bytesPerLine) else { return nil }
        
        let headerData = self.bitmapFileHeaderData(width: width, height: height, bytesPerLine: bytesPerLine)
        return headerData + bitmapData
    }

    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
    
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /// Rotate the UIImage
    /// - Parameter orientation: Define the rotation orientation
    /// - Returns: Get the rotated image
    func rotateImage(orientation: UIImage.Orientation) -> UIImage? {
      guard let cgImage = self.cgImage else { return nil }
      switch orientation {
           case .right:
               return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
           case .down:
               return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
           case .left:
               return UIImage(cgImage: cgImage, scale: 1.0, orientation: .down)
           default:
               return UIImage(cgImage: cgImage, scale: 1.0, orientation: .left)
       }
    }
    
    func maskImage(mask:UIImage) -> UIImage? {
        if let imageReference = self.cgImage,
            let maskReference = mask.cgImage,
            let dataProvider = maskReference.dataProvider {

            if let imageMask = CGImage(maskWidth: maskReference.width,
                                       height: maskReference.height,
                                       bitsPerComponent: maskReference.bitsPerComponent,
                                       bitsPerPixel: maskReference.bitsPerPixel,
                                       bytesPerRow: maskReference.bytesPerRow,
                                       provider: dataProvider, decode: nil, shouldInterpolate: true) {

                if let maskedReference = imageReference.masking(imageMask) {
                    let maskedImage = UIImage(cgImage: maskedReference)
                    return maskedImage
                }
            }
        }
        return nil
    }
    
    
    static func createImage(size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let color = UIColor.clear
        color.setFill()
        UIRectFill(rect)
                
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    func drawText(position: CGPoint, size: CGSize, text: String) -> UIImage? {
        let imageView = UIImageView(image: self)
        imageView.backgroundColor = UIColor.clear
        imageView.frame = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        label.backgroundColor = UIColor.yellow
        label.textAlignment = .center
        label.textColor = UIColor.black
        label.text = text
        
        label.font = UIFont.systemFont(ofSize: 25)
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true


        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0)
        
        if let context = UIGraphicsGetCurrentContext() {
            imageView.layer.render(in: context)
            context.translateBy(x: position.x, y: position.y)
            label.layer.render(in: context)
            context.translateBy(x: 0, y: 0)
            let imageWithText = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return imageWithText
        } else {
            return nil
        }

    }
    
    func alpha(_ a: CGFloat) -> UIImage {
        return UIGraphicsImageRenderer(size: size, format: imageRendererFormat).image { (_) in
            draw(in: CGRect(origin: .zero, size: size), blendMode: .normal, alpha: a)
        }
    }
    
    func saveImageToDocumentDirectory() -> String {
        let directoryPath =  NSHomeDirectory().appending("/Documents/")
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddhhmmss"

        let filename = dateFormatter.string(from: Date()).appending(".jpg")
        let filepath = directoryPath.appending(filename)
        let url = NSURL.fileURL(withPath: filepath)
        do {
            try self.jpegData(compressionQuality: 1.0)?.write(to: url, options: .atomic)
            return String.init("/Documents/\(filename)")

        } catch {
            print(error)
            print("file cant not be save at path \(filepath), with error : \(error)");
            return filepath
        }
    }
    
    
    func saveImageToDocumentDirectory(filename: String) -> String {
        let directoryPath =  NSHomeDirectory().appending("/Documents/")
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddhhmmss"

        let filepath = directoryPath.appending(filename)
        let url = NSURL.fileURL(withPath: filepath)
        do {
            try self.jpegData(compressionQuality: 1.0)?.write(to: url, options: .atomic)
            return String.init("/Documents/\(filename)")

        } catch {
            print(error)
            print("file cant not be save at path \(filepath), with error : \(error)");
            return filepath
        }
    }
    
    func saveImageWebPToDocumentDirectory(filename: String, lossless: Bool) -> String {
        let directoryPath =  NSHomeDirectory().appending("/Documents/")
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }

        let filepath = directoryPath.appending(filename + ".webp")
        let url = NSURL.fileURL(withPath: filepath)
        do {
            
            let WebPCoder = SDImageWebPCoder.shared
            SDImageCodersManager.shared.addCoder(WebPCoder)
            
            if (lossless) {
                let webpData = SDImageWebPCoder.shared.encodedData(with: self, format: .webP, options: [.encodeWebPLossless: true])
                print("losslessWebpData size: \(webpData?.count)")
                try webpData!.write(to: url, options: .atomic)
            } else {
                let webpData = SDImageWebPCoder.shared.encodedData(with: self, format: .webP, options: [.encodeCompressionQuality: 0.9]) // [0, 1]
                print("losslessWebpData size: \(webpData?.count)")
                try webpData!.write(to: url, options: .atomic)
            }
            
            return String.init("/Documents/\(filename)")

        } catch {
            print(error)
            print("file cant not be save at path \(filepath), with error : \(error)");
            return filepath
        }
    }
    
    
    func saveImageBMPToDocumentDirectory(filename: String) -> String {
        let directoryPath =  NSHomeDirectory().appending("/Documents/")
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }

        let filepath = directoryPath.appending(filename + ".bmp")
        let url = NSURL.fileURL(withPath: filepath)
        do {
            
            let bmpData = self.bitmapDataWithFileHeader()
            try bmpData!.write(to: url, options: .atomic)
            return String.init("/Documents/\(filename)")

        } catch {
            print(error)
            print("file cant not be save at path \(filepath), with error : \(error)");
            return filepath
        }
    }
    
    func saveImageJpegToDocumentDirectory(filename: String, compression: Float) -> String {
        print("saveImageJpegToDocumentDirectory: \(filename) + \(compression)")
        let directoryPath =  NSHomeDirectory().appending("/Documents/")
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }

        let filepath = directoryPath.appending(filename + ".jpeg")
        let url = NSURL.fileURL(withPath: filepath)
        do {
            if let data = self.jpegData(compressionQuality: CGFloat(compression)/100.0) {
                try? data.write(to: url, options: .atomic)
            }
            return String.init("/Documents/\(filename)")
        } catch {
            print(error)
            print("file cant not be save at path \(filepath), with error : \(error)");
            return filepath
        }
    }
    
    func saveImagePngToDocumentDirectory(filename: String) -> String {
        let directoryPath =  NSHomeDirectory().appending("/Documents/")
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }

        let filepath = directoryPath.appending(filename + ".png")
        let url = NSURL.fileURL(withPath: filepath)
        do {
            if let data = self.pngData() {
                try? data.write(to: url, options: .atomic)
            }
            return String.init("/Documents/\(filename)")
        } catch {
            print(error)
            print("file cant not be save at path \(filepath), with error : \(error)");
            return filepath
        }
    }
    
    
    func resize(_ width: Int, _ height: Int) -> UIImage {
        // Keep aspect ratio
        let targetSize = CGSize(width: width, height: height)

        // Set scale of renderer so that 1pt == 1px
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        // Resize the image
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resized
    }
}
