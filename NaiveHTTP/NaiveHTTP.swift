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
    case GET    = "GET"
    case POST   = "POST"
    case PUT    = "PUT"
    case DELETE = "DELETE"
}

public protocol NaiveHTTPProtocol {
    var urlSession: NSURLSession { get }
    var configuration: NSURLSessionConfiguration { get }

    func GET(
        uri:String,
        params:[String : String]?,
        headers: [String : String]?,
        completion: completionHandler?
    )
    
    func POST(
        uri:String,
        postObject: AnyObject?,
        headers: [String : String]?,
        completion: completionHandler?
    )
    
    func performRequest(
        method: Method,
        uri: String,
        body: AnyObject?,
        headers: [String : String]?,
        completion: completionHandler?
    )
}

public class NaiveHTTP: NaiveHTTPProtocol {
    let _urlSession: NSURLSession!
    let _configuration: NSURLSessionConfiguration!
    
    public var urlSession: NSURLSession {
        return _urlSession
    }
    
    public var configuration: NSURLSessionConfiguration {
        return _configuration
    }
    
    required public init(configuration: NSURLSessionConfiguration?) {
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
}