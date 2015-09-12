//
//  NaiveHTTP+JSON.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation

public extension NaiveHTTPProtocol {
    public typealias jsonCompletion = (json: JSON?, response: NSURLResponse?, error: NSError?) -> Void
    
    public func jsonGET(
        uri:String,
        params:[String: String]?,
        responseFilter: String?,
        additionalHeaders: [String:String]?,
        completion: jsonCompletion?) {

        GET(uri,
            params: params,
            additionalHeaders: additionalHeaders) { (data, response, error) -> () in
            
                guard error == nil else {
                    completion?(json: nil, response: response, error: error)
                    return
                }
                
                let json: JSON?
                let jsonError: NSError?
                
                if responseFilter != nil {
                    json = self.preFilterResponseData(responseFilter!, data: data)
                } else {
                    json = JSON(data: data!)
                }
                
                jsonError = json!.error
                
                completion?(json: json, response: response, error: jsonError)
            }
    }
    
    public func jsonPOST(
        uri:String,
        postObject: AnyObject?,
        preFilter: String?,
        additionalHeaders: [String: String]?,
        completion: jsonCompletion?) {
            
            POST(uri, postObject: postObject, additionalHeaders: additionalHeaders) { (data, response, error)->() in
                guard error == nil else {
                    completion?(json: nil, response: response, error: error)
                    return
                }
                
                // TODO: pass any JSON errors into completion function
                let json: JSON?
                if preFilter != nil {
                    json = self.preFilterResponseData(preFilter!, data: data)
                } else {
                    json = JSON(data: data!)
                }
                
                completion?(json: json, response: response, error: error)
                
            }
    }
}

