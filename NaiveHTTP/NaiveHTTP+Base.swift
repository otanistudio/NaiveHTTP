//
//  NaiveHTTP+Base.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation

public extension NaiveHTTPProtocol {
    
    public func GET(
        _ uri: String,
        params: [String: String]?,
        headers: [String: String]?,
        completion: ((_ data: Data?, _ response: URLResponse?, _ error: NSError?) -> Void)?) -> URLSessionDataTask? {
            
        let url: URL =  URL(string: uri, params: params)
        return performRequest(.GET, uri: url.absoluteString, body: nil, headers: headers, completion: completion)
    }
    
    public func POST(
        _ uri: String,
        body: Data?,
        headers: [String : String]?,
        completion: ((_ data: Data?, _ response: URLResponse?, _ error: NSError?) -> Void)?) -> URLSessionDataTask? {
            
        return performRequest(.POST, uri: uri, body: body, headers: headers, completion: completion)
    }
    
    public func PUT(
        _ uri: String,
        body: Data?,
        headers: [String : String]?,
        completion: ((_ data: Data?, _ response: URLResponse?, _ error: NSError?) -> Void)?) -> URLSessionDataTask? {
            
        return performRequest(.PUT, uri: uri, body: body, headers: headers, completion: completion)
    }

    public func DELETE(
        _ uri: String,
        body: Data?,
        headers: [String : String]?,
        completion: ((_ data: Data?, _ response: URLResponse?, _ error: NSError?) -> Void)?) -> URLSessionDataTask? {

        return performRequest(.DELETE, uri: uri, body: body, headers: headers, completion: completion)
    }
}

