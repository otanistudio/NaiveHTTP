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
        completion: completionHandler?) -> Self {
            
        let url: NSURL =  NSURL(string: uri, params: params)
        return performRequest(.GET, uri: url.absoluteString, body: nil, headers: headers, completion: completion)
    }
    
    public func POST(
        uri: String,
        postObject: AnyObject?,
        headers: [String : String]?,
        completion: completionHandler?) -> Self {
            
        return performRequest(.POST, uri: uri, body: postObject, headers: headers, completion: completion)
    }
    
    public func PUT(
        uri: String,
        body: AnyObject?,
        headers: [String : String]?,
        completion: completionHandler?) -> Self {
            
        return performRequest(.PUT, uri: uri, body: body, headers: headers, completion: completion)
    }
    
}

