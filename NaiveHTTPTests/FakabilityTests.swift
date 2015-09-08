//
//  FakabilityTests.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import XCTest

class FakeTests: XCTestCase {
    
    struct FakeNaive: NaiveHTTPProtocol {
        var urlSession: NSURLSession {
            return NSURLSession(configuration: configuration)
        }
        
        var configuration: NSURLSessionConfiguration {
            return NSURLSessionConfiguration.ephemeralSessionConfiguration()
        }
        
        let commonJSONString = "{\"somekey\":\"somevalue\"}"
        
        private func fakeAsync(
            success:((data: NSData, response: NSURLResponse)->())?,
            failure:((error: NSError)->())?) {
                
            let s = NSString(string: commonJSONString)
            let data = s.dataUsingEncoding(NSUTF8StringEncoding)
            let resp = NSURLResponse()
            success!(data: data!, response: resp)
        }
        
        func GET(
            uri: String,
            params: [String : String]?,
            success: ((data: NSData, response: NSURLResponse) -> ())?,
            failure: ((error: NSError) -> Void)?) {
                
            fakeAsync(success, failure: failure)
        }
        
        func POST(
            uri: String,
            postObject: AnyObject?,
            additionalHeaders: [String : String]?,
            success: ((responseData: NSData, response: NSURLResponse) -> ())?,
            failure: ((postError: NSError) -> ())?) {
                
            fakeAsync(success, failure: failure)
        }
    }
    
    override func setUp() {
        super.setUp()
    }
    
    func testBasicFake() {
        let fakeNaive = FakeNaive()
        let asyncExpectation = self.expectationWithDescription("async expectation")
        
        fakeNaive.GET("http://example.com", params: nil, success: { [asyncExpectation](data, response) -> () in
            let resultString = NSString(data: data, encoding: NSUTF8StringEncoding)
            XCTAssertEqual(fakeNaive.commonJSONString, resultString)
            asyncExpectation.fulfill()
        }) { (error) -> Void in
            XCTFail()
            asyncExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        
    }
    
    func testJSONGET() {
        // This is nice because we only needed to write one struct, and we inherit
        // expected behavior from the other protocol extensions
        let fakeNaive = FakeNaive()
        let asyncExpectation = self.expectationWithDescription("async expectation")
        fakeNaive.GET("http://example.com/whatever", params: nil, successJSON: { (json, response) -> () in
            XCTAssertEqual("somevalue", json["somekey"].stringValue)
            asyncExpectation.fulfill()
        }) { (error) -> Void in
            XCTFail()
            asyncExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
}