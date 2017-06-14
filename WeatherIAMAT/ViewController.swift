//
//  ViewController.swift
//  WeatherIAMAT
//
//  Created by Haurimton Andres Martin Franco on 6/13/17.
//  Copyright © 2017 Haurimton Andres Martin Franco. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON
import Charts

class ViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var imageBackground: UIImageView!
    @IBOutlet weak var labelCity: UILabel!
    @IBOutlet weak var labelCountry: UILabel!
    @IBOutlet weak var viewBarChart: BarChartView!
    var locationManager: CLLocationManager!
    var inCelsius: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    fileprivate func drawForecastBarChart(forecastArray: [JSON]) {
        // Initialize an array to store chart data entries (values; y axis)
        var forecastMinEntries = [ChartDataEntry]()
        var forecastMaxEntries = [ChartDataEntry]()
        
        // Initialize an array to store months (labels; x axis)
        var forecastDays = [String]()
        
        for index in 0..<forecastArray.count {
            if let minTemp = forecastArray[index]["temp"]["min"].double, let maxTemp = forecastArray[index]["temp"]["max"].double {
                // Create single chart data entry and append it to the array
                var minTempFormatted: Double!
                if inCelsius {
                    minTempFormatted = minTemp - 273.15
                }
                var maxTempFormatted: Double!
                if inCelsius {
                    maxTempFormatted = maxTemp - 273.15
                }
                
                forecastMinEntries.append(BarChartDataEntry(x: Double(index), y: minTempFormatted))
                forecastMaxEntries.append(BarChartDataEntry(x: Double(index + 1), y: maxTempFormatted))
                
                // Append the day to the array
                if let dt = forecastArray[index]["dt"].double {
                    let date = Date(timeIntervalSince1970: dt)
                    let f = DateFormatter()
                    let dayName = f.weekdaySymbols[Calendar.current.component(.weekday, from: date) - 1]
                    var dayNameShort = dayName.substring(to: dayName.index(dayName.startIndex, offsetBy: 3))
                    if let weatherArray = forecastArray[index]["weather"].array {
                        if let condition = weatherArray[0]["main"].string {
                            if (condition.lowercased().contains("sun")) {
                                dayNameShort.append(" ☀️")
                            } else if (condition.lowercased().contains("cloud")) {
                                dayNameShort.append(" ☁️")
                            } else if (condition.lowercased().contains("rain")) {
                                dayNameShort.append(" 🌧")
                            }
                        }
                    }
                    forecastDays.append(dayNameShort)
                }
            }
        }
        
        // http://openweathermap.org/img/w/"iconCode".png
        
        viewBarChart.chartDescription?.text = "Daily Forecast"
        
        let xAxis = viewBarChart.xAxis
        xAxis.drawGridLinesEnabled = true
        xAxis.labelPosition = .bottom
        xAxis.centerAxisLabelsEnabled = true
        xAxis.valueFormatter = IndexAxisValueFormatter(values: forecastDays)
        xAxis.granularity = 1
        
        let leftAxisFormatter = NumberFormatter()
        leftAxisFormatter.maximumFractionDigits = 1
        
        let yAxis = viewBarChart.leftAxis
        yAxis.spaceTop = 0.35
        yAxis.axisMinimum = 0
        yAxis.drawGridLinesEnabled = false
        
        viewBarChart.rightAxis.enabled = false
        
        // Create bar chart data set containing salesEntries
        let chartDataSetMin = BarChartDataSet(values: forecastMinEntries, label: "Min.")
        let chartDataSetMax = BarChartDataSet(values: forecastMaxEntries, label: "Max.")
        let dataSets: [BarChartDataSet] = [chartDataSetMin, chartDataSetMax]
        chartDataSetMax.colors = [UIColor.yellow]
        
        // Create bar chart data with data sets and array with values for x axis
        let chartData = BarChartData(dataSets: dataSets)
        
        let groupSpace = 0.3
        let barSpace = 0.05
        let barWidth = 0.3
        
        let groupCount = forecastDays.count
        let startYear = 0
        
        
        chartData.barWidth = barWidth;
        viewBarChart.xAxis.axisMinimum = Double(startYear)
        let gg = chartData.groupWidth(groupSpace: groupSpace, barSpace: barSpace)
        viewBarChart.xAxis.axisMaximum = Double(startYear) + gg * Double(groupCount)
        
        chartData.groupBars(fromX: Double(startYear), groupSpace: groupSpace, barSpace: barSpace)
        
        // Set bar chart data to previously created data
        viewBarChart.notifyDataSetChanged()
        viewBarChart.data = chartData
        viewBarChart.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        
        //chart animation
        viewBarChart.animate(xAxisDuration: 1.5, yAxisDuration: 1.5, easingOption: .linear)
    }

}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("DIDUPDATELOCATIONS: \(locations) \n\(locations[0].coordinate.latitude)")
        WebServicesController.getDailyForecast(lat: "\(locations[0].coordinate.latitude)", lon: "\(locations[0].coordinate.longitude)", handleComplete: { (error, data) in
            if let data = data {
                if let city = data["city"]["name"].string {
                    self.labelCity.text = city
                    self.labelCity.sizeToFit()
                    WebServicesController.getCityPicture(lat: "\(locations[0].coordinate.latitude)", lon: "\(locations[0].coordinate.longitude)", cityName: city.lowercased(), handleComplete: { (error, image) in
                        if let image = image {
                            self.imageBackground.image = image
                            self.imageBackground.alpha = 0.4
                        } else {
                            NSLog("ERROR DOWNLOADING CITY IMAGE \"\(error)\"")
                        }
                    })
                }
                if let country = data["city"]["country"].string {
                    self.labelCountry.text = country
                    self.labelCountry.sizeToFit()
                }
                if let forecast = data["list"].array {
                    self.drawForecastBarChart(forecastArray: forecast)
                }
            } else {
                NSLog("There was an error retrieving weather for current location \"\(error)\"")
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("didChangeAuthorization \"\(status)\"")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR LOCATION \"\(error.localizedDescription)\"")
    }
    
}
