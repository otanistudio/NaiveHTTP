//
//  ExternalTests.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/24/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import XCTest

class ExternalTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testJSONGET() {
        let naive = NaiveHTTP(configuration: nil)
        let testURI = "http://otanistudio.com/feh/derp.json"
        
        let networkExpectation = self.expectationWithDescription("naive network expectation")
        
        naive.jsonGET(uri: testURI, success: { (json) -> () in
            XCTAssertTrue(json.error == nil)
            let expectedString = NSString(string: "{\"herp\":\"derp\"}")
            let expectedData = expectedString.dataUsingEncoding(NSUTF8StringEncoding)
            let expectedJSON = JSON(data: expectedData!)
            XCTAssertEqual(expectedJSON, json)
            networkExpectation.fulfill()
            }) { () -> () in
                XCTFail()
                networkExpectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(1.0) { (error) -> Void in
            
        }
    }
    
    
}
