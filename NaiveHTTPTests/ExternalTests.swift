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

        naive.jsonGET(
            testURI,
            params:params,
            responseFilter: nil,
            headers: nil) { (json, response, error) -> () in
                
            XCTAssertNil(error)
            XCTAssertEqual("derp", json!["args"]["herp"])
            let httpResp = response as! NSHTTPURLResponse
            XCTAssertEqual(testURI+"?herp=derp", httpResp.URL!.absoluteString)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testGETWithError() {
        let naive = NaiveHTTP(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
        naive.GET("http://httpbin.org/status/400", params: nil, headers: nil) { (data, response, error) -> Void in
            XCTAssertEqual(400, error?.code)
            self.networkExpectation!.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testBadImageGET() {
        let naive = NaiveHTTP(configuration: nil)

        naive.imageGET("http://httpbin.org/image/webp") { (image, response, error) -> () in
            XCTAssertEqual("nil UIImage", error?.userInfo[NSLocalizedFailureReasonErrorKey] as? String)
            XCTAssertNil(image)
            XCTAssertNotNil(response)
            self.networkExpectation!.fulfill()

        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPNGImageGET() {
        let naive = NaiveHTTP(configuration: nil)
        
        naive.imageGET("http://httpbin.org/image/png") { (image, response, error) -> () in
            XCTAssertNotNil(image)
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testImage404() {
        let naive = NaiveHTTP(configuration: nil)
        
        naive.imageGET("http://httpbin.org/status/404") { (image, response, error) -> () in
            XCTAssertEqual(404, error!.code)
            XCTAssertNil(image)
            XCTAssertNotNil(response)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPOSTFormEncoded() {
        let naive = NaiveHTTP(configuration: nil)
        let postString = "blah=blee&hey=this+is+a+string+folks"
        let formEncodedHeader = [
            "Content-Type" : "application/x-www-form-urlencoded"
        ]
        
        naive.POST("http://httpbin.org/post", postObject: postString, headers: formEncodedHeader) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let parsedResult = JSON(data: data!)
            let receivedFormInfo = parsedResult["form"]
            XCTAssertEqual("blee", receivedFormInfo["blah"])
            XCTAssertEqual("this is a string folks", receivedFormInfo["hey"])
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPOSTWithAdditionalHeaders() {
        let naive = NaiveHTTP(configuration: nil)
        let postObject = ["herp":"derp"];
        let additionalHeaders = ["X-Some-Custom-Header":"hey-hi-ho"]
        
        naive.jsonPOST("https://httpbin.org/post", postObject: postObject, responseFilter: nil, headers: additionalHeaders) { (json, response, error) -> () in
            XCTAssertNil(error)
            XCTAssertEqual("hey-hi-ho", json!["headers"]["X-Some-Custom-Header"].string)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPUT() {
        let naive = NaiveHTTP(configuration: nil)
        let putBody = ["put":"this"];
    
        naive.PUT("https://httpbin.org/put", body: putBody, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let parsedResult = JSON(data: data!)
            XCTAssertEqual("this", parsedResult["json"]["put"])
            self.networkExpectation!.fulfill()
        }
    
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPUT() {
        let naive = NaiveHTTP(configuration: nil)
        let putBody = ["put":"this"];
        
        naive.jsonPUT("https://httpbin.org/put", body: putBody, responseFilter: nil, headers: nil) { (json, response, error) -> Void in
            XCTAssertNil(error)
            XCTAssertEqual("this", json!.dictionary!["json"]!["put"])
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)    }
    
    func testJSONPOST() {
        let naive = NaiveHTTP(configuration: nil)
        let postObject = ["herp":"derp"];
        let expectedResponseJSON = JSON(postObject)
        
        naive.jsonPOST("https://httpbin.org/post", postObject: postObject, responseFilter: nil, headers: nil) { (json, response, error) -> () in
            XCTAssertNil(error)
            XCTAssertEqual(expectedResponseJSON, json!.dictionary!["json"])
            let httpResp = response as! NSHTTPURLResponse
            XCTAssertEqual("https://httpbin.org/post", httpResp.URL!.absoluteString)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOSTWithNilPostBody() {
        let naive = NaiveHTTP(configuration: nil)
        
        naive.jsonPOST("https://httpbin.org/post", postObject: nil, responseFilter: nil, headers: nil) { (json, response, error) -> () in
            XCTAssertNil(error)
            XCTAssertEqual(JSON(NSNull()), json!["json"])
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOSTError() {
        let naive = NaiveHTTP(configuration: nil)
        let postObject = ["herp":"derp"];
        
        naive.jsonPOST("http://httpbin.org/status/500", postObject: postObject, responseFilter: nil, headers: nil) { (json, response, error) -> () in
            
            XCTAssertNil(json)
            XCTAssertEqual(500, error!.code)
            XCTAssertEqual("HTTP Error 500", error!.userInfo[NSLocalizedDescriptionKey] as? String)
            self.networkExpectation!.fulfill()

        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testGETWithPreFilter() {
        let naive = NaiveHTTP(configuration: nil)
        let prefixFilter = "while(1);</x>"
        let url = NSBundle(forClass: self.dynamicType).URLForResource("hijack_guarded", withExtension: "json")
        let uri = url?.absoluteString
        
        naive.jsonGET(uri!, params: nil, responseFilter: prefixFilter, headers: nil) { (json, response, error) -> () in
            XCTAssertNil(error)
            XCTAssertEqual(JSON(["feh":"bleh"]), json)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOSTWithPreFilter() {
        let naive = NaiveHTTP(configuration: nil)
        let prefixFilter = "while(1);</x>"
        let url = NSBundle(forClass: self.dynamicType).URLForResource("hijack_guarded", withExtension: "json")
        let uri = url?.absoluteString
        
        naive.jsonPOST(uri!, postObject: nil, responseFilter: prefixFilter, headers: nil) { (json, response, error) -> () in
            XCTAssertNil(error)
            XCTAssertEqual(JSON(["feh":"bleh"]), json)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
}
