//
//  ImageCache4ASDKTests.swift
//  ImageCache4ASDKTests
//
//  Created by Pikaurd Chen on 4/17/15.
//  Copyright (c) 2015 Shanghai Zuijiao Infomation Technology Inc. All rights reserved.
//

import UIKit
import XCTest

class ImageCache4ASDKTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testConvertFileUrlToString() {
        let url = NSURL(fileURLWithPath: "/root/suba/subb/")
        let folderUrl = url!.URLByAppendingPathComponent("cache").absoluteString!
        let path = folderUrl.substringFromIndex(advance(folderUrl.startIndex, 7))
        
        XCTAssert(path == "/root/suba/subb/cache", "Convert failed")
    }
    
}
