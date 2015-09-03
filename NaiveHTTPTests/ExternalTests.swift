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
    
    func testNormalizedURL() {
        let testQueryParams = ["a":"123","b":"456"]
        let url = NaiveHTTP.normalizedURL(uri: "http://example.com", params: testQueryParams)
        XCTAssertEqual(NSURL(string: "http://example.com?a=123&b=456"), url)
    }
    
    func testNormalizedURLWithExistingQueryParameters() {
        let testQueryParams = ["a":"123","b":"456"]
        let url = NaiveHTTP.normalizedURL(uri: "http://example.com?c=xxx&d=yyy", params: testQueryParams)
        XCTAssertEqual(NSURL(string: "http://example.com?a=123&b=456&c=xxx&d=yyy"), url)
    }
    
    func testNormalizedURLWithNilQueryParam() {
        let url = NaiveHTTP.normalizedURL(uri: "http://example.com", params: nil)
        let expectedURL = NSURL(string: "http://example.com")
        XCTAssertEqual(expectedURL, url)
    }
    
    func testJSONGETWithParams() {
        let naive = NaiveHTTP(configuration: nil)
        let testURI = "https://httpbin.org/get"
        let params = ["herp":"derp"]
        
        let networkExpectation = self.expectationWithDescription("naive network expectation")
        
        naive.jsonGET(uri: testURI, params: params, success: { (json) -> () in
            XCTAssertNil(json.error)
            XCTAssertEqual("derp", json["args"]["herp"])
            networkExpectation.fulfill()
            }) { (error) -> Void in
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
    
    func testPostWithAdditionalHeaders() {
        let naive = NaiveHTTP(configuration: nil)
        let networkExpectation = self.expectationWithDescription("naive network expectation")
        let postObject = ["herp":"derp"];
        let additionalHeaders = ["X-Some-Custom-Header":"hey-hi-ho"]
        
        naive.post(uri: "https://httpbin.org/post", postObject: postObject, additionalHeaders: additionalHeaders, success: { (responseJSON) -> Void in
            XCTAssertEqual("hey-hi-ho", responseJSON["headers"]["X-Some-Custom-Header"].string)
            networkExpectation.fulfill()
            }) { (error) -> Void in
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
            }) { (error) -> Void in
                XCTFail()
                networkExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPOSTWithNilPostBody() {
        let naive = NaiveHTTP(configuration: nil)
        let networkExpectation = self.expectationWithDescription("naive network expectation")
        
        naive.post(uri: "https://httpbin.org/post", postObject: nil, success: { (responseJSON) -> Void in
            XCTAssertEqual(JSON(NSNull()), responseJSON["json"])
            networkExpectation.fulfill()
            }) { (error) -> Void in
                XCTFail()
                networkExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPOSTError() {
        let naive = NaiveHTTP(configuration: nil)
        let networkExpectation = self.expectationWithDescription("naive network expectation")
        let postObject = ["herp":"derp"];
        
        naive.post(uri: "http://httpbin.org/status/500", postObject: postObject, success: { (responseJSON) -> Void in
            XCTFail()
            networkExpectation.fulfill()
            }) { (error) -> Void in
                XCTAssertEqual(error.code, 400)
                XCTAssertEqual("HTTP Error 500", error.userInfo[NSLocalizedDescriptionKey] as? String)
                networkExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
}
