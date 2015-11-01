//
//  ExternalSwiftyJSONTests.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 10/31/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import XCTest

class ExternalSwiftyJSONTests: XCTestCase {
    struct URI {
        static func loc(path: String) -> String {
            return "\(localServerURI)/\(path)"
        }
    }
    
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
        let naive = NaiveHTTP()
        let params = ["herp":"derp"]
        let uri = URI.loc("get")
        
        naive.jsonGET(
            uri,
            params:params,
            responseFilter: nil,
            headers: nil) { (json, response, error) -> () in
                
                XCTAssertNil(error)
                XCTAssertEqual("derp", json!["args"]["herp"])
                let httpResp = response as! NSHTTPURLResponse
                XCTAssertEqual(uri+"?herp=derp", httpResp.URL!.absoluteString)
                self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testGETWithPreFilter() {
        let naive = NaiveHTTP()
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
    
    func testJSONPOST() {
        let naive = NaiveHTTP()
        let postObject = ["herp":"derp"];
        let expectedResponseJSON = JSON(postObject)
        
        naive.jsonPOST(URI.loc("post"), postObject: postObject, responseFilter: nil, headers: nil) { (json, response, error) -> () in
            XCTAssertNil(error)
            XCTAssertEqual(expectedResponseJSON, json!.dictionary!["json"])
            let httpResp = response as! NSHTTPURLResponse
            XCTAssertEqual(URI.loc("post"), httpResp.URL!.absoluteString)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOSTWithAdditionalHeaders() {
        let naive = NaiveHTTP()
        let postObject = ["herp":"derp"];
        let additionalHeaders = ["X-Some-Custom-Header":"hey-hi-ho"]
        
        naive.jsonPOST(URI.loc("post"), postObject: postObject, responseFilter: nil, headers: additionalHeaders) { (json, response, error) -> () in
            XCTAssertNil(error)
            XCTAssertEqual("hey-hi-ho", json!["headers"]["X-Some-Custom-Header"].string)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOSTWithNilPostBody() {
        let naive = NaiveHTTP()
        
        naive.jsonPOST(URI.loc("post"), postObject: nil, responseFilter: nil, headers: nil) { (json, response, error) -> () in
            XCTAssertNil(error)
            XCTAssertEqual(JSON(NSNull()), json!["json"])
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOSTError() {
        let naive = NaiveHTTP()
        let postObject = ["herp":"derp"];
        
        naive.jsonPOST(URI.loc("status/500"), postObject: postObject, responseFilter: nil, headers: nil) { (json, response, error) -> () in
            
            XCTAssertNil(json)
            XCTAssertEqual(500, error!.code)
            XCTAssertEqual("HTTP Error 500", error!.userInfo[NSLocalizedDescriptionKey] as? String)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOSTWithPreFilter() {
        let naive = NaiveHTTP()
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
    
    func testJSONPUT() {
        let naive = NaiveHTTP()
        let putBody = ["put":"this"];
        
        naive.jsonPUT(URI.loc("put"), body: putBody, responseFilter: nil, headers: nil) { (json, response, error) -> Void in
            XCTAssertNil(error)
            XCTAssertEqual("this", json!.dictionary!["json"]!["put"])
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONDELETE() {
        let naive = NaiveHTTP()
        let deleteBody = ["delete":"this"];
        
        naive.jsonDELETE(URI.loc("delete"), body: deleteBody, responseFilter: nil, headers: nil) { (json, response, error) -> Void in
            XCTAssertNil(error)
            XCTAssertEqual("this", json!.dictionary!["json"]!["delete"])
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
}