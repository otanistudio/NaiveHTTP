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
    
    func imageGET(_ uri: String, completion:((image: UIImage?, response: URLResponse?, error: NSError?)->())?) -> URLSessionDataTask? {
        //TODO: Include all the image formats that are supported by UIImage (and eventually, their extensions)
        let headers = [
            "Accept" : "image/png,image/jpg,image/jpeg,image/tiff,image/gif,image/webp"
        ]
        
        return performRequest(.GET, uri: uri, body: nil, headers: headers) { (data, response, error) -> Void in
            guard error == nil else {
                completion?(image: nil, response: response, error: error)
                return
            }
            
            guard let image = UIImage(data: data!) else {
                let imageNilError = NSError(domain: self.errorDomain, code: -1, userInfo: [
                    NSLocalizedFailureReasonErrorKey: "nil UIImage",
                    NSLocalizedDescriptionKey: "image data retrieved resulted in a nil UIImage"])
                completion?(image: nil, response: response, error: imageNilError)
                return
            }
            
            completion?(image: image, response: response, error: error)
        }
    }
    
}
