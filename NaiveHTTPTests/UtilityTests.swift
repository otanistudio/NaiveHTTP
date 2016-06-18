//
//  NormalizedURLTests.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/6/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import XCTest
import NaiveHTTP

class UtilityTests: XCTestCase {
    
    func testNormalizedURLInit() {
        let testQueryParams = ["a":"123","b":"456"]
        let url = URL(string: "http://example.com", params: testQueryParams)
        XCTAssertEqual(URL(string: "http://example.com?a=123&b=456"), url)
    }
    
    func testNormalizedURLWithExistingQueryParameters() {
        let testQueryParams = ["a":"123","b":"456"]
        let url = URL(string: "http://example.com?c=xxx&d=yyy", params: testQueryParams)
        XCTAssertEqual(URL(string: "http://example.com?a=123&b=456&c=xxx&d=yyy"), url)
    }
    
    func testNormalizedURLWithNilQueryParam() {
        let url = URL(string: "http://example.com", params: nil)
        let expectedURL = URL(string: "http://example.com")
        XCTAssertEqual(expectedURL, url)
    }
    
//    func testFilteredJSON() {        
//        let str: String = "while(1);\n[\"bleh\", \"blah\"]"
//        let data: Data = str.data(using: String.Encoding.utf8)!
//        let json = SwiftyHTTP.filteredJSON("while(1);", data: data)
//        let expected: JSON = ["bleh", "blah"]
//        XCTAssertEqual(expected, json)
//    }
}
