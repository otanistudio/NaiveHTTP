//
//  Utility.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation

public class Utility {
    /// A convenience function for services that returns a string response prepended with
    /// with an anti-hijacking string.
    ///
    /// Some services return a string, like `while(1);` pre-pended to their JSON string, which can
    /// break the normal decoding dance.
    /// 
    /// - parameter prefixFilter: The string to remove from the beginning of the response
    /// - parameter data: The data, usually the response data from of your `NSURLSession` or `NSURLConnection` request
    /// - returns: a valid `SwiftyJSON` object
    public static func filteredJSON(prefixFilter: String, data: NSData?) -> JSON {
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
}

internal extension NSURL {
    /// Returns an NSURL with alphabetized query paramters. 
    ///
    /// This covers the use case where `http://example.com?a=1&b=2` is always returned
    /// even if the string given was `http://example.com?b=2&a=1`
    ///
    /// - parameter string: The string to use to create the URL, e.g.: http://example.com or file://something
    ///
    /// - parameter params: a `Dictionary<String, String>` that contains the name/value pairs for the parameters
    ///
    /// - returns: An NSURL that guarantees query parameters sorted in ascending alphabetic order.
    convenience init(string: String, params: [String : String]?) {
        // Deal with any query params already in the URI String
        let urlComponents = NSURLComponents(string: string)
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
        
        self.init(string: (urlComponents?.string)!)!
    }
}
