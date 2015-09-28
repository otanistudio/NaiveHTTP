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
        headers: [String:String]?,
        completion: jsonCompletion?) {

        GET(uri,
            params: params,
            headers: self.jsonHeaders(headers)) { (data, response, error) -> () in
            
                guard error == nil else {
                    completion?(json: nil, response: response, error: error)
                    return
                }
                
                let json: JSON?
                let jsonError: NSError?
                
                if responseFilter != nil {
                    json = Utility.filteredJSON(responseFilter!, data: data)
                } else {
                    json = JSON(data: data!)
                }
                
                jsonError = json!.error
                
                completion?(json: json, response: response, error: jsonError)
            }
    }
    
    public func jsonPOST(
        uri: String,
        postObject: AnyObject?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: jsonCompletion?) {
            
            POST(uri, postObject: postObject, headers: self.jsonHeaders(headers)) { (data, response, error)->() in
                guard error == nil else {
                    completion?(json: nil, response: response, error: error)
                    return
                }
                
                // TODO: pass any JSON errors into completion function
                let json: JSON?
                if responseFilter != nil {
                    json = Utility.filteredJSON(responseFilter!, data: data)
                } else {
                    json = JSON(data: data!)
                }
                
                completion?(json: json, response: response, error: error)
                
            }
    }
    
    public func jsonPUT(
        uri: String,
        body: AnyObject?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: jsonCompletion?) {
        
        PUT(uri, body: body, headers: self.jsonHeaders(headers)) { (data, response, error) -> Void in
            guard error == nil else {
                completion?(json: nil, response: response, error: error)
                return
            }
            
            // TODO: pass any JSON errors into completion function
            let json: JSON?
            if responseFilter != nil {
                json = Utility.filteredJSON(responseFilter!, data: data)
            } else {
                json = JSON(data: data!)
            }
            
            completion?(json: json, response: response, error: error)
        }
            
    }
    
    private func jsonHeaders(additionalHeaders: [String : String]?) -> [String : String] {
        let jsonHeaders: [String : String] = [
            "Accept" : "application/json",
            "Content-Type" : "application/json"
        ]
        
        let headers: [String : String]?
        if let additional = additionalHeaders {
            headers = additional.reduce(jsonHeaders) { (var dict, pair) in
                dict[pair.0] = pair.1
                return dict
            }
        } else {
            headers = jsonHeaders
        }
        
        return headers!
    }
}

