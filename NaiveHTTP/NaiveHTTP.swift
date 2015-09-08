//
//  NaiveHTTP.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/20/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import UIKit

private let errorDomain = "com.otanistudio.NaiveHTTP.error"

public protocol NaiveHTTPProtocol {
    var urlSession: NSURLSession { get }
    var configuration: NSURLSessionConfiguration { get }
    
    func GET(
        uri:String,
        params:[String: String]?,
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
    
    public func GET(
        uri:String,
        params:[String: String]?,
        success:((data: NSData, response: NSURLResponse)->())?,
        failure:((error: NSError)->Void)?) {
        
        let url: NSURL =  self.dynamicType.normalizedURL(uri, params: params)
        
        urlSession.dataTaskWithURL(url) { (responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if (error != nil) {
                failure!(error: error!)
                return
            }
            
            if let httpResponse: NSHTTPURLResponse = response as? NSHTTPURLResponse {
                if (httpResponse.statusCode > 400) {
                    let responseError = NSError(domain: errorDomain, code: httpResponse.statusCode, userInfo: [NSLocalizedFailureReasonErrorKey: "HTTP 400 or above error", NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
                    failure!(error: responseError)
                    return
                }
            }
            
            success!(data: responseData!, response: response!)
            
            }.resume()
    }
    
    public func POST(
        uri:String,
        postObject: AnyObject?,
        additionalHeaders: [String: String]?,
        success: ((responseData: NSData, response: NSURLResponse)->())?,
        failure:((postError: NSError)->())?) {
            
            let url = NSURL(string: uri)!
            let request = NSMutableURLRequest(URL: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.HTTPMethod = "POST"
            
            if let headers = additionalHeaders {
                for (k, v) in headers {
                    request.setValue(v, forHTTPHeaderField: k)
                }
            }
            
            if postObject != nil {
                do {
                    try request.HTTPBody = JSON(postObject!).rawData()
                } catch {
                    let postObjectError = NSError(domain: errorDomain, code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: "failed to convert postObject to JSON"])
                    failure!(postError: postObjectError)
                }
            }
            
            urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
                if error != nil {
                    failure!(postError: error!)
                    return
                }
                
                if let httpResponse: NSHTTPURLResponse = response as? NSHTTPURLResponse {
                    if (httpResponse.statusCode > 400) {
                        let responseError = NSError(domain: errorDomain, code: httpResponse.statusCode, userInfo: [NSLocalizedFailureReasonErrorKey: "HTTP 400 or above error", NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
                        failure!(postError: responseError)
                        return
                    }
                }
                
                success!(responseData: data!, response: response!)
            }.resume()
    }

    
}