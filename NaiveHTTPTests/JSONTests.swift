//
//  JSONTests.swift
//  NaiveHTTPTests
//
//  Created by Robert Otani on 6/8/17.
//  Copyright © 2017 otanistudio.com. All rights reserved.
//

import XCTest
import Foundation
import NaiveHTTP

fileprivate struct HTTPBinResponse: Decodable {
    let args: [String:String]
    var data: String?
    var files: [String:String]?
    var form: [String:String]?
    let headers: [String:String]
    var json: [String:String]?
    let origin: String
    let url: String
}

class JSONTests: XCTestCase {
    let networkTimeout = 1.0
    var networkExpectation: XCTestExpectation?
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    override func setUp() {
        super.setUp()
        networkExpectation = self.expectation(description: "naive (JSONTests) network expectation")
    }

    /*
    curl http://localhost:5000/get?herp=derp
    {
      "args": {
        "herp": "derp"
      },
      "headers": {
        "Accept": "*",
        "Content-Length": "",
        "Content-Type": "",
        "Host": "localhost:5000",
        "User-Agent": "curl/7.54.0"
      },
      "origin": "127.0.0.1",
      "url": "http://localhost:5000/get?herp=derp"
    }
    */
    func testJSONGETWithParams() {
        let naive = NaiveHTTP()

        let params = ["herp":"derp"]
        let uri = URI.loc("get")

        let _ = naive.GET(
            uri,
            params: params,
            responseFilter: nil,
            headers: nil) { (data, response, error) -> Void in
                XCTAssertNil(error)
                let httpResp = response as! HTTPURLResponse
                XCTAssertEqual(uri + "?herp=derp", httpResp.url!.absoluteString)
                let httpbinResponse = try! self.decoder.decode(HTTPBinResponse.self, from: data!)
                XCTAssertEqual(["herp":"derp"], httpbinResponse.args)
                self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

    func testGETWithPreFilter() {
        let naive = NaiveHTTP()
        let prefixFilter = "while(1);</x>"
        let url = Bundle(for: JSONTests.self).url(forResource: "hijack_guarded", withExtension: "json")
        let uri = url?.absoluteString

        let expectedString = "{\"feh\":\"bleh\"}\n"

        let _ = naive.GET(uri!, params: nil, responseFilter: prefixFilter, headers: nil) { (data, response, error) -> () in
            XCTAssertNil(error)
            let json = String(data: data!, encoding: .utf8)
            XCTAssertEqual(expectedString, json)
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

    func testJSONPOST() {
        let naive = NaiveHTTP()

        let postData = try! encoder.encode(["herp":"derp"])

        let _ = naive.POST(URI.loc("post"), postData: postData, responseFilter: nil, headers: nil) { (data, response, error) -> () in
            XCTAssertNil(error)
            let httpbinResponse = try! self.decoder.decode(HTTPBinResponse.self, from: data!)
            XCTAssertEqual("{\"herp\":\"derp\"}", httpbinResponse.data)
            XCTAssertEqual("http://localhost:5000/post", httpbinResponse.url)
            let httpResp = response as! HTTPURLResponse
            XCTAssertEqual(URI.loc("post"), httpResp.url!.absoluteString)
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

    func testJSONPOSTWithAdditionalHeaders() {
        let naive = NaiveHTTP()
        let postData = try! encoder.encode(["herp":"derp"])

        let additionalHeaders = ["X-Some-Custom-Header":"hey-hi-ho"]

        let _ = naive.POST(URI.loc("post"), postData: postData, responseFilter: nil, headers: additionalHeaders) { (data, response, error) -> () in
            XCTAssertNil(error)
            let httpbinResponse = try! self.decoder.decode(HTTPBinResponse.self, from: data!)
            XCTAssertEqual("hey-hi-ho", httpbinResponse.headers["X-Some-Custom-Header"])
            XCTAssertEqual("http://localhost:5000/post", httpbinResponse.url)
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

    func testJSONPOSTWithNilPostBody() {
        let naive = NaiveHTTP()

        let _ = naive.POST(URI.loc("post"), postData: nil, responseFilter: nil, headers: nil) { (data, response, error) -> () in
            XCTAssertNil(error)
            let httpbinResponse = try! self.decoder.decode(HTTPBinResponse.self, from: data!)
            XCTAssertEqual("http://localhost:5000/post", httpbinResponse.url)
            XCTAssertNil(httpbinResponse.json)
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

    func testJSONPOSTError() {
        let naive = NaiveHTTP()
        let postData = try! encoder.encode(["herp":"derp"])

        let _ = naive.POST(URI.loc("status/500"), postData: postData, responseFilter: nil, headers: nil) { (data, response, error) -> () in
            XCTAssertEqual(0, data?.count)
            XCTAssertEqual(500, error!.code)
            XCTAssertEqual("HTTP Error 500", error!.userInfo[NSLocalizedDescriptionKey] as? String)
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

    func testJSONPOSTWithPreFilter() {
        let naive = NaiveHTTP()
        let prefixFilter = "while(1);</x>"
        let url = Bundle(for: JSONTests.self).url(forResource: "hijack_guarded", withExtension: "json")
        let uri = url?.absoluteString

        let _ = naive.POST(uri!, postData: nil, responseFilter: prefixFilter, headers: nil) { (data, response, error) -> () in
            XCTAssertNil(error)
            XCTAssertEqual("{\"feh\":\"bleh\"}\n", String(data: data!, encoding: .utf8))
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

    func testJSONPUT() {
        let naive = NaiveHTTP()
        let putData = try! encoder.encode(["put":"something here"])

        let _ = naive.PUT(URI.loc("put"), putData: putData, responseFilter: nil, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let httpbinResponse = try! self.decoder.decode(HTTPBinResponse.self, from: data!)
            XCTAssertEqual("{\"put\":\"something here\"}", httpbinResponse.data)
            XCTAssertEqual("http://localhost:5000/put", httpbinResponse.url)
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

    func testJSONDELETE() {
        let naive = NaiveHTTP()
        let dataForDeleteReq = try! encoder.encode(["thing":"should be deleted"])

        let _ = naive.DELETE(URI.loc("delete"), body: dataForDeleteReq, responseFilter: nil, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let httpbinResponse = try! self.decoder.decode(HTTPBinResponse.self, from: data!)
            XCTAssertEqual("{\"thing\":\"should be deleted\"}", httpbinResponse.data)
            XCTAssertEqual("http://localhost:5000/delete", httpbinResponse.url)
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

}
