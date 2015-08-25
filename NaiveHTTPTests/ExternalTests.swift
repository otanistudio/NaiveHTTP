//
//  ExternalTests.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/24/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import XCTest

class ExternalTests: XCTestCase {
    
    let networkTimeout = 2.0
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testJSONGET() {
        let naive = NaiveHTTP(configuration: nil)
        let testURI = "https://httpbin.org/get?herp=derp"
        
        let networkExpectation = self.expectationWithDescription("naive network expectation")
        
        naive.jsonGET(uri: testURI, success: { (json) -> () in
            XCTAssertNil(json.error)
            XCTAssertEqual("derp", json["args"]["herp"])
            networkExpectation.fulfill()
            }) { () -> () in
                XCTFail()
                networkExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testBadImageGET() {
        let naive = NaiveHTTP(configuration: nil)
        
        let networkExpectation = self.expectationWithDescription("naive network expectation")

        naive.imageGET(uri: "http://httpbin.org/image/webp", success: { (image) -> () in
            XCTAssertNil(image)
            networkExpectation.fulfill()
            }) { () -> () in
                XCTFail()
                networkExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPNGImageGET() {
        let naive = NaiveHTTP(configuration: nil)
        
        let networkExpectation = self.expectationWithDescription("naive network expectation")
        
        naive.imageGET(uri: "http://httpbin.org/image/png", success: { (image) -> () in
            XCTAssertNotNil(image)
            networkExpectation.fulfill()
            }) { () -> () in
                XCTFail()
                networkExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOST() {
        let naive = NaiveHTTP(configuration: nil)
        let networkExpectation = self.expectationWithDescription("naive network expectation")
        let postString = NSString(string: "{\"herp\":\"derp\"}")
        let postData = postString.dataUsingEncoding(NSUTF8StringEncoding)
        let postJSON = JSON(data: postData!)
        naive.jsonPOST(uri: "https://httpbin.org/post", postData: postJSON, success: { (json) -> Void in
            debugPrint(json)
            XCTAssertEqual("derp", json["json"]["herp"])
            networkExpectation.fulfill()
            }) { () -> Void in
                XCTFail()
                networkExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPOST() {
        let naive = NaiveHTTP(configuration: nil)
        let networkExpectation = self.expectationWithDescription("naive network expectation")
        let postObject = ["herp":"derp"];
        let expectedResponseJSON = JSON(postObject)
        
        naive.post(uri: "https://httpbin.org/post", postObject: postObject, success: { (responseJSON) -> Void in
            XCTAssertEqual(expectedResponseJSON, responseJSON.dictionary!["json"])
            networkExpectation.fulfill()
            }) { () -> Void in
                XCTFail()
                networkExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
}
