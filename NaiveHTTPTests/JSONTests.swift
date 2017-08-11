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

fileprivate struct GETResponse {
    let herp: String
}

extension GETResponse: Decodable {
    enum StructKeys: String, CodingKey {
        case args = "args"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StructKeys.self)
        let dict = try container.decode(Dictionary<String,String>.self, forKey: .args)
        let herp: String = dict["herp"]!
        self.init(herp: herp)
    }
}

fileprivate struct POSTResponse {
    let contents: String
}

extension POSTResponse: Decodable {
    enum StructKeys: String, CodingKey {
        case data = "data"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StructKeys.self)
        let responseString = try container.decode(String.self, forKey: .data)
        self.init(contents: responseString)
    }
}

fileprivate struct HeaderResponse {
    let headers: [String:String]
}

extension HeaderResponse: Decodable {
    enum StructKeys: String, CodingKey {
        case headers = "headers"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StructKeys.self)
        let dict = try container.decode([String:String].self, forKey: .headers)
        self.init(headers: dict)
    }
}

fileprivate struct JSONNullValueCheck {
    var json: String?
}

extension JSONNullValueCheck: Decodable {
    enum StructKeys: String, CodingKey {
        case json = "json"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StructKeys.self)
        let json = try container.decodeIfPresent(String.self, forKey: .json)
        self.init(json: json)
    }
}

class JSONTests: XCTestCase {
    let networkTimeout = 1.0
    var networkExpectation: XCTestExpectation?
    let decoder = JSONDecoder()

    struct SamplePostData: Encodable {
        let herp: String
    }

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
                let result = try! self.decoder.decode(GETResponse.self, from: data!)
                XCTAssertEqual("derp", result.herp)
                let httpResp = response as! HTTPURLResponse
                XCTAssertEqual(uri + "?herp=derp", httpResp.url!.absoluteString)
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

        let postObject = SamplePostData(herp: "derp")
        let encoder = JSONEncoder()
        let postData = try! encoder.encode(postObject)

        let _ = naive.POST(URI.loc("post"), postData: postData, responseFilter: nil, headers: nil) { (data, response, error) -> () in
            XCTAssertNil(error)
            let responseObject = try! self.decoder.decode(POSTResponse.self, from: data!)
            XCTAssertEqual("{\"herp\":\"derp\"}", responseObject.contents)
            let httpResp = response as! HTTPURLResponse
            XCTAssertEqual(URI.loc("post"), httpResp.url!.absoluteString)
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

    func testJSONPOSTWithAdditionalHeaders() {
        let naive = NaiveHTTP()
        let postObject = SamplePostData(herp: "derp")
        let encoder = JSONEncoder()
        let postData = try! encoder.encode(postObject)

        let additionalHeaders = ["X-Some-Custom-Header":"hey-hi-ho"]

        let _ = naive.POST(URI.loc("post"), postData: postData, responseFilter: nil, headers: additionalHeaders) { (data, response, error) -> () in
            XCTAssertNil(error)
            let headerCheck = try! self.decoder.decode(HeaderResponse.self, from: data!)
            XCTAssertEqual("hey-hi-ho", headerCheck.headers["X-Some-Custom-Header"])
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

    func testJSONPOSTWithNilPostBody() {
        let naive = NaiveHTTP()

        let _ = naive.POST(URI.loc("post"), postData: nil, responseFilter: nil, headers: nil) { (data, response, error) -> () in
            XCTAssertNil(error)
            let jsonResponse = try! self.decoder.decode(JSONNullValueCheck.self, from: data!)
            XCTAssertNil(jsonResponse.json)
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

    func testJSONPOSTError() {
        let naive = NaiveHTTP()
        let postObject = SamplePostData(herp: "derp")
        let encoder = JSONEncoder()
        let postData = try! encoder.encode(postObject)

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
        let sampleData = SamplePostData(herp: "derp")
        let encoder = JSONEncoder()
        let putData = try! encoder.encode(sampleData)

        let _ = naive.PUT(URI.loc("put"), putData: putData, responseFilter: nil, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let responseObject = try! self.decoder.decode(POSTResponse.self, from: data!)
            XCTAssertEqual("{\"herp\":\"derp\"}", responseObject.contents)
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

    func testJSONDELETE() {
        let naive = NaiveHTTP()
        let sampleData = SamplePostData(herp: "derp")
        let encoder = JSONEncoder()
        let dataForDeleteReq = try! encoder.encode(sampleData)

        let _ = naive.DELETE(URI.loc("delete"), body: dataForDeleteReq, responseFilter: nil, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let responseObject = try! self.decoder.decode(POSTResponse.self, from: data!)
            XCTAssertEqual("{\"herp\":\"derp\"}", responseObject.contents)
            self.networkExpectation!.fulfill()
        }

        self.waitForExpectations(timeout: networkTimeout, handler: nil)
    }

}
