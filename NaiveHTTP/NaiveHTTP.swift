//
//  NaiveHTTP.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/20/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import UIKit

public protocol NaiveHTTPProtocol {
    var urlSession: NSURLSession { get }
    var configuration: NSURLSessionConfiguration { get }
    
    func GET(
        uri:String,
        params:[String: String]?,
        additionalHeaders: [String: String]?,
        success:((data: NSData, response: NSURLResponse)->())?,
        failure:((error: NSError)->Void)?
    )
    
    func POST(
        uri:String,
        postObject: AnyObject?,
        additionalHeaders: [String: String]?,
        success: ((responseData: NSData, response: NSURLResponse)->())?,
        failure:((postError: NSError)->())?
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
            self._configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            _urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        }
    }
    
    deinit {
        _urlSession.invalidateAndCancel()
    }
}