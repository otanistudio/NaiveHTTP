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

public extension NaiveHTTPProtocol {
    private func preFilterResponseData(prefixFilter: String, data: NSData?) -> JSON {
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

public extension NaiveHTTPProtocol {
    func GET(uri:String, successImage:((image: UIImage?, response: NSURLResponse)->())?, failure:((error: NSError)->())?) {
        let url = NSURL(string: uri)!
        let request = NSMutableURLRequest(URL: url)
        request.setValue("image/png,image/jpg,image/jpeg,image/tiff,image/gif", forHTTPHeaderField: "Accept")
        
        GET(uri, params: nil, success: { (imageData, response) -> () in
            let image = UIImage(data: imageData)
            successImage!(image: image, response: response)
            }, failure: failure)
    }
}

public extension NaiveHTTPProtocol {

    public func POST(
        uri:String,
        postObject: AnyObject?,
        preFilter: String?,
        additionalHeaders: [String: String]?,
        successJSON: ((responseJSON: JSON, response: NSURLResponse)->())?,
        failure:((postError: NSError)->())?) {
        
        POST(uri, postObject: postObject, additionalHeaders: additionalHeaders, success: { (responseData, response) -> () in
            
            let json: JSON?
            if preFilter != nil {
                json = self.preFilterResponseData(preFilter!, data: responseData)
            } else {
                json = JSON(data: responseData)
            }
            
            successJSON!(responseJSON: json!, response: response)
            
            }) { (postError) -> () in
                failure!(postError: postError)
        }
    }
    
    public func POST(
        uri:String,
        postObject: AnyObject?,
        successJSON: ((responseJSON: JSON, response: NSURLResponse)->Void)?,
        failure:( (postError: NSError)->Void )?) {
            
        POST(uri, postObject: postObject, additionalHeaders: nil, successJSON: successJSON, failure: failure)
    }
    
    public func POST(
        uri:String,
        postObject: AnyObject?,
        additionalHeaders: [String:String]?,
        successJSON: ((responseJSON: JSON, response: NSURLResponse)->())?,
        failure:((postError: NSError)->())?) {
            
        POST(uri, postObject: postObject, preFilter: nil, additionalHeaders: additionalHeaders, successJSON: successJSON, failure: failure)
    }
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
    
    public func GET(
        uri:String,
        params:[String: String]?,
        successJSON:((json: JSON, response: NSURLResponse)->())?,
        failure:((error: NSError)->Void)?) {
            
        GET(uri, params: params, success: { (data, response) -> () in
            let json = JSON(data: data)
            
            if let error = json.error {
                debugPrint(error)
                failure!(error: error)
                return
            }
            
            successJSON!(json: json, response: response)
            
            }, failure: failure)
    }
    
    public func GET(
        uri:String,
        params:[String: String]?,
        responseFilter: String?,
        successJSON:((json: JSON, response: NSURLResponse)->())?,
        failure:((error: NSError)->Void)?) {
            
        GET(uri, params: params, success: { [weak self](data, response) -> () in
            
            let json: JSON?
            
            if responseFilter != nil {
                json = self!.preFilterResponseData(responseFilter!, data: data)
            } else {
                json = JSON(data: data)
            }
            
            if let error = json!.error {
                debugPrint(error)
                failure!(error: error)
                return
            }
            
            successJSON!(json: json!, response: response)
            
            }, failure: failure)
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