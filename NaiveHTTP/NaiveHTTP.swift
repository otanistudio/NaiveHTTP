//
//  NaiveHTTP.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/20/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import UIKit

public class NaiveHTTP {
    let urlSession: NSURLSession!
    
    required public init(configuration: NSURLSessionConfiguration?) {
        if let config = configuration {
            urlSession = NSURLSession(configuration: config)
        } else {
            urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        }
    }
    
    deinit {
        urlSession.invalidateAndCancel()
    }
    
    public func imageGET(uri uri:String, success:((image: UIImage?)->())?, failure:(()->())?) {
        
        let url = NSURL(string: uri)!
        let request = NSMutableURLRequest(URL: url)
        request.setValue("image/png,image/jpg,image/jpeg,image/tiff,image/gif", forHTTPHeaderField: "Accept")
        
        urlSession.dataTaskWithRequest(request) { (imageData: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            let image = UIImage(data: imageData!)
            success!(image: image)
            
            }.resume()
        
    }
    
    public func dataGET(uri uri:String, success:((data: NSData)->())?, failure:(()->())?) {
        let url = NSURL(string: uri)!
        
        urlSession.dataTaskWithURL(url) { (responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            
            if (error != nil) {
                failure!()
                return
            }
            
            if (httpResponse.statusCode > 400) {
                failure!()
                return
            }
            
            success!(data: responseData!)
            
            }.resume()
    }
    
    public func jsonGET(uri uri:String, success:((json: JSON)->())?, failure:(()->())?) {
        dataGET(uri: uri, success: { (data) -> () in
            let json = JSON(data: data)
            
            if let error = json.error {
                debugPrint(error)
                failure!()
                return
            }
            
            success!(json: json)
            
            }, failure: failure)
    }
    
    public func post(uri uri:String, postObject: AnyObject, success: ((responseJSON: JSON)->Void)?, failure:( ()->Void )?) {
        
        let url = NSURL(string: uri)!
        let request = NSMutableURLRequest(URL: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPMethod = "POST"
        
        do {
            try request.HTTPBody = JSON(postObject).rawData()
        } catch {
            failure!()
        }
        
        urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                failure!()
                return
            }
            
            let httpResponse = response as! NSHTTPURLResponse
            
            if (httpResponse.statusCode > 400) {
                failure!()
                return
            }
            
            let json = JSON(data: data!)
            success!(responseJSON: json)
            }.resume()
    }
    

}