//
//  NaiveHTTP+JSON.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation

public extension NaiveHTTPProtocol {
    public func GET(
        uri:String,
        params:[String: String]?,
        responseFilter: String?,
        additionalHeaders: [String:String]?,
        completion:((json: JSON?, response: NSURLResponse?, error: NSError?)->())?) {

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
}

public extension NaiveHTTPProtocol {
    
    public func POST(
        uri:String,
        postObject: AnyObject?,
        preFilter: String?,
        additionalHeaders: [String: String]?,
        successJSON: ((responseJSON: JSON, response: NSURLResponse)->())?,
        failure:((postError: NSError)->())?) {
            
            POST(uri, postObject: postObject, additionalHeaders: additionalHeaders) { (data, response, error)->() in
                guard error == nil else {
                    failure?(postError: error!)
                    return
                }
                
                let json: JSON?
                if preFilter != nil {
                    json = self.preFilterResponseData(preFilter!, data: data)
                } else {
                    json = JSON(data: data!)
                }
                
                successJSON?(responseJSON: json!, response: response!)
                
            }
    }

}

