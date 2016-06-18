//
//  FreddyHTTP.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 5/6/16.
//  Copyright © 2016 otanistudio.com. All rights reserved.
//

import Foundation
import NaiveHTTP
import enum NaiveHTTP.Method
import Freddy

public enum FreddyHTTPError: ErrorProtocol {
    case httpBodyDataConversion
    case freddyJSONInternal
}

public final class FreddyHTTP: NaiveHTTPProtocol {
    public let errorDomain = "com.otanistudio.FreddyHTTP.error"
    public typealias freddyCompletion = (json: Freddy.JSON?, response: NSURLResponse?, error: NSError?) -> Void
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
        completion: freddyCompletion?) -> URLSessionDataTask? {
        
        let task = naive.GET(uri,
                  params: params,
                  headers: self.jsonHeaders(headers)) { [weak self](data, response, error) in
                    
                    guard error == nil else {
                        completion?(json: nil, response: response, error: error)
                        return
                    }
            
                    let json: Freddy.JSON?

                    if responseFilter != nil {
                        json = self?.dynamicType.filteredJSON(responseFilter!, data: data)
                    } else {
                        do {
                            json = try Freddy.JSON(data: data!)
                        } catch let e {
                            completion?(json: nil, response: response, error: self?.jsonError(e))
                            return
                        }
                    }
                    
                    completion?(json: json, response: response, error: nil)
                    
        }
        return task
        
    }
    
    public func POST(
        _ uri: String,
        postObject: AnyObject?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: freddyCompletion?) -> URLSessionDataTask? {
        
        var body: Data? = nil
        if postObject != nil {
            do {
                body = try jsonData(postObject!)
            } catch let e {
                completion?(json: nil, response: nil, error: jsonError(e))
                return nil
            }
        }
        
        return naive.POST(uri, body: body, headers: self.jsonHeaders(headers)) { [weak self](data, response, error) in
            guard error == nil else {
                completion?(json: nil, response: response, error: error)
                return
            }
            
            // TODO: pass any SwiftyJSON.JSON errors into completion function
            let json: Freddy.JSON?
            if responseFilter != nil {
                json = self?.dynamicType.filteredJSON(responseFilter!, data: data)
            } else {
                json = try! Freddy.JSON(data: data!)
            }
            
            completion?(json: json, response: response, error: error)
            
        }
    }
    
    public func PUT(
        _ uri: String,
        body: AnyObject?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: freddyCompletion?) -> URLSessionDataTask? {
        
        var putBody: Data? = nil
        
        if body != nil {
            do {
                putBody = try jsonData(body!)
            } catch let e {
                completion?(json: nil, response: nil, error: jsonError(e))
                return nil
            }
        }
        
        return naive.PUT(uri, body: putBody, headers: self.jsonHeaders(headers)) { [weak self](data, response, error) -> Void in
            guard error == nil else {
                completion?(json: nil, response: response, error: error)
                return
            }
            
            // TODO: pass any SwiftyJSON.JSON errors into completion function
            let json: Freddy.JSON?
            if responseFilter != nil {
                json = self?.dynamicType.filteredJSON(responseFilter!, data: data)
            } else {
                json = try! Freddy.JSON(data: data!)
            }
            
            completion?(json: json, response: response, error: error)
        }
        
    }
    
    public func DELETE(
        _ uri: String,
        body: AnyObject?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: freddyCompletion?) -> URLSessionDataTask? {
        
        var deleteBody: Data? = nil
        if body != nil {
            do {
                deleteBody = try jsonData(body!)
            } catch let e {
                completion?(json: nil, response: nil, error: jsonError(e))
                return nil
            }
        }
        
        return naive.DELETE(uri, body: deleteBody, headers: self.jsonHeaders(headers)) { [weak self](data, response, error) -> Void in
            guard error == nil else {
                completion?(json: nil, response: response, error: error)
                return
            }
            
            // TODO: pass any SwiftyJSON.JSON errors into completion function
            let json: Freddy.JSON?
            if responseFilter != nil {
                json = self?.dynamicType.filteredJSON(responseFilter!, data: data)
            } else {
                json = try! Freddy.JSON(data: data!)
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
    public static func filteredJSON(_ prefixFilter: String, data: NSData?) -> Freddy.JSON {
        let json: Freddy.JSON?
        var filteredData: Data?
        
        if let unfilteredJSONStr = NSString(data: data!, encoding: String.Encoding.utf8) {
            if unfilteredJSONStr.hasPrefix(prefixFilter) {
                let range = unfilteredJSONStr.rangeOfString(prefixFilter, options: .LiteralSearch)
                let filteredStr = unfilteredJSONStr.substringFromIndex(range.length)
                filteredData = filteredStr.dataUsingEncoding(String.Encoding.utf8, allowLossyConversion: false)
            } else {
                filteredData = unfilteredJSONStr.dataUsingEncoding(String.Encoding.utf8, allowLossyConversion: false)
            }
        }
        
        guard let data = filteredData else {
            return JSON.Null
        }
        
        do {
            json = try Freddy.JSON(data: data)
        } catch {
            return JSON.Null
        }
        
        return json!
    }
    
    private func jsonError(_ error: ErrorProtocol) -> NSError {
        return NSError(
            domain: errorDomain,
            code: -3,
            userInfo: [
                NSLocalizedFailureReasonErrorKey : "FreddyJSON Error",
                NSLocalizedDescriptionKey: "Error while processing objects to Freddy.JSON data",
                "Error from Freddy.JSON" : "\(error)"
            ])
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
    
    private func jsonData(_ object: AnyObject) throws -> Data {
        switch object {
        case is String:
            if let jsonData: Data = (object.stringValue as NSString).data(using: String.Encoding.utf8.rawValue) {
                return jsonData
            } else {
                throw FreddyHTTPError.httpBodyDataConversion
            }
        case is [String : String]:
            return try (object as! [String : String]).toJSON().serialize()
        case is [String]:
            return try (object as! [String]).toJSON().serialize()
        default:
            return try Freddy.JSON(object as! String).serialize()
        }
    }
    
}
