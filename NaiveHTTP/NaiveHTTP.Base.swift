//
//  NaiveHTTP.Base.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation

private let errorDomain = "com.otanistudio.NaiveHTTP.error"

public extension NaiveHTTPProtocol {
    public func GET(
        uri:String,
        params: [String: String]?,
        additionalHeaders: [String: String]?,
        success:((data: NSData, response: NSURLResponse)->())?,
        failure:((error: NSError)->Void)?) {
            
        let url: NSURL =  self.dynamicType.normalizedURL(uri, params: params)
        let request = NSMutableURLRequest(URL: url)
            
        if let headers = additionalHeaders {
            for (k, v) in headers {
                request.setValue(v, forHTTPHeaderField: k)
            }
        }
            
        performRequest(request, success: success, failure: failure)
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
        
        performRequest(request, success:success, failure: failure)
    }
}

extension NaiveHTTPProtocol {
    private func performRequest(
        req: NSURLRequest,
        success:((data: NSData, response: NSURLResponse)->())?,
        failure:((error: NSError)->())?) {
            
        urlSession.dataTaskWithRequest(req) { (data, response, error) -> Void in
            if error != nil {
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
            
            success!(data: data!, response: response!)
        }.resume()
    }
}
