//
//  NaiveHTTP+SwiftyJSON.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation

public enum NaiveHTTPSwiftyJSONError: ErrorType {
    case HTTPBodyDataConversion
    case SwiftyJSONInternal
}

public extension NaiveHTTPProtocol {
    public typealias swiftyCompletion = (json: JSON?, response: NSURLResponse?, error: NSError?) -> Void
    
    public func jsonGET(
        uri:String,
        params:[String: String]?,
        responseFilter: String?,
        headers: [String:String]?,
        completion: swiftyCompletion?) -> NSURLSessionDataTask? {

        return GET(uri,
            params: params,
            headers: self.jsonHeaders(headers)) { (data, response, error) -> () in
            
                guard error == nil else {
                    completion?(json: nil, response: response, error: error)
                    return
                }
                
                let json: JSON?
                let jsonError: NSError?
                
                if responseFilter != nil {
                    json = self.dynamicType.filteredJSON(responseFilter!, data: data)
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
        completion: swiftyCompletion?) -> NSURLSessionDataTask? {
            
            var body: NSData? = nil
            if postObject != nil {
                do {
                    body = try jsonData(postObject!)
                } catch {
                    completion?(json: nil, response: nil, error: naiveHTTPSwiftyJSONError)
                    return nil
                }
            }
            
            return POST(uri, body: body, headers: self.jsonHeaders(headers)) { (data, response, error)->() in
                guard error == nil else {
                    completion?(json: nil, response: response, error: error)
                    return
                }
                
                // TODO: pass any JSON errors into completion function
                let json: JSON?
                if responseFilter != nil {
                    json = self.dynamicType.filteredJSON(responseFilter!, data: data)
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
        completion: swiftyCompletion?) -> NSURLSessionDataTask? {
        
        var putBody: NSData? = nil
            
        if body != nil {
            do {
                putBody = try jsonData(body!)
            } catch {
                completion?(json: nil, response: nil, error: naiveHTTPSwiftyJSONError)
                return nil
            }
        }
            
        return PUT(uri, body: putBody, headers: self.jsonHeaders(headers)) { (data, response, error) -> Void in
            guard error == nil else {
                completion?(json: nil, response: response, error: error)
                return
            }
            
            // TODO: pass any JSON errors into completion function
            let json: JSON?
            if responseFilter != nil {
                json = self.dynamicType.filteredJSON(responseFilter!, data: data)
            } else {
                json = JSON(data: data!)
            }
            
            completion?(json: json, response: response, error: error)
        }
            
    }

    public func jsonDELETE(
        uri: String,
        body: AnyObject?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: swiftyCompletion?) -> NSURLSessionDataTask? {

        var deleteBody: NSData? = nil
        if body != nil {
            do {
                deleteBody = try jsonData(body!)
            } catch {
                completion?(json: nil, response: nil, error: naiveHTTPSwiftyJSONError)
                return nil
            }
        }
            
        return DELETE(uri, body: deleteBody, headers: self.jsonHeaders(headers)) { (data, response, error) -> Void in
            guard error == nil else {
                completion?(json: nil, response: response, error: error)
                return
            }

            // TODO: pass any JSON errors into completion function
            let json: JSON?
            if responseFilter != nil {
                json = self.dynamicType.filteredJSON(responseFilter!, data: data)
            } else {
                json = JSON(data: data!)
            }

            completion?(json: json, response: response, error: error)
        }

    }
    
    /// A convenience function for services that returns a string response prepended with
    /// with an anti-hijacking string.
    ///
    /// Some services return a string, like `while(1);` pre-pended to their JSON string, which can
    /// break the normal decoding dance.
    ///
    /// - parameter prefixFilter: The string to remove from the beginning of the response
    /// - parameter data: The data, usually the response data from of your `NSURLSession` or `NSURLConnection` request
    /// - returns: a valid `SwiftyJSON` object
    public static func filteredJSON(prefixFilter: String, data: NSData?) -> JSON {
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
    
    private var naiveHTTPSwiftyJSONError: NSError {
       return NSError(
        domain: errorDomain,
        code: -3,
        userInfo: [
            NSLocalizedFailureReasonErrorKey : "SwiftyJSON Error",
            NSLocalizedDescriptionKey: "Error while processing objects to SwiftyJSON data"
        ])
    }
    
    private func jsonData(object: AnyObject) throws -> NSData {
        do {
            let o = JSON(object)
            if o.type == .String {
                if let jsonData: NSData = (o.stringValue as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
                    return jsonData
                } else {
                    throw NaiveHTTPSwiftyJSONError.HTTPBodyDataConversion
                }
            } else {
                return try o.rawData()
            }
        } catch let jsonError as NSError {
            debugPrint("NaiveHTTP+JSON: \(jsonError)")
            throw NaiveHTTPSwiftyJSONError.SwiftyJSONInternal
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

