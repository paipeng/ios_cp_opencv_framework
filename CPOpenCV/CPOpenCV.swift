//
//  CPOpenCV.swift
//  CPOpenCV
//
//  Created by Pai Peng on 26.09.24.
//

import Foundation
import UIKit

//import "CPOpenCV-Bridging-Header.h"


public class CPOpenCV {
    init() {
        
    }
    
    func getVersion() ->String {
        return String(cString: getOpenCVVersion())
    }
    
    func convertGray(image: UIImage?) -> UIImage? {
        guard let rgbData = image?.getRGBPixelData() else { return nil }
        let uint8_pointer = UnsafeMutablePointer<UInt8>(mutating: rgbData);
        let width: Int32 = Int32((image?.size.width)!)
        let height: Int32 = Int32((image?.size.height)!)
        var pixelData = [UInt8](repeating: 0, count: Int(width * height))
        
        let grayData = convertGrayscale(uint8_pointer, 0, width, height, UnsafeMutablePointer<UInt8>(mutating: pixelData))
        

        let grayImage = UIImage.convert(pixelBuffer: pixelData, width: Int(width), height: Int(height), orientation: UIImage.Orientation.up)
        return grayImage
    }
}
