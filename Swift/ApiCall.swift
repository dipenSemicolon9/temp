//
//  ApiCall.swift
//  NativeWsCall
//
//  Created by tasol on 10/25/16.
//  Copyright © 2016 tasol. All rights reserved.
//

import UIKit

class ApiCall: NSObject {

    class var sharedAPICall: ApiCall {
        struct Static {
            static var instance: ApiCall?
            static var token: dispatch_once_t = 0
        }
        dispatch_once(&Static.token) {
            Static.instance = ApiCall()
        }
        return Static.instance!
    }
    
    func callApi (urlPath: String, withParameter dictData: NSMutableDictionary, withLoader showLoader: Bool, successBlock success:(responceData:AnyObject)->Void , FailurBlock failur:(failurData:AnyObject)->Void) {

        let url = NSURL(string: urlPath)!
        let urlRequest = NSMutableURLRequest(URL: url)
            //urlRequest.HTTPMethod = "POST"
        let queue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: queue) { (response:NSURLResponse?, data:NSData?, error:NSError?) in
            
            do {
                if error == nil {
                    let dictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                    success(responceData: dictionary)
                }
                else {
                    print("\(error)")
                    
                }
            }
            catch let error {
                print("\(error)")
                failur(failurData: "")
            }
            
        }
    }
    
    
    func callApiImageUpload (urlPath: String, withParameter dictData: NSMutableDictionary, withLoader showLoader: Bool,img:UIImage,imgTagName:String, successBlock success:(responceData:AnyObject)->Void , FailurBlock failur:(failurData:AnyObject)->Void) {
    
        let url = NSURL(string: urlPath)!
        let urlRequest = NSMutableURLRequest(URL: url)
        urlRequest.HTTPMethod = "POST"
       
        //image upload code
        let boundary = generateBoundaryString()

        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let image_data = UIImagePNGRepresentation(img)
        if(image_data == nil)
        {
            return
        }
        
        
        let body = NSMutableData()
        
        let fname = "test.png"
        let mimetype = "image/png"
        
        //define the data post parameter
        
        for key  in dictData.allKeys{

            body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            body.appendData("Content-Disposition:form-data; name=\"\(key as! String)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            body.appendData("\(dictData.valueForKey(key as! String)!)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            
        }

        body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Disposition:form-data; name=\"\(imgTagName)\"; filename=\"\(fname)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Type: \(mimetype)\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData(image_data!)
        body.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        
        body.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)

        urlRequest.HTTPBody = body
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) {
            (
            let data, let response, let error) in
            
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                print("error")
                return
            }
            
            let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print(dataString)
            
        }
        
        task.resume()
        
    }
    func generateBoundaryString() -> String
    {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    
    
}
