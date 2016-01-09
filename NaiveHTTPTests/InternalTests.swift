//
//  InternalTests.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 1/8/16.
//  Copyright © 2016 otanistudio.com. All rights reserved.
//

import XCTest

class InternalTests: XCTestCase {
    
    let timeout = 1.0
    
    override func setUp() {
        super.setUp()
    }
    
    func testBadURIString() {
        let naive = NaiveHTTP()
        let errorExpectation = self.expectationWithDescription("error expectation")
        naive.performRequest(.GET, uri: "not an url string people", body: nil, headers: nil) { (data, response, error) -> Void in
            XCTAssertEqual(error?.userInfo[NSLocalizedFailureReasonErrorKey] as? String, "could not create NSURL from string")
            errorExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
}
