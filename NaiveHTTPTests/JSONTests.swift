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

fileprivate struct TestObject {
    let herp: String
}

extension TestObject: Decodable {
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

class JSONTests: XCTestCase {
    let networkTimeout = 1.0
    var networkExpectation: XCTestExpectation?
    let decoder = JSONDecoder()

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
                let result = try! self.decoder.decode(TestObject.self, from: data!)
                XCTAssertEqual("derp", result.herp)
                let httpResp = response as! HTTPURLResponse
                debugPrint(httpResp)
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

}
