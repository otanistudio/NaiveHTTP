//
//  Utility.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation

internal extension URL {
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
    init(string: String, params: [String : String]?) {
        // Deal with any query params already in the URI String
        var urlComponents = URLComponents(string: string)
        var queryItems: [URLQueryItem]? = urlComponents?.queryItems
        
        if queryItems == nil {
            queryItems = []
        }
        
        // Now, incorporate items in queryParams to generate the fully-formed NSURL
        if let p = params {
            for (key, val) in p {
                let qItem = URLQueryItem(name: key, value: val)
                queryItems?.append(qItem)
            }
        }
        
        if queryItems!.count > 0 {
            queryItems?.sort(by: { (qItem1: URLQueryItem, qItem2: URLQueryItem) -> Bool in
                return qItem1.name < qItem2.name
            })
            urlComponents?.queryItems = queryItems
        }
        
        self.init(string: (urlComponents?.string)!)!
    }
}
