//
//  WebServicesController.swift
//  WeatherIAMAT
//
//  Created by Haurimton Andres Martin Franco on 6/13/17.
//  Copyright © 2017 Haurimton Andres Martin Franco. All rights reserved.
//

import Alamofire
import AlamofireImage
import UIKit
import SwiftyJSON

class WebServicesController {
    
    class func getDailyForecast(lat: String, lon: String, handleComplete:@escaping ((_ error: Error?, _ data: JSON?)->())) {
        // Add URL parameters
        let urlParams = [
            "APPID":"031cd07a9763a139c45edc008516f0ad",
            "lat":lat,
            "lon":lon
        ]
        
        // Fetch request
        Alamofire.request("http://api.openweathermap.org/data/2.5/forecast/daily", method: .get, parameters: urlParams).validate(statusCode: 200..<300).responseJSON(completionHandler: { response in
            if let data = response.data {
                let json = JSON(data: data)
                handleComplete(response.result.error, json)
            } else {
                print("HTTP Request Failed: \(String(describing: response.result.error))")
                handleComplete(response.result.error, nil)
            }
        })
    }
    
    class func getCityPicture(lat: String, lon: String, cityName: String, handleComplete: @escaping ((_ error: Error?, _ image: UIImage?) -> ())) {
        // Add URL parameters
        // Add URL parameters
        let urlParams = [
            "method":"flickr.photos.search",
            "api_key":"5a20abc69d3c9a4829b2b9c99e743dc8",
            "tags":cityName,
            "text":cityName,
            "lat":lat,
            "lon":lon,
            "format":"json",
            "nojsoncallback":"1",
        ]
        
        // Fetch Request
        
        Alamofire.request("https://api.flickr.com/services/rest/", method: .get, parameters: urlParams).validate(statusCode: 200..<300).responseJSON { response in
            if let data = response.data {
                let json = JSON(data: data)
                if let photosArray = json["photos"]["photo"].array {
                    let photos = photosArray.filter({ photo in
                        return photo["title"].string!.lowercased().contains(cityName)
                    })
                    if !photos.isEmpty {
                        let photo = photos[Int(arc4random_uniform(UInt32((photos.count - 1) - 0)))]
                        if let farm_id = photo["farm"].int, let server_id = photo["server"].string, let photo_id = photo["id"].string, let secret = photo["secret"].string {
                            let urlString = "https://farm\(farm_id).staticflickr.com/\(server_id)/\(photo_id)_\(secret)_b.jpg"
                            if let url = URL(string: urlString) {
                                Alamofire.request(url).responseImage(completionHandler: { response in
                                    handleComplete(response.result.error, response.result.value)
                                })
                            }
                        }
                    } else {
                        handleComplete(Error.self as? Error,nil)
                    }
                } else {
                    handleComplete(Error.self as? Error,nil)
                }
            } else {
                print("HTTP Request Failed: \(String(describing: response.result.error))")
                handleComplete(response.result.error, nil)
            }
        }
    }
    
}
