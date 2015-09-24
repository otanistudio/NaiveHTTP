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
            
        let url: NSURL =  self.dynamicType.normalizedURL(uri, params: params)
        performRequest(.GET, uri:url.absoluteString, body: nil, headers: headers, completion: completion)
    }
    
    public func POST(
        uri: String,
        postObject: AnyObject?,
        headers: [String : String]?,
        completion: completionHandler?) {
            
        performRequest(.POST, uri: uri, body: postObject, headers: headers, completion: completion)
    }
    
    public func performRequest(
        method: Method,
        uri: String,
        body: AnyObject?,
        headers: [String : String]?,
        completion: completionHandler?) {
            
            let url = NSURL(string: uri)
            let req = NSMutableURLRequest(URL: url!)
            req.HTTPMethod = "\(method)"
            
            if headers != nil {
                for (k, v) in headers! {
                    req.setValue(v, forHTTPHeaderField: k)
                }
            }
            
            if method == .POST || method == .PUT {
                if body != nil {
                    do {
                        let o = JSON(body!)
                        if o.type == .String {
                            req.HTTPBody = (o.stringValue as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                        } else {
                            req.HTTPBody = try o.rawData()
                        }
                    } catch let jsonError as NSError {
                        let bodyError = NSError(domain: errorDomain, code: -1,
                            userInfo: [
                                NSLocalizedFailureReasonErrorKey: "failed to convert body to appropriate format",
                                NSLocalizedDescriptionKey: "SwiftyJSON Error: \(jsonError.description)"
                            ])
                        
                        completion?(data: nil, response: nil, error: bodyError)
                        return
                    }
                }
            }
            
            
            urlSession.dataTaskWithRequest(req) { (data, response, error) -> Void in
                guard error == nil else {
                    completion?(data: data, response: response, error: error)
                    return
                }
                
                if let httpResponse: NSHTTPURLResponse = response as? NSHTTPURLResponse {
                    if (httpResponse.statusCode >= 400) {
                        let responseError = NSError(domain: errorDomain, code: httpResponse.statusCode, userInfo: [NSLocalizedFailureReasonErrorKey: "HTTP 400 or above error", NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
                        completion?(data: data, response: response, error: responseError)
                        return
                    }
                }
                
                completion?(data: data, response: response, error: error)
                
                }.resume()
            
    }
}

