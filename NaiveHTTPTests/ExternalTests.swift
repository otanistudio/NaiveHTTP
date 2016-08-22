//
//  ExternalTests.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/24/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import XCTest
import NaiveHTTP

let localServerURI = (ProcessInfo.processInfo.environment["NAIVEHTTP_EXTERNAL_TEST_SERVER"] != nil) ? ProcessInfo.processInfo.environment["NAIVEHTTP_EXTERNAL_TEST_SERVER"]! : "https://httpbin.org"

struct URI {
    static func loc(_ path: String) -> String {
        return "\(localServerURI)/\(path)"
    }
}

class ExternalTests: XCTestCase {
    let networkTimeout = 2.0
    var networkExpectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        networkExpectation = self.expectation(description: "naive network expectation")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDataTask() {
        let naive = NaiveHTTP()
        let task = naive.performRequest(.GET, uri: URI.loc("get") + "?task=data", body: nil, headers: nil) { (data, response, error) -> Void in
            self.networkExpectation!.fulfill()
        }
        XCTAssertEqual(URI.loc("get") + "?task=data", task?.originalRequest!.url?.absoluteString)
        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }
    
    func testGETWithError() {
        let naive = NaiveHTTP()
        let _ = naive.GET(URI.loc("status/400"), params: nil, headers: nil) { (data, response, error) -> Void in
            XCTAssertEqual(400, error?.code)
            self.networkExpectation!.fulfill()
        }
        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }
    
    func testGET() {
        let naive = NaiveHTTP()
        let _ = naive.GET(URI.loc("get"), params: ["something":"this is something"], headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let httpResponse: HTTPURLResponse = response as! HTTPURLResponse
            XCTAssertEqual(200, httpResponse.statusCode)
            let jsonResponse = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String : AnyObject]
            let args = jsonResponse["args"] as! [String : AnyObject]
            XCTAssertEqual("this is something", args["something"] as! String)
            self.networkExpectation!.fulfill()
        }
        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }
    
    func testOPTIONS() {
        let naive = NaiveHTTP()
        let _ = naive.performRequest(.OPTIONS, uri: URI.loc("get"), body: nil, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let httpResponse: HTTPURLResponse = response as! HTTPURLResponse
            XCTAssertEqual(200, httpResponse.statusCode)
            let headers = httpResponse.allHeaderFields
            let allowHeader: String = headers["Allow"] as! String
            XCTAssertEqual(allowHeader, "HEAD, OPTIONS, GET")
            self.networkExpectation!.fulfill()
        }
        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }
    
    func testHEAD() {
        let naive = NaiveHTTP()
        let _ = naive.performRequest(.HEAD, uri: URI.loc("get"), body: nil, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let httpResponse: HTTPURLResponse = response as! HTTPURLResponse
            XCTAssertEqual(0, data?.count)
            XCTAssertEqual(200, httpResponse.statusCode)
            self.networkExpectation!.fulfill()
        }
        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }
    
//    func testBadImageGET() {
//        let naive = NaiveHTTP()
//
//        let _ = naive.imageGET(URI.loc("image/webp")) { (image, response, error) -> () in
//            XCTAssertEqual("nil UIImage", error?.userInfo[NSLocalizedFailureReasonErrorKey] as? String)
//            XCTAssertNil(image)
//            XCTAssertNotNil(response)
//            self.networkExpectation!.fulfill()
//
//        }
//        self.waitForExpectations(withTimeout: networkTimeout, handler: nil)
//    }
    
    func testPNGImageGET() {
        let naive = NaiveHTTP()
        
        let _ = naive.imageGET(URI.loc("image/png")) { (image, response, error) -> () in
            XCTAssertNotNil(image)
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }
    
    func testImage404() {
        let naive = NaiveHTTP()
        
        let _ = naive.imageGET(URI.loc("status/404")) { (image, response, error) -> () in
            XCTAssertEqual(404, error!.code)
            XCTAssertNil(image)
            XCTAssertNotNil(response)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }
    
    func testPOSTFormEncoded() {
        let naive = NaiveHTTP()
        let postString = "blah=blee&hey=this+is+a+string+folks"
        let formEncodedHeader = [
            "Content-Type" : "application/x-www-form-urlencoded"
        ]
        
        let _ = naive.POST(URI.loc("post"), body: postString.data(using: String.Encoding.utf8), headers: formEncodedHeader) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let parsedResult = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String : AnyObject]
            let receivedFormInfo = parsedResult["form"] as! [String : AnyObject]
            XCTAssertEqual("blee", receivedFormInfo["blah"] as! String)
            XCTAssertEqual("this is a string folks", receivedFormInfo["hey"] as! String)
            self.networkExpectation!.fulfill()
        }
        
        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }
    
    
    func testPUT() {
        let naive = NaiveHTTP()
        let putBody = ["put":"this"];
        let data = try! JSONSerialization.data(withJSONObject: putBody, options: [])
        let _ = naive.PUT(URI.loc("put"), body: data, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let parsed = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String : AnyObject]
            let json = parsed["json"] as! [String : AnyObject]
            XCTAssertEqual("this", json["put"] as! String)
            self.networkExpectation!.fulfill()
        }
    
        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }
    

    func testDELETE() {
        let naive = NaiveHTTP()
        let deleteBody = ["delete":"this"];
        let data = try! JSONSerialization.data(withJSONObject: deleteBody, options: [])
        let _ = naive.DELETE(URI.loc("delete"), body: data, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let parsedResult = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String : AnyObject]
            let json = parsedResult["json"] as! [String : AnyObject]
            XCTAssertEqual("this", json["delete"] as! String)
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

}
