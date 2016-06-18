//
//  SwiftyHTTP.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import NaiveHTTP
import enum NaiveHTTP.Method
import SwiftyJSON

public enum SwiftyHTTPError: ErrorProtocol {
    case httpBodyDataConversion
    case swiftyJSONInternal
}

public final class SwiftyHTTP: NaiveHTTPProtocol {
    public let errorDomain = "com.otanistudio.SwiftyHTTP.error"
    public typealias swiftyCompletion = (json: SwiftyJSON.JSON?, response: NSURLResponse?, error: NSError?) -> Void
    
    let naive: NaiveHTTP
    
    public var urlSession: URLSession {
        return naive.urlSession
    }
    
    public var configuration: URLSessionConfiguration {
        return naive.configuration
    }
    
    required public init(_ naiveHTTP: NaiveHTTP? = nil, configuration: URLSessionConfiguration? = nil) {
        if naiveHTTP == nil {
            naive = NaiveHTTP(configuration)
        } else {
            naive = naiveHTTP!
        }
    }
    
    public func GET(
        _ uri:String,
        params:[String: String]?,
        responseFilter: String?,
        headers: [String:String]?,
        completion: swiftyCompletion?) -> URLSessionDataTask? {

        return naive.GET(uri,
            params: params,
            headers: self.jsonHeaders(headers)) { [weak self](data, response, error) -> () in
            
                guard error == nil else {
                    completion?(json: nil, response: response, error: error)
                    return
                }
                
                let json: SwiftyJSON.JSON?
                let jsonError: NSError?
                
                if responseFilter != nil {
                    json = self?.dynamicType.filteredJSON(responseFilter!, data: data)
                } else {
                    json = SwiftyJSON.JSON(data: data!)
                }
                
                jsonError = json!.error
                
                completion?(json: json, response: response, error: jsonError)
            }
    }
    
    public func POST(
        _ uri: String,
        postObject: AnyObject?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: swiftyCompletion?) -> URLSessionDataTask? {
            
            var body: Data? = nil
            if postObject != nil {
                do {
                    body = try jsonData(postObject!)
                } catch {
                    completion?(json: nil, response: nil, error: naiveHTTPSwiftyJSONError)
                    return nil
                }
            }
            
            return naive.POST(uri, body: body, headers: self.jsonHeaders(headers)) { [weak self](data, response, error)->() in
                guard error == nil else {
                    completion?(json: nil, response: response, error: error)
                    return
                }
                
                // TODO: pass any SwiftyJSON.JSON errors into completion function
                let json: SwiftyJSON.JSON?
                if responseFilter != nil {
                    json = self?.dynamicType.filteredJSON(responseFilter!, data: data)
                } else {
                    json = SwiftyJSON.JSON(data: data!)
                }
                
                completion?(json: json, response: response, error: error)
                
            }
    }
    
    public func PUT(
        _ uri: String,
        body: AnyObject?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: swiftyCompletion?) -> URLSessionDataTask? {
        
        var putBody: Data? = nil
            
        if body != nil {
            do {
                putBody = try jsonData(body!)
            } catch {
                completion?(json: nil, response: nil, error: naiveHTTPSwiftyJSONError)
                return nil
            }
        }
            
        return naive.PUT(uri, body: putBody, headers: self.jsonHeaders(headers)) { [weak self](data, response, error) -> Void in
            guard error == nil else {
                completion?(json: nil, response: response, error: error)
                return
            }
            
            // TODO: pass any SwiftyJSON.JSON errors into completion function
            let json: SwiftyJSON.JSON?
            if responseFilter != nil {
                json = self?.dynamicType.filteredJSON(responseFilter!, data: data)
            } else {
                json = SwiftyJSON.JSON(data: data!)
            }
            
            completion?(json: json, response: response, error: error)
        }
            
    }

