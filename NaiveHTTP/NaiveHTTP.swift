//
//  NaiveHTTP.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/20/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import UIKit

public class NaiveHTTP {
    let urlSession: NSURLSession!
    public let configuration: NSURLSessionConfiguration!
    let errorDomain = "com.otanistudio.NaiveHTTP.error"
    
    required public init(configuration: NSURLSessionConfiguration?) {
        if let config = configuration {
            self.configuration = config
            urlSession = NSURLSession(configuration: config)
        } else {
            self.configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        }
    }
    
    deinit {
        urlSession.invalidateAndCancel()
    }
    
    public class func normalizedURL(uri uri:String, params:[String: String]?) -> NSURL {
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
    
    public func GET(uri uri:String, successImage:((image: UIImage?, response: NSURLResponse)->())?, failure:((error: NSError)->())?) {
        
        let url = NSURL(string: uri)!
        let request = NSMutableURLRequest(URL: url)
        request.setValue("image/png,image/jpg,image/jpeg,image/tiff,image/gif", forHTTPHeaderField: "Accept")
        
        dataGET(uri: uri, params: nil, success: { (imageData, response) -> () in
            let image = UIImage(data: imageData)
            successImage!(image: image, response: response)
            }, failure: failure)
    }
    
    public func dataGET(uri uri:String, params:[String: String]?, success:((data: NSData, response: NSURLResponse)->())?, failure:((error: NSError)->Void)?) {
        
        let url: NSURL =  NaiveHTTP.normalizedURL(uri: uri, params: params)
        
        urlSession.dataTaskWithURL(url) { [weak self](responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if (error != nil) {
                failure!(error: error!)
                return
            }
            
            if let httpResponse: NSHTTPURLResponse = response as? NSHTTPURLResponse {
                if (httpResponse.statusCode > 400) {
                    let responseError = NSError(domain: self!.errorDomain, code: 400, userInfo: nil)
                    failure!(error: responseError)
                    return
                }
            }            
            
            success!(data: responseData!, response: response!)
            
            }.resume()
    }
    
    public func jsonGET(uri uri:String, params:[String: String]?, success:((json: JSON, response: NSURLResponse)->())?, failure:((error: NSError)->Void)?) {
        dataGET(uri: uri, params: params, success: { (data, response) -> () in
            let json = JSON(data: data)
            
            if let error = json.error {
                debugPrint(error)
                failure!(error: error)
                return
            }
            
            success!(json: json, response: response)
            
            }, failure: failure)
    }
    
    public func get(uri uri:String, params:[String: String]?, responseFilter: String?, success:((json: JSON, response: NSURLResponse)->())?, failure:((error: NSError)->Void)?) {
        dataGET(uri: uri, params: params, success: { [weak self](data, response) -> () in
            
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
            
            success!(json: json!, response: response)
            
            }, failure: failure)
    }
    
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
    
    public func post(uri uri:String, postObject: AnyObject?, preFilter: String?, additionalHeaders: [String: String]?, success: ((responseJSON: JSON, response: NSURLResponse)->())?, failure:((postError: NSError)->())?) {
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
                let postObjectError = NSError(domain: self.errorDomain, code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: "failed to convert postObject to JSON"])
                failure!(postError: postObjectError)
            }
        }
        
        urlSession.dataTaskWithRequest(request) { [weak self](data, response, error) -> Void in
            if error != nil {
                failure!(postError: error!)
                return
            }
            
            if let httpResponse: NSHTTPURLResponse = response as? NSHTTPURLResponse {
                if (httpResponse.statusCode > 400) {
                    let responseError = NSError(domain: self!.errorDomain, code: 400, userInfo: [NSLocalizedFailureReasonErrorKey: "400 or above error", NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
                    failure!(postError: responseError)
                    return
                }
            }
            
            let json: JSON?
            
            if preFilter != nil {
                json = self!.preFilterResponseData(preFilter!, data: data)
            } else {
                json = JSON(data: data!)
            }
            
            success!(responseJSON: json!, response: response!)
            }.resume()
    }
    
    public func post(uri uri:String, postObject: AnyObject?, additionalHeaders: [String:String]?, success: ((responseJSON: JSON, response: NSURLResponse)->())?, failure:((postError: NSError)->())?) {
        post(uri: uri, postObject: postObject, preFilter: nil, additionalHeaders: additionalHeaders, success: success, failure: failure)
    }
    
    public func post(uri uri:String, postObject: AnyObject?, success: ((responseJSON: JSON, response: NSURLResponse)->Void)?, failure:( (postError: NSError)->Void )?) {
        post(uri: uri, postObject: postObject, additionalHeaders: nil, success: success, failure: failure)
    }
    
    
}