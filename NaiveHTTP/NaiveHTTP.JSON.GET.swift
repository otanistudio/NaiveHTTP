//
//  NaiveHTTP.JSON.GET.swift
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
        successJSON:((json: JSON, response: NSURLResponse)->())?,
        failure:((error: NSError)->Void)?) {
            
        GET(uri, params: params, success: { (data, response) -> () in
            
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
}