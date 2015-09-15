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
        additionalHeaders: [String: String]?,
        completion: completionHandler?) {
            
        let url: NSURL =  self.dynamicType.normalizedURL(uri, params: params)
        let request = NSMutableURLRequest(URL: url)
            
        if let headers = additionalHeaders {
            for (k, v) in headers {
                request.setValue(v, forHTTPHeaderField: k)
            }
        }

        performRequest(request, completion: completion)
    }
    
    public func POST(
        uri: String,
        postObject: AnyObject?,
        additionalHeaders: [String : String]?,
        completion: completionHandler?) {
        
            let url = NSURL(string: uri)!
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"

            if let headers = additionalHeaders {
                for (k, v) in headers {
                    request.setValue(v, forHTTPHeaderField: k)
                }
            }
            
            if postObject != nil {
                do {
                    request.HTTPBody = try JSON(postObject!).rawData()
                } catch let jsonError as NSError {
                    let postObjectError = NSError(domain: errorDomain, code: -1,
                        userInfo: [
                            NSLocalizedFailureReasonErrorKey: "failed to convert postObject to JSON",
                            NSLocalizedDescriptionKey: "SwiftyJSON Error: \(jsonError.description)"
                        ])
                    
                    completion?(data: nil, response: nil, error: postObjectError)
                    return
                }
            }

            performRequest(request, completion: completion)

    }

    public func performRequest(
        req: NSURLRequest,
        completion: completionHandler?) {
            
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

