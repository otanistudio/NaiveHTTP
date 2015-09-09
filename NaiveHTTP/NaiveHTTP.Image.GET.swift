//
//  NaiveHTTP.Image.GET.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import UIKit

public extension NaiveHTTPProtocol {
    
    func GET(uri:String, successImage:((image: UIImage?, response: NSURLResponse)->())?, failure:((error: NSError)->())?) {
        let url = NSURL(string: uri)!
        let request = NSMutableURLRequest(URL: url)
        //TODO: (ASAP) We should be actually using this request object!!!
        request.setValue("image/png,image/jpg,image/jpeg,image/tiff,image/gif", forHTTPHeaderField: "Accept")
        
        GET(uri, params: nil, additionalHeaders: nil, success: { (imageData, response) -> () in
            let image = UIImage(data: imageData)
            successImage!(image: image, response: response)
            }, failure: failure)
    }
    
}
