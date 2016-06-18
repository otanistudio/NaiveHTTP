//
//  NaiveHTTP.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/20/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation

public enum Method: String {
    case GET        = "GET"
    case HEAD       = "HEAD"
    case OPTIONS    = "OPTIONS"
    case POST       = "POST"
    case PUT        = "PUT"
    case DELETE     = "DELETE"
}

public typealias NaiveMethod = Method

public protocol NaiveHTTPProtocol {
    var urlSession: URLSession { get }
    var configuration: URLSessionConfiguration { get }
    var errorDomain: String { get }

    func performRequest(
        _ method: Method,
        uri: String,
        body: Data?,
        headers: [String : String]?,
        completion: ((data: Data?, response: URLResponse?, error: NSError?) -> Void)?
    ) -> URLSessionDataTask?
}

public final class NaiveHTTP: NaiveHTTPProtocol {
    public let errorDomain = "com.otanistudio.NaiveHTTP.error"
    public typealias completionHandler = (data: Data?, response: URLResponse?, error: NSError?) -> Void
    
    public let urlSession: URLSession
    public let configuration: URLSessionConfiguration
    
    required public init(_ configuration: URLSessionConfiguration? = nil) {
        if let config = configuration {
            self.configuration = config
            urlSession = URLSession(configuration: config)
        } else {
            self.configuration = URLSessionConfiguration.ephemeral()
            urlSession = URLSession(configuration: self.configuration)
        }
    }
    
    deinit {
        urlSession.invalidateAndCancel()
    }
    
    public func performRequest(
        _ method: Method,
        uri: String,
        body: Data?,
        headers: [String : String]?,
        completion: completionHandler?) -> URLSessionDataTask? {
            
        let url = URL(string: uri)
        if url == nil {
            let urlError = NSError(domain: errorDomain, code: -13, userInfo: [
                NSLocalizedFailureReasonErrorKey : "could not create NSURL from string"
                ])
            completion?(data: nil, response: nil, error: urlError)
            return nil
        }
        var req = URLRequest(url: url!)
        req.httpMethod = "\(method)"
        
        if headers != nil {
            for (k, v) in headers! {
                req.setValue(v, forHTTPHeaderField: k)
            }
        }
        
        if method == .POST || method == .PUT || method == .DELETE {
            req.httpBody = body
        }
        

        let task = urlSession.dataTask(with: req) { (data: Data?, response: URLResponse?, error: NSError?) in
            guard error == nil else {
                completion?(data: data, response: response, error: error)
                return
            }
            
            if let httpResponse: HTTPURLResponse = response as? HTTPURLResponse {
                if (httpResponse.statusCode >= 400) {
                    let responseError = NSError(domain: self.errorDomain, code: httpResponse.statusCode, userInfo: [NSLocalizedFailureReasonErrorKey: "HTTP 400 or above error", NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
                    completion?(data: data, response: response, error: responseError)
                    return
                }
            }
            
            completion?(data: data, response: response, error: error)
            
        }
        
        task.resume()
        return task
    }
}
