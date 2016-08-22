//
//  NaiveHTTP+Image.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import UIKit

public extension NaiveHTTPProtocol {
    
    func imageGET(_ uri: String, completion:((_ image: UIImage?, _ response: URLResponse?, _ error: NSError?)->())?) -> URLSessionDataTask? {
        //TODO: Include all the image formats that are supported by UIImage (and eventually, their extensions)
        let headers = [
            "Accept" : "image/png,image/jpg,image/jpeg,image/tiff,image/gif,image/webp"
        ]
        
        return performRequest(.GET, uri: uri, body: nil, headers: headers) { (data, response, error) -> Void in
            guard error == nil else {
                completion?(nil, response, error)
                return
            }
            
            guard let image = UIImage(data: data!) else {
                let imageNilError = NSError(domain: self.errorDomain, code: -1, userInfo: [
                    NSLocalizedFailureReasonErrorKey: "nil UIImage",
                    NSLocalizedDescriptionKey: "image data retrieved resulted in a nil UIImage"])
                completion?(nil, response, imageNilError)
                return
            }
            
            completion?(image, response, error)
        }
    }
    
}
