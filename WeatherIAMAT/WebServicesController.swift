//
//  WebServicesController.swift
//  WeatherIAMAT
//
//  Created by Haurimton Andres Martin Franco on 6/13/17.
//  Copyright © 2017 Haurimton Andres Martin Franco. All rights reserved.
//

import Foundation
import Alamofire
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
            if (response.result.error == nil) {
                if let data = response.data {
                    let json = JSON(data: data)
                    handleComplete(response.result.error, json)
                }
            } else {
                print("HTTP Request Failed: \(String(describing: response.result.error))")
                handleComplete(response.result.error, nil)
            }
        })
    }
    
}
