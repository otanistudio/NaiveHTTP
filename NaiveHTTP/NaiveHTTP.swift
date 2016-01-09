//
//  NaiveHTTP.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/20/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import UIKit

internal let errorDomain = "com.otanistudio.NaiveHTTP.error"
public typealias completionHandler = (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void

public enum Method: String {
    case GET        = "GET"
    case HEAD       = "HEAD"
    case OPTIONS    = "OPTIONS"
    case POST       = "POST"
    case PUT        = "PUT"
    case DELETE     = "DELETE"
}

public protocol NaiveHTTPProtocol {
    var urlSession: NSURLSession { get }
    var configuration: NSURLSessionConfiguration { get }
    
    func performRequest(
        method: Method,
        uri: String,
        body: NSData?,
        headers: [String : String]?,
        completion: completionHandler?
    ) -> NSURLSessionDataTask?
}

public final class NaiveHTTP: NaiveHTTPProtocol {
    let _urlSession: NSURLSession!
    let _configuration: NSURLSessionConfiguration!
    
    public var urlSession: NSURLSession {
        return _urlSession
    }
    
    public var configuration: NSURLSessionConfiguration {
        return _configuration
    }
    
    required public init(_ configuration: NSURLSessionConfiguration? = nil) {
        if let config = configuration {
            self._configuration = config
            _urlSession = NSURLSession(configuration: config)
        } else {
            self._configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
            _urlSession = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
        }
    }
    
    deinit {
        _urlSession.invalidateAndCancel()
    }
    
    public func performRequest(
        method: Method,
        uri: String,
        body: NSData?,
        headers: [String : String]?,
        completion: completionHandler?) -> NSURLSessionDataTask? {
            
        let url = NSURL(string: uri)
        if url == nil {
            let urlError = NSError(domain: errorDomain, code: -13, userInfo: [
                NSLocalizedFailureReasonErrorKey : "could not create NSURL from string"
                ])
            completion?(data: nil, response: nil, error: urlError)
            return nil
        }
        let req = NSMutableURLRequest(URL: url!)
        req.HTTPMethod = "\(method)"
        
        if headers != nil {
            for (k, v) in headers! {
                req.setValue(v, forHTTPHeaderField: k)
            }
        }
        
        if method == .POST || method == .PUT || method == .DELETE {
            req.HTTPBody = body
        }
        
        let task = urlSession.dataTaskWithRequest(req) { (data, response, error) -> Void in
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
            
        }
        
        task.resume()
        return task
    }
}