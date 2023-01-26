//
//  ImpressionsModeTypeTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 24-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class ImpressionsModeTypeWrapperTest: XCTestCase {

    func testEmptyInvalidValue() {
        @ImpressionsModeProperty var value: String = ""
        // Initial value is "", should be mapped as "optimized"
        XCTAssertEqual(ImpressionsMode.optimized.rawValue, value)
        XCTAssertEqual(ImpressionsMode.optimized, $value) // Projected value
    }

    func testInvalidValue() {
        @ImpressionsModeProperty var value: String = "invalid"

        XCTAssertEqual(ImpressionsMode.optimized.rawValue, value)
        XCTAssertEqual(ImpressionsMode.optimized, $value) // Projected value
    }

    func testInitoptimizedValue() {
        @ImpressionsModeProperty var value: String = "optimized"

        XCTAssertEqual(ImpressionsMode.optimized.rawValue, value)
        XCTAssertEqual(ImpressionsMode.optimized, $value) // Projected value
    }

    func testInitdebugValue() {
        @ImpressionsModeProperty var value: String = "debug"

        XCTAssertEqual(ImpressionsMode.debug.rawValue, value)
        XCTAssertEqual(ImpressionsMode.debug, $value) // Projected value
    }

    func testInitnoneValue() {
        @ImpressionsModeProperty var value: String = "none"

        XCTAssertEqual(ImpressionsMode.none.rawValue, value)
        XCTAssertEqual(ImpressionsMode.none, $value) // Projected value
    }

    func testoptimizedValue() {
        @ImpressionsModeProperty var value: String = ""
        value = "optimized"

        XCTAssertEqual(ImpressionsMode.optimized.rawValue, value)
        XCTAssertEqual(ImpressionsMode.optimized, $value) // Projected value
    }

    func testdebugValue() {
        @ImpressionsModeProperty var value: String = ""
        value = "debug"

        XCTAssertEqual(ImpressionsMode.debug.rawValue, value)
        XCTAssertEqual(ImpressionsMode.debug, $value) // Projected value
    }

    func testnoneValue() {
        @ImpressionsModeProperty var value: String = ""
        value = "none"

        XCTAssertEqual(ImpressionsMode.none.rawValue, value)
        XCTAssertEqual(ImpressionsMode.none, $value) // Projected value
    }

    override func tearDown() {
    }
}

