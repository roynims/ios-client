//
//  TrackTestViewController.swift
//  Split_Example
//
//  Created by Javier L. Avrudsky on 6/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Split

class TrackViewController: UIViewController {
    
    @IBOutlet weak var eventTypeField: UITextField!
    @IBOutlet weak var trafficTypeField: UITextField!
    @IBOutlet weak var valueField: UITextField!
    @IBOutlet weak var sendEventButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    
    var factory: SplitFactory?
    var client: SplitClientProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.view.addGestureRecognizer(tap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func handleTap(){
        self.view.endEditing(true)
    }
    
    @IBAction func sendEventDidTouch(_ sender: UIButton) {
        if client == nil {
            initClient()
        }
        sendEvent()
    }
    func initClient(){
        // Your Split API-KEY - Change in Config.swift file
        let authorizationKey: String = "YOUR_API_KEY"
        
        //This Key should identify user or installation
        let matchingKeyText: String = "SAMPLE_ID_1"
        
        //Split Configuration
        let config = SplitClientConfig()
        config.featuresRefreshRate(30)
        config.segmentsRefreshRate(30)
        config.impressionRefreshRate(30)
        config.readyTimeOut(15000)
        
        // Track config
        config.eventsPushRate(10)
        config.eventsPerPush(2000)
        config.eventsQueueSize(10000)
        config.eventsFirstPushWindow(10)
        config.trafficType("custom")
        
        config.sdkEndpoint("https://sdk-aws-staging.split.io/api")
        config.eventsEndpoint("https://events-aws-staging.split.io/api")

        
        //User Key
        let key: Key = Key(matchingKey: matchingKeyText, bucketingKey: nil)
        
        //Split Factory
        self.factory = SplitFactory(apiKey: authorizationKey, key: key, config: config)
        
        //Split Client
        self.client = self.factory?.client()
    }
    
    private func sendEvent(){
                
        if isEmpty(eventTypeField) {
            resultLabel.text = "Event Type should not be empty"
        } else if !isEmpty(valueField) && Double(valueField.text ?? "") == nil {
            resultLabel.text = "Value field is not valid"
        } else if isEmpty(trafficTypeField) && isEmpty(valueField) {
            showResult(client?.track(eventType: trafficTypeField.text!) ?? false)
        } else if isEmpty(trafficTypeField) {
            showResult(client?.track(eventType: eventTypeField.text!, value: Double(valueField.text!)!) ?? false)
        } else if isEmpty(valueField) {
            showResult(client?.track(trafficType: trafficTypeField.text!, eventType: eventTypeField.text!) ?? false)
        } else {
            showResult(client?.track(trafficType: trafficTypeField.text!, eventType: eventTypeField.text!, value: Double(valueField.text!)!) ?? false)
        }
    }
    
    private func isEmpty(_ textField: UITextField) -> Bool {
        return textField.text == nil || textField.text?.trimmingCharacters(in: .whitespaces) == ""
    }
    
    private func showResult(_ result: Bool){
        resultLabel.text = (result ? "Success" : "Failure")
    }
}
