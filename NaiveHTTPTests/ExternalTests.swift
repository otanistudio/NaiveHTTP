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
        
        naive.GET(uri: testURI, params: params, successJSON: { (json, response) -> () in
            XCTAssertNil(json.error)
            XCTAssertEqual("derp", json["args"]["herp"])
            let httpResp = response as! NSHTTPURLResponse
            XCTAssertEqual(testURI+"?herp=derp", httpResp.URL!.absoluteString)
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

        naive.GET(uri: "http://httpbin.org/image/webp", successImage: { (image, response) -> () in
            XCTAssertNil(image)
            networkExpectation.fulfill()
            }) { (error) -> () in
                XCTFail()
                networkExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPNGImageGET() {
        let naive = NaiveHTTP(configuration: nil)
        
        let networkExpectation = self.expectationWithDescription("naive network expectation")
        
        naive.GET(uri: "http://httpbin.org/image/png", successImage: { (image, response) -> () in
            XCTAssertNotNil(image)
            networkExpectation.fulfill()
            }) { (error) -> () in
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
        
        naive.POST(uri: "https://httpbin.org/post", postObject: postObject, additionalHeaders: additionalHeaders, success: { (responseJSON, response) -> Void in
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
        
        naive.POST(uri: "https://httpbin.org/post", postObject: postObject, success: { (responseJSON, response) -> Void in
            XCTAssertEqual(expectedResponseJSON, responseJSON.dictionary!["json"])
            let httpResp = response as! NSHTTPURLResponse
            XCTAssertEqual("https://httpbin.org/post", httpResp.URL!.absoluteString)
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
        
        naive.POST(uri: "https://httpbin.org/post", postObject: nil, success: { (responseJSON, response) -> Void in
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
        
        naive.POST(uri: "http://httpbin.org/status/500", postObject: postObject, success: { (responseJSON) -> Void in
            XCTFail()
            networkExpectation.fulfill()
            }) { (error) -> Void in
                XCTAssertEqual(error.code, 400)
                XCTAssertEqual("HTTP Error 500", error.userInfo[NSLocalizedDescriptionKey] as? String)
                networkExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testGETWithPreFilter() {
        let naive = NaiveHTTP(configuration: nil)
        let networkExpectation = self.expectationWithDescription("naive network expectation")
        let prefixFilter = "while(1);</x>"
        let url = NSBundle(forClass: self.dynamicType).URLForResource("hijack_guarded", withExtension: "json")
        let uri = url?.absoluteString
    
        naive.get(uri: uri!, params: nil, responseFilter:prefixFilter, success: { (json, response) -> () in
                XCTAssertEqual(JSON(["feh":"bleh"]), json)
                networkExpectation.fulfill()
            }) { (error) -> Void in
                XCTFail(error.description)
                networkExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPOSTWithPreFilter() {
        let naive = NaiveHTTP(configuration: nil)
        let networkExpectation = self.expectationWithDescription("naive network expectation")
        let prefixFilter = "while(1);</x>"
        let url = NSBundle(forClass: self.dynamicType).URLForResource("hijack_guarded", withExtension: "json")
        let uri = url?.absoluteString
        
        naive.POST(uri: uri!, postObject: nil, preFilter: prefixFilter, additionalHeaders: nil
            , success: { (responseJSON, response) -> () in
                XCTAssertEqual(JSON(["feh":"bleh"]), responseJSON)
                networkExpectation.fulfill()
            }) { (postError) -> () in
                XCTFail(postError.description)
                networkExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
}
