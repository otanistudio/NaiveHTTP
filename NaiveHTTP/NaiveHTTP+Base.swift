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
        uri: String,
        params: [String: String]?,
        headers: [String: String]?,
        completion: ((data: NSData?, response: NSURLResponse?, error: NSError?) -> Void)?) -> NSURLSessionDataTask? {
            
        let url: NSURL =  NSURL(string: uri, params: params)
        return performRequest(.GET, uri: url.absoluteString, body: nil, headers: headers, completion: completion)
    }
    
    public func POST(
        uri: String,
        body: NSData?,
        headers: [String : String]?,
        completion: ((data: NSData?, response: NSURLResponse?, error: NSError?) -> Void)?) -> NSURLSessionDataTask? {
            
        return performRequest(.POST, uri: uri, body: body, headers: headers, completion: completion)
    }
    
    public func PUT(
        uri: String,
        body: NSData?,
        headers: [String : String]?,
        completion: ((data: NSData?, response: NSURLResponse?, error: NSError?) -> Void)?) -> NSURLSessionDataTask? {
            
        return performRequest(.PUT, uri: uri, body: body, headers: headers, completion: completion)
    }

    public func DELETE(
        uri: String,
        body: NSData?,
        headers: [String : String]?,
        completion: ((data: NSData?, response: NSURLResponse?, error: NSError?) -> Void)?) -> NSURLSessionDataTask? {

        return performRequest(.DELETE, uri: uri, body: body, headers: headers, completion: completion)
    }
}

