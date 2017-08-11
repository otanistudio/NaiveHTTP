//
//  NaiveHTTP+JSON.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/8/17.
//  Copyright © 2017 otanistudio.com. All rights reserved.
//

import Foundation

extension NaiveHTTPProtocol {

    public func GET(
        _ uri:String,
        params:[String : String]?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: ((Data?, URLResponse?, NSError?) -> Void)?) -> URLSessionDataTask? {

        let url: URL =  URL(string: uri, params: params)
        let headers = jsonHeaders(headers)

        return performRequest(.GET, uri: url.absoluteString, body: nil, headers: headers, completion: { (unfilteredData, response, requestError) in

            guard requestError == nil else {
                completion?(unfilteredData, response, requestError)
                return
            }

            guard unfilteredData != nil else {
                completion?(nil, response, requestError)
                return
            }

            guard let unfilteredJSONStr = String(data: unfilteredData!, encoding: .utf8) else {
                completion?(unfilteredData, response, requestError)
                return
            }

            guard !unfilteredJSONStr.isEmpty else {
                completion?(unfilteredData, response, requestError)
                return
            }

            var filteredStr: String?
            if let filter = responseFilter {
                if let range = unfilteredJSONStr.range(of: filter) {
                    filteredStr = String(unfilteredJSONStr.suffix(from: range.upperBound))
                } else {
                    filteredStr = unfilteredJSONStr
                }

                let filteredData = filteredStr?.data(using: .utf8)
                completion?(filteredData, response, requestError)
                return
            }

            completion?(unfilteredData, response, requestError)
        })
    }

    private func jsonHeaders(_ additionalHeaders: [String : String]?) -> [String : String] {
        let jsonHeaders: [String : String] = [
            "Accept" : "application/json",
            "Content-Type" : "application/json"
        ]

        let headers: [String : String]?
        if let additional = additionalHeaders {
            headers = additional.reduce(jsonHeaders) { dict, pair in
                var fixed = dict
                fixed[pair.0] = pair.1
                return fixed
            }
        } else {
            headers = jsonHeaders
        }

        return headers!
    }

}
