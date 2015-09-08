//
//  NaiveHTTP.Utility.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation

public extension NaiveHTTPProtocol {
    internal func preFilterResponseData(prefixFilter: String, data: NSData?) -> JSON {
        let json: JSON?
        
        if let unfilteredJSONStr = NSString(data: data!, encoding: NSUTF8StringEncoding) {
            if unfilteredJSONStr.hasPrefix(prefixFilter) {
                let range = unfilteredJSONStr.rangeOfString(prefixFilter, options: .LiteralSearch)
                let filteredStr = unfilteredJSONStr.substringFromIndex(range.length)
                let filteredData = filteredStr.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                json = JSON(data: filteredData!)
            } else {
                let filteredData = unfilteredJSONStr.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                json = JSON(data: filteredData!)
            }
        } else {
            json = JSON(NSNull())
        }
        
        return json!
    }
    
    public static func normalizedURL(uri:String, params:[String: String]?) -> NSURL {
        // Deal with any query params already in the URI String
        let urlComponents = NSURLComponents(string: uri)
        var queryItems: [NSURLQueryItem]? = urlComponents?.queryItems
        
        if queryItems == nil {
            queryItems = []
        }
        
        // Now, incorporate items in queryParams to generate the fully-formed NSURL
        if let p = params {
            for (key, val) in p {
                let qItem = NSURLQueryItem(name: key, value: val)
                queryItems?.append(qItem)
            }
        }
        
        if queryItems!.count > 0 {
            queryItems?.sortInPlace({ (qItem1: NSURLQueryItem, qItem2: NSURLQueryItem) -> Bool in
                return qItem1.name < qItem2.name
            })
            urlComponents?.queryItems = queryItems
        }
        
        return NSURL(string: (urlComponents?.string)!)!
    }
}
