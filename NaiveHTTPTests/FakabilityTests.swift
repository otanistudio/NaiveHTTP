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
        let errorDomain = "com.otanistudio.FakeNaive.error"
        
        var urlSession: URLSession {
            return URLSession(configuration: configuration)
        }
        
        var configuration: URLSessionConfiguration {
            return URLSessionConfiguration.ephemeral()
        }
        
        let commonJSONString = "{\"somekey\":\"somevalue\"}"
        
        private func fakeAsync(
            _ success:((data: Data, response: URLResponse)->())?,
            failure:((error: NSError)->())?) -> URLSessionDataTask? {
                
            let s = NSString(string: commonJSONString)
            let data = s.data(using: String.Encoding.utf8.rawValue)
            let resp = URLResponse()
            success!(data: data!, response: resp)
            
            return nil
        }
        
        func performRequest(_ method: Method, uri: String, body: Data?, headers: [String : String]?, completion: ((data: Data?, response: URLResponse?, error: NSError?) -> Void)?)  -> URLSessionDataTask? {
            
            return fakeAsync({ (data, response) -> () in
                completion!(data: data, response: response, error: nil)
            }) { (error) -> () in
                completion!(data: nil, response: nil, error: error)
            }
        }
    }
    
    override func setUp() {
        super.setUp()
    }
    
    func testBasicFake() {
        let fakeNaive = FakeNaive()
        let asyncExpectation = self.expectation(withDescription: "async expectation")
        
        fakeNaive.GET("http://example.com", params: nil, headers: nil) { [asyncExpectation](data, response, error) -> () in
            XCTAssertNil(error)
            let resultString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            XCTAssertEqual(fakeNaive.commonJSONString, resultString)
            asyncExpectation.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1.0, handler: nil)
        
    }
    
    func testJSONGET() {
        // This is nice because we only needed to write one struct, and we inherit
        // expected behavior from the other protocol extensions
        let fakeNaive = FakeNaive()
        let asyncExpectation = self.expectation(withDescription: "async expectation")
        
        fakeNaive.GET("http://example.com/whatever", params: nil, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let json = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
            XCTAssertEqual("somevalue", json["somekey"]!)
            asyncExpectation.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 1.0, handler: nil)
    }
    
}
