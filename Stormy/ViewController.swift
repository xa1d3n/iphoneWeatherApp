//
//  ViewController.swift
//  Stormy
//
//  Created by Aldin Fajic on 12/8/14.
//  Copyright (c) 2014 Aldin Fajic. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var precipitationLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var refreshActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var celsiusButton: UIButton!
    @IBOutlet weak var farButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    private let apiKey = "497c87ac0bef2e49775503bce665366d"
    
    let locationManager = CLLocationManager()
    let defaultLat = "37.8267"
    let defaultLong = "-122.423"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // hide the activity indiator initially
        refreshActivityIndicator.hidden = true
        farButton.enabled = false
       
 
    }
    
    func getCurrentWeatherData(latitude : String, longitude : String) -> Void {

        // forecast api url
        let baseURL = NSURL(string: "https://api.forecast.io/forecast/\(apiKey)/")
        // relative url
        let forecastURL = NSURL(string: "\(latitude),\(longitude)", relativeToURL: baseURL)
        
        // start a session
        let sharedSession = NSURLSession.sharedSession()
        
        // pass in parameters
        let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(forecastURL!, completionHandler: { (location: NSURL!, response: NSURLResponse!, error: NSError!) -> Void in
            
            if (error == nil) {
                // get json
                let dataObject = NSData(contentsOfURL: location)
                
                // decode json and put into dictionary
                let weatherDictionary: NSDictionary = NSJSONSerialization.JSONObjectWithData(dataObject!, options: nil, error: nil) as NSDictionary
                
                let currentWeather = Current(weatherDictionary: weatherDictionary)
                
                // asynchronously update ui
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    
                    if self.celsiusButton.enabled == false {
                        self.convertToCelsius(String(currentWeather.temperature))
                       // self.temperatureLabel.text = temp
                    }
                    else {
                        self.temperatureLabel.text = "\(currentWeather.temperature)"
                    }
                    
                    
                    self.iconView.image = currentWeather.icon!
                    self.currentTimeLabel.text = "At \(currentWeather.currentTime!) it is"
                    self.humidityLabel.text = "\(Int(currentWeather.humidity * 100))%"
                    self.precipitationLabel.text = "\(Int(currentWeather.precipProbability * 100))%"
                    self.summaryLabel.text = "\(currentWeather.summary)"
                    
                    // stop animating the
                    self.refreshActivityIndicator.stopAnimating()
                    self.refreshActivityIndicator.hidden = true
                    self.refreshButton.hidden = false
                    
                })
            } else {
                // add an alert
                self.displayErrorAlert("Unable to load data. Connectivity error!")
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // stop animating the
                    self.refreshActivityIndicator.stopAnimating()
                    self.refreshActivityIndicator.hidden = true
                    self.refreshButton.hidden = false
                })
            }
        })
        // execute the task
        downloadTask.resume()
    }
    
    // hide the button when it's clciked.
    // show the activity indicator
    // start animating the indicator
    @IBAction func refresh() {
        var latVal = self.locationManager.location?.coordinate.latitude.description ?? self.defaultLat
        var longVal = self.locationManager.location?.coordinate.longitude.description ?? self.defaultLong
        
        getCurrentWeatherData(latVal, longitude: longVal)
        refreshButton.hidden = true
        refreshActivityIndicator.hidden = false
        refreshActivityIndicator.startAnimating()
    }
    
    // convert temp from farenheit to celsius
    @IBAction func convertTempToCel() {
        convertToCelsius(self.temperatureLabel.text!)
        self.celsiusButton.enabled = false
        self.farButton.enabled = true
        
        // change colors
        self.farButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        self.celsiusButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
    }
    
    
    // convert temp from celsius to farenheit
    @IBAction func convertTempToFar() {
        
        convertToFarenheit(self.temperatureLabel.text!)
        
        self.farButton.enabled = false
        self.celsiusButton.enabled = true
        // change colors
        self.farButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        self.celsiusButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
    }
    
    // convert temp from far to celsius
    func convertToCelsius(farVal: String) {
        var celVal = ((Double(farVal.toInt()!) - 32.0) * 5.0) / 9.0
        
        self.temperatureLabel.text = String(format: "%.0f", celVal)
    }
    
    func convertToFarenheit(celVal: String) {
        var farVal = (((Double(celVal.toInt()!) * 18.0) + 325.0)/10.0)
        
        self.temperatureLabel.text = String(format: "%.0f", farVal)
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        CLGeocoder().reverseGeocodeLocation(manager.location, completionHandler: { (placemarks, error) -> Void in
            if (error != nil) {
                self.displayErrorAlert("Unable to determine location")
                
                return
            }
            
            if placemarks.count > 0 {
                let pm = placemarks[0] as CLPlacemark
                
                
                self.displayLocationInfo(pm)
                
            }else {
                
                self.displayErrorAlert("No location available")
                
            }
        })
    }
    
    func displayLocationInfo(placemark: CLPlacemark) {
        self.locationManager.stopUpdatingLocation()
        var latVal = placemark.location.coordinate.latitude
        var longVal = placemark.location.coordinate.longitude
        
        self.getCurrentWeatherData(latVal.description, longitude: longVal.description)
        
        self.locationLabel.text = "\(placemark.locality), \(placemark.administrativeArea)"
        
        
    }
    
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        //println("Error: " + error.localizedDescription)
        displayErrorAlert("Please enable location services.")
    }
    
    func displayErrorAlert(message: String) {
        let networkIssueController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
        
        // add ok button
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        networkIssueController.addAction(okButton)
        
        // add cancel button
        let cancelButton = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        networkIssueController.addAction(cancelButton)
        
        // show alert
        self.presentViewController(networkIssueController, animated: true, completion: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

