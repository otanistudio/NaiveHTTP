//
//  ExternalFreddyHTTPTests.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 5/6/16.
//  Copyright © 2016 otanistudio.com. All rights reserved.
//

import XCTest
import Freddy

class ExternalFreddyHTTPTests: XCTestCase {
    let networkTimeout = 2.0
    var networkExpectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        networkExpectation = self.expectationWithDescription("naive network expectation")
    }

    func testJSONGETWithParams() {
        let freddyHTTP = FreddyHTTP()
        let params = ["herp":"derp"]
        let uri = URI.loc("get")
        
        freddyHTTP.GET(
            uri,
            params:params,
            responseFilter: nil,
            headers: nil) { (json, response, error) -> () in
                XCTAssertNil(error)
                XCTAssertEqual("derp", json!["args"]!["herp"])
                let httpResp = response as! NSHTTPURLResponse
                XCTAssertEqual(uri+"?herp=derp", httpResp.URL!.absoluteString)
                self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testGETWithPreFilter() {
        let freddyHTTP = FreddyHTTP()
        let prefixFilter = "while(1);</x>"
        let url = NSBundle(forClass: self.dynamicType).URLForResource("hijack_guarded", withExtension: "json")
        let uri = url?.absoluteString
        
        freddyHTTP.GET(uri!, params: nil, responseFilter: prefixFilter, headers: nil) { (json, response, error) -> () in
            XCTAssertNil(error)
            let jDict = ["feh" : "bleh"].toJSON()
            XCTAssertEqual(jDict, json)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOST() {
        let freddyHTTP = FreddyHTTP()
        let postObject = ["herp":"derp"]
        let expectedResponseJSON = postObject.toJSON()
        
        freddyHTTP.POST(URI.loc("post"), postObject: postObject, responseFilter: nil, headers: nil) { json, response, error in
            XCTAssertNil(error)
            XCTAssertEqual(expectedResponseJSON, json!["json"])
            let httpResp = response as! NSHTTPURLResponse
            XCTAssertEqual(URI.loc("post"), httpResp.URL!.absoluteString)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOSTWithAdditionalHeaders() {
        let freddyHTTP = FreddyHTTP()
        let postObject = ["herp":"derp"];
        let additionalHeaders = ["X-Some-Custom-Header":"hey-hi-ho"]
        
        freddyHTTP.POST(URI.loc("post"), postObject: postObject, responseFilter: nil, headers: additionalHeaders) { (json, response, error) -> () in
            XCTAssertNil(error)
            XCTAssertEqual("hey-hi-ho", json!["headers"]!["X-Some-Custom-Header"])
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOSTWithNilPostBody() {
        let freddyHTTP = FreddyHTTP()
        
        freddyHTTP.POST(URI.loc("post"), postObject: nil, responseFilter: nil, headers: nil) { (json, response, error) -> () in
            XCTAssertNil(error)
            XCTAssertEqual(JSON.Null, json!["json"])
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOSTError() {
        let freddyHTTP = FreddyHTTP()
        let postObject = ["herp":"derp"];
        
        freddyHTTP.POST(URI.loc("status/500"), postObject: postObject, responseFilter: nil, headers: nil) { (json, response, error) -> () in
            
            XCTAssertNil(json)
            XCTAssertEqual(500, error!.code)
            XCTAssertEqual("HTTP Error 500", error!.userInfo[NSLocalizedDescriptionKey] as? String)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPOSTWithPreFilter() {
        let freddyHTTP = FreddyHTTP()
        let prefixFilter = "while(1);</x>"
        let url = NSBundle(forClass: self.dynamicType).URLForResource("hijack_guarded", withExtension: "json")
        let uri = url?.absoluteString
        
        freddyHTTP.POST(uri!, postObject: nil, responseFilter: prefixFilter, headers: nil) { (json, response, error) -> () in
            XCTAssertNil(error)
            XCTAssertEqual(JSON(["feh":"bleh"]), json)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONPUT() {
        let freddyHTTP = FreddyHTTP()
        let putBody = ["put":"this"];
        
        freddyHTTP.PUT(URI.loc("put"), body: putBody, responseFilter: nil, headers: nil) { (json, response, error) -> Void in
            XCTAssertNil(error)
            XCTAssertEqual("this", json!["json"]!["put"])
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testJSONDELETE() {
        let freddyHTTP = FreddyHTTP()
        let deleteBody = ["delete":"this"];
        
        freddyHTTP.DELETE(URI.loc("delete"), body: deleteBody, responseFilter: nil, headers: nil) { (json, response, error) -> Void in
            XCTAssertNil(error)
            XCTAssertEqual("this", json!["json"]!["delete"])
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
}
