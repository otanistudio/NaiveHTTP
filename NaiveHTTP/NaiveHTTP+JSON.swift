//
//  NaiveHTTP+JSON.swift
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
    public typealias jsonCompletion = (json: JSON?, response: NSURLResponse?, error: NSError?) -> Void

    public func jsonGET(
        uri:String,
        params:[String: String]?,
        responseFilter: String?,
        headers: [String:String]?,
        completion: jsonCompletion?) -> NSURLSessionDataTask? {

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
        completion: jsonCompletion?) -> NSURLSessionDataTask? {
            
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
        completion: jsonCompletion?) -> NSURLSessionDataTask? {
        
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
                json = Utility.filteredJSON(responseFilter!, data: data)
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
        completion: jsonCompletion?) -> NSURLSessionDataTask? {

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
                json = Utility.filteredJSON(responseFilter!, data: data)
            } else {
                json = JSON(data: data!)
            }

            completion?(json: json, response: response, error: error)
        }

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

