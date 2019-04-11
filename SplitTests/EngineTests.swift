//
//  EngineTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 29/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import XCTest
@testable import Split

class EngineTests: XCTestCase {

    var splitEngine: Engine!
    let matchingKey = "test_key"
    
    override func setUp() {
        splitEngine = Engine.shared
    }

    override func tearDown() {
    }

    func testAlgoNull() {
        var treatment: [String: String]? = nil
        let split: Split? = loadSplit(splitName: "split_sample_feature6")
        do {
            split?.algo = nil
            treatment = try splitEngine.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(treatment, "Treatment should not be nil when algo = nil")
        XCTAssertTrue(treatment?[Engine.EVALUATION_RESULT_TREATMENT] == "t4_6", "Expected treatment 'On', obtained '\(treatment?[Engine.EVALUATION_RESULT_TREATMENT] ?? "null")'")
    }
    
    func testAlgoLegacy() {
        var treatment: [String: String]? = nil
        let split: Split? = loadSplit(splitName: "split_sample_feature6")
        do {
        split?.algo = 1
        treatment = try splitEngine.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(treatment, "Treatment should not be nil when algo = 1 (Legacy)")
        XCTAssertTrue(treatment?[Engine.EVALUATION_RESULT_TREATMENT] == "t4_6", "Expected treatment 'On', obtained '\(treatment?[Engine.EVALUATION_RESULT_TREATMENT] ?? "null")'")
    }
    
    func testAlgoMurmur3() {
        var treatment: [String: String]? = nil
        let split: Split? = loadSplit(splitName: "split_sample_feature6")
        do {
            split?.algo = 2
            treatment = try splitEngine.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(treatment, "Treatment should not be nil when algo = 2 (Murmur3)")
        XCTAssertTrue(treatment?[Engine.EVALUATION_RESULT_TREATMENT] == "t4_6", "Expected treatment 'On', obtained '\(treatment?[Engine.EVALUATION_RESULT_TREATMENT] ?? "null")'")
    }
    
    func testsTrafficAllocation50DefaultRule50() {
        var treatmentOn: [String: String]? = nil
        var treatmentOff: [String: String]? = nil
        let split: Split? = loadSplit(splitName: "split_traffic_alloc_50_default_rule_50")
        
        do {
            treatmentOn = try splitEngine.getTreatment(matchingKey: "8771ab59-daf5-40de-a368-6bb06f2a876f", bucketingKey: nil, split: split, attributes: nil)
            treatmentOff = try splitEngine.getTreatment(matchingKey: "aa9055eb-710c-4817-93bc-6906db5f4934", bucketingKey: nil, split: split, attributes: nil)
        } catch {
        }
        XCTAssertEqual("on", treatmentOn![Engine.EVALUATION_RESULT_TREATMENT]!)
        XCTAssertEqual("default rule", treatmentOn![Engine.EVALUATION_RESULT_LABEL]!)
        
        XCTAssertEqual("off", treatmentOff![Engine.EVALUATION_RESULT_TREATMENT]!)
        XCTAssertEqual("default rule", treatmentOff![Engine.EVALUATION_RESULT_LABEL]!)

    }

    func loadSplit(splitName: String) -> Split? {
        if let splitContent = FileHelper.readDataFromFile(sourceClass: self, name: splitName, type: "json") {
            do {
                return try JSON(splitContent.data(using: .utf8)).decode(Split.self)
            } catch {
                print("Decoding split for algo null test failed")
            }
        } else {
            print("Error loading file \(splitName)")
        }
        return nil
    }
    
}