    public func DELETE(
        _ uri: String,
        body: AnyObject?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: swiftyCompletion?) -> URLSessionDataTask? {

        var deleteBody: Data? = nil
        if body != nil {
            do {
                deleteBody = try jsonData(body!)
            } catch {
                completion?(json: nil, response: nil, error: naiveHTTPSwiftyJSONError)
                return nil
            }
        }
            
        return naive.DELETE(uri, body: deleteBody, headers: self.jsonHeaders(headers)) { [weak self](data, response, error) -> Void in
            guard error == nil else {
                completion?(json: nil, response: response, error: error)
                return
            }

            // TODO: pass any SwiftyJSON.JSON errors into completion function
            let json: SwiftyJSON.JSON?
            if responseFilter != nil {
                json = self?.dynamicType.filteredJSON(responseFilter!, data: data)
            } else {
                json = SwiftyJSON.JSON(data: data!)
            }

            completion?(json: json, response: response, error: error)
        }

    }
    
    /// A convenience function for services that returns a string response prepended with
    /// with an anti-hijacking string.
    ///
    /// Some services return a string, like `while(1);` pre-pended to their SwiftyJSON.JSON string, which can
    /// break the normal decoding dance.
    ///
    /// - parameter prefixFilter: The string to remove from the beginning of the response
    /// - parameter data: The data, usually the response data from of your `NSURLSession` or `NSURLConnection` request
    /// - returns: a valid `SwiftyJSON` object
    public static func filteredJSON(_ prefixFilter: String, data: NSData?) -> SwiftyJSON.JSON {
        let json: SwiftyJSON.JSON?
        
        if let unfilteredJSONStr = NSString(data: data!, encoding: String.Encoding.utf8) {
            if unfilteredJSONStr.hasPrefix(prefixFilter) {
                let range = unfilteredJSONStr.rangeOfString(prefixFilter, options: .LiteralSearch)
                let filteredStr = unfilteredJSONStr.substringFromIndex(range.length)
                let filteredData = filteredStr.dataUsingEncoding(String.Encoding.utf8, allowLossyConversion: false)
                json = SwiftyJSON.JSON(data: filteredData!)
            } else {
                let filteredData = unfilteredJSONStr.dataUsingEncoding(String.Encoding.utf8, allowLossyConversion: false)
                json = SwiftyJSON.JSON(data: filteredData!)
            }
        } else {
            json = SwiftyJSON.JSON(NSNull())
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
    
    private func jsonData(_ object: AnyObject) throws -> Data {
        do {
            let o = SwiftyJSON.JSON(object)
            if o.type == .String {
                if let jsonData: Data = (o.stringValue as NSString).dataUsingEncoding(String.Encoding.utf8) {
                    return jsonData
                } else {
                    throw SwiftyHTTPError.httpBodyDataConversion
                }
            } else {
                return try o.rawData()
            }
        } catch let jsonError as NSError {
            debugPrint("NaiveHTTP+JSON: \(jsonError)")
            throw SwiftyHTTPError.swiftyJSONInternal
        }
    }
    
    public func performRequest(_ method: Method, uri: String, body: Data?, headers: [String : String]?, completion: ((data: Data?, response: URLResponse?, error: NSError?) -> Void)?) -> URLSessionDataTask? {
        return naive.performRequest(method, uri: uri, body: body, headers: headers, completion: { (data, response, error) -> Void in
            completion?(data: data, response: response, error: error)
        })
    }

    private func jsonHeaders(_ additionalHeaders: [String : String]?) -> [String : String] {
        let jsonHeaders: [String : String] = [
            "Accept" : "application/json",
            "Content-Type" : "application/json"
        ]
        
        let headers: [String : String]?
        if let additional = additionalHeaders {
            headers = additional.reduce(jsonHeaders) { dict, pair in
                var fixed = dict
                fixed[pair.0] = pair.1
                return fixed
            }
        } else {
            headers = jsonHeaders
        }
        
        return headers!
    }
}

