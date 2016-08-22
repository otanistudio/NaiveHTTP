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
            return URLSessionConfiguration.ephemeral
        }
        
        let commonJSONString = "{\"somekey\":\"somevalue\"}"
        
        private func fakeAsync(
            _ success:((_ data: Data, _ response: URLResponse)->())?,
            failure:((_ error: NSError)->())?) -> URLSessionDataTask? {
                
            let s = NSString(string: commonJSONString)
            let data = s.data(using: String.Encoding.utf8.rawValue)
            let resp = URLResponse()
            success!(data!, resp)
            
            return nil
        }
        
        func performRequest(_ method: Method, uri: String, body: Data?, headers: [String : String]?, completion: ((_ data: Data?, _ response: URLResponse?, _ error: NSError?) -> Void)?)  -> URLSessionDataTask? {
            
            return fakeAsync({ (data, response) -> () in
                completion!(data, response, nil)
            }) { (error) -> () in
                completion!(nil, nil, error)
            }
        }
    }
    
    override func setUp() {
        super.setUp()
    }

    func testBasicFake() {
        let fakeNaive = FakeNaive()
        let asyncExpectation = self.expectation(description: "async expectation")
        
        let _ = fakeNaive.GET("http://example.com", params: nil, headers: nil) { [asyncExpectation](data, response, error) in
            XCTAssertNil(error)
            let resultString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            XCTAssertEqual(fakeNaive.commonJSONString, resultString as! String)
            asyncExpectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
    }
    
    func testJSONGET() {
        // This is nice because we only needed to write one struct, and we inherit
        // expected behavior from the other protocol extensions
        let fakeNaive = FakeNaive()
        let asyncExpectation = self.expectation(description: "async expectation")

        let _ = fakeNaive.GET("http://example.com/whatever", params: nil, headers: nil) { (data, response, error) in
            XCTAssertNil(error)
            let json = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String:AnyObject]

            XCTAssertEqual("somevalue", json["somekey"] as! String)
            asyncExpectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
}
