//
//  ExternalFreddyHTTPTests.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 5/6/16.
//  Copyright © 2016 otanistudio.com. All rights reserved.
//

import XCTest

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
                XCTAssertEqual("derp", try! json?.dictionary("args")["herp"])
                let httpResp = response as! NSHTTPURLResponse
                XCTAssertEqual(uri+"?herp=derp", httpResp.URL!.absoluteString)
                self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
}
