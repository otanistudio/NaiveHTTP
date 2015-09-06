//
//  ExternalTests.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/24/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import XCTest
import NaiveHTTP

class ExternalTests: XCTestCase {
    
    let networkTimeout = 2.0
    var networkExpectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        networkExpectation = self.expectationWithDescription("naive network expectation")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testJSONGETWithParams() {
        let naive = NaiveHTTP(configuration: nil)
        let testURI = "https://httpbin.org/get"
        let params = ["herp":"derp"]
        
        naive.GET(testURI, params: params, successJSON: { (json, response) -> () in
                XCTAssertNil(json.error)
                XCTAssertEqual("derp", json["args"]["herp"])
                let httpResp = response as! NSHTTPURLResponse
                XCTAssertEqual(testURI+"?herp=derp", httpResp.URL!.absoluteString)
                self.networkExpectation!.fulfill()
            }) { (error) -> Void in
                XCTFail()
                self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testBadImageGET() {
        let naive = NaiveHTTP(configuration: nil)

        naive.GET("http://httpbin.org/image/webp", successImage: { (image, response) -> () in
                XCTAssertNil(image)
               self.networkExpectation!.fulfill()
            }) { (error) -> () in
                XCTFail()
                self.networkExpectation!.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPNGImageGET() {
        let naive = NaiveHTTP(configuration: nil)
        
        naive.GET("http://httpbin.org/image/png", successImage: { (image, response) -> () in
                XCTAssertNotNil(image)
                self.networkExpectation!.fulfill()
            }) { (error) -> () in
                XCTFail()
                self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testImage404() {
        let naive = NaiveHTTP(configuration: nil)
        
        naive.GET("http://httpbin.org/status/404", successImage: { (image, response) -> () in
            XCTFail()
            self.networkExpectation!.fulfill()
            }) { (error) -> () in
                XCTAssertEqual(404, error.code)
                self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPostWithAdditionalHeaders() {
        let naive = NaiveHTTP(configuration: nil)
        let postObject = ["herp":"derp"];
        let additionalHeaders = ["X-Some-Custom-Header":"hey-hi-ho"]
        
        naive.POST("https://httpbin.org/post", postObject: postObject, additionalHeaders: additionalHeaders, success: { (responseJSON, response) -> Void in
                XCTAssertEqual("hey-hi-ho", responseJSON["headers"]["X-Some-Custom-Header"].string)
                self.networkExpectation!.fulfill()
            }) { (error) -> Void in
                XCTFail()
                self.networkExpectation!.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPOST() {
        let naive = NaiveHTTP(configuration: nil)
        let postObject = ["herp":"derp"];
        let expectedResponseJSON = JSON(postObject)
        
        naive.POST("https://httpbin.org/post", postObject: postObject, success: { (responseJSON, response) -> Void in
                XCTAssertEqual(expectedResponseJSON, responseJSON.dictionary!["json"])
                let httpResp = response as! NSHTTPURLResponse
                XCTAssertEqual("https://httpbin.org/post", httpResp.URL!.absoluteString)
                self.networkExpectation!.fulfill()
            }) { (error) -> Void in
                XCTFail()
                self.networkExpectation!.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPOSTWithNilPostBody() {
        let naive = NaiveHTTP(configuration: nil)
        
        naive.POST("https://httpbin.org/post", postObject: nil, success: { (responseJSON, response) -> Void in
                XCTAssertEqual(JSON(NSNull()), responseJSON["json"])
                self.networkExpectation!.fulfill()
            }) { (error) -> Void in
                XCTFail()
                self.networkExpectation!.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPOSTError() {
        let naive = NaiveHTTP(configuration: nil)
        let postObject = ["herp":"derp"];
        
        naive.POST("http://httpbin.org/status/500", postObject: postObject, success: { (responseJSON) -> Void in
                XCTFail()
                self.networkExpectation!.fulfill()
            }) { (error) -> Void in
                XCTAssertEqual(error.code, 500)
                XCTAssertEqual("HTTP Error 500", error.userInfo[NSLocalizedDescriptionKey] as? String)
                self.networkExpectation!.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testGETWithPreFilter() {
        let naive = NaiveHTTP(configuration: nil)
        let prefixFilter = "while(1);</x>"
        let url = NSBundle(forClass: self.dynamicType).URLForResource("hijack_guarded", withExtension: "json")
        let uri = url?.absoluteString
    
        naive.GET(uri!, params: nil, responseFilter:prefixFilter, successJSON: { (json, response) -> () in
                XCTAssertEqual(JSON(["feh":"bleh"]), json)
                self.networkExpectation!.fulfill()
            }) { (error) -> Void in
                XCTFail(error.description)
                self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPOSTWithPreFilter() {
        let naive = NaiveHTTP(configuration: nil)
        let prefixFilter = "while(1);</x>"
        let url = NSBundle(forClass: self.dynamicType).URLForResource("hijack_guarded", withExtension: "json")
        let uri = url?.absoluteString
        
        naive.POST(uri!, postObject: nil, preFilter: prefixFilter, additionalHeaders: nil, success: { (responseJSON, response) -> () in
                XCTAssertEqual(JSON(["feh":"bleh"]), responseJSON)
                self.networkExpectation!.fulfill()
            }) { (postError) -> () in
                XCTFail(postError.description)
                self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
}
