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
        uri:String,
        params: [String: String]?,
        headers: [String: String]?,
        completion: completionHandler?) {
            
        let url: NSURL =  Utility.normalizedURL(uri, params: params)
        performRequest(.GET, uri:url.absoluteString, body: nil, headers: headers, completion: completion)
    }
    
    public func POST(
        uri: String,
        postObject: AnyObject?,
        headers: [String : String]?,
        completion: completionHandler?) {
            
        performRequest(.POST, uri: uri, body: postObject, headers: headers, completion: completion)
    }
    
    public func PUT(
        uri: String,
        body: AnyObject?,
        headers: [String : String]?,
        completion: completionHandler?) {
            
        performRequest(.PUT, uri: uri, body: body, headers: headers, completion: completion)
    }
    
}

