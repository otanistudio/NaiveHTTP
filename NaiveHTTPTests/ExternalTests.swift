//
//  ExternalTests.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/24/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import XCTest
import NaiveHTTP

let localServerURI = (NSProcessInfo.processInfo().environment["NAIVEHTTP_EXTERNAL_TEST_SERVER"] != nil) ? NSProcessInfo.processInfo().environment["NAIVEHTTP_EXTERNAL_TEST_SERVER"]! : "https://httpbin.org"

class ExternalTests: XCTestCase {

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
    
    func testDataTask() {
        let naive = NaiveHTTP()
        let task = naive.performRequest(.GET, uri: URI.loc("get") + "?task=data", body: nil, headers: nil) { (data, response, error) -> Void in
            self.networkExpectation!.fulfill()
        }
        XCTAssertEqual(URI.loc("get") + "?task=data", task?.originalRequest!.URL?.absoluteString)
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testGETWithError() {
        let naive = NaiveHTTP()
        naive.GET(URI.loc("status/400"), params: nil, headers: nil) { (data, response, error) -> Void in
            XCTAssertEqual(400, error?.code)
            self.networkExpectation!.fulfill()
        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testBadImageGET() {
        let naive = NaiveHTTP()

        naive.imageGET(URI.loc("image/webp")) { (image, response, error) -> () in
            XCTAssertEqual("nil UIImage", error?.userInfo[NSLocalizedFailureReasonErrorKey] as? String)
            XCTAssertNil(image)
            XCTAssertNotNil(response)
            self.networkExpectation!.fulfill()

        }
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPNGImageGET() {
        let naive = NaiveHTTP()
        
        naive.imageGET(URI.loc("image/png")) { (image, response, error) -> () in
            XCTAssertNotNil(image)
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testImage404() {
        let naive = NaiveHTTP()
        
        naive.imageGET(URI.loc("status/404")) { (image, response, error) -> () in
            XCTAssertEqual(404, error!.code)
            XCTAssertNil(image)
            XCTAssertNotNil(response)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    func testPOSTFormEncoded() {
        let naive = NaiveHTTP()
        let postString = "blah=blee&hey=this+is+a+string+folks"
        let formEncodedHeader = [
            "Content-Type" : "application/x-www-form-urlencoded"
        ]
        
        naive.POST(URI.loc("post"), body: postString.dataUsingEncoding(NSUTF8StringEncoding), headers: formEncodedHeader) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let parsedResult = try! NSJSONSerialization.JSONObjectWithData(data!, options: [])
            let receivedFormInfo = parsedResult["form"]!!
            XCTAssertEqual("blee", receivedFormInfo["blah"])
            XCTAssertEqual("this is a string folks", receivedFormInfo["hey"])
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    
    
    func testPUT() {
        let naive = NaiveHTTP()
        let putBody = ["put":"this"];
        let data = try! NSJSONSerialization.dataWithJSONObject(putBody, options: [])
        naive.PUT(URI.loc("put"), body: data, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let parsed = try! NSJSONSerialization.JSONObjectWithData(data!, options: [])
            XCTAssertEqual("this", parsed["json"]??["put"])
            self.networkExpectation!.fulfill()
        }
    
        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }
    

    func testDELETE() {
        let naive = NaiveHTTP()
        let deleteBody = ["delete":"this"];
        let data = try! NSJSONSerialization.dataWithJSONObject(deleteBody, options: [])
        naive.DELETE(URI.loc("delete"), body: data, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let parsedResult = try! NSJSONSerialization.JSONObjectWithData(data!, options: [])
            XCTAssertEqual("this", parsedResult["json"]??["delete"])
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectationsWithTimeout(networkTimeout, handler: nil)
    }

}
