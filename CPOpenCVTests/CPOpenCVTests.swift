//
//  CPOpenCVTests.swift
//  CPOpenCVTests
//
//  Created by Pai Peng on 26.09.24.
//

import XCTest


@testable import CPOpenCV


final class CPOpenCVTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    

    func testGetCPOpenCVVersion() throws {
        let frameworkBundle = Bundle(identifier: "com.paipeng.CPOpenCV")
        let frameworkVersion = frameworkBundle?.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            
        print("cpopencv: \(frameworkVersion)")
    }

    func testGetOpenCVVersion() throws {
        //let ver = CPOpenCV.CPOpenCVVersionString
        let str = String(cString: getOpenCVVersion())
        print("opencv: \(str)")
    }
    
    func testGetOpenCVVersionViaWrapper() throws {
        let cpopencv = CPOpenCV()
        print("opencv: \(cpopencv.getVersion())")
    }

    
    func testImageConvert() throws {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "qrcode", ofType: "png")!
        let image = UIImage(contentsOfFile: path)
        XCTAssertNotNil(image)
        
        guard let rgbData = image?.getRGBPixelData() else { return }
        let uint8_pointer = UnsafeMutablePointer<UInt8>(mutating: rgbData);
        let width: Int32 = Int32((image?.size.width)!)
        let height: Int32 = Int32((image?.size.height)!)
        var pixelData = [UInt8](repeating: 0, count: Int(width * height))
        
        let grayData = convertGrayscale(uint8_pointer, 0, width, height, UnsafeMutablePointer<UInt8>(mutating: pixelData))
        

        let grayImage = UIImage.convert(pixelBuffer: pixelData, width: Int(width), height: Int(height), orientation: UIImage.Orientation.up)
        XCTAssertNotNil(grayImage)
    }
    
    
    func testImageConvertViaWrapper() throws {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "qrcode", ofType: "png")!
        let image = UIImage(contentsOfFile: path)
        XCTAssertNotNil(image)
        let cpopencv = CPOpenCV()
        let grayImage = cpopencv.convertGray(image: image)
        XCTAssertNotNil(grayImage)
    }
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
