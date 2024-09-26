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

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
