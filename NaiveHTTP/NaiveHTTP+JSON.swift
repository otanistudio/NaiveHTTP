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
        successJSON:((json: JSON, response: NSURLResponse)->())?,
        failure:((error: NSError)->Void)?) {
            
            GET(uri, params: params, additionalHeaders: additionalHeaders, success: { (data, response) -> () in
                
                let json: JSON?
                
                if responseFilter != nil {
                    json = self.preFilterResponseData(responseFilter!, data: data)
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

