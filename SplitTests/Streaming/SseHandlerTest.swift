//
//  SseHandlerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 01/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SseHandlerTest: XCTestCase {

    var notificationProcessor: SseNotificationProcessorStub!
    var notificationParser: SseNotificationParserStub!
    var notificationManagerKeeper: NotificationManagerKeeperStub!
    var broadcasterChannel: PushManagerEventBroadcasterStub!

    var sseHandler: SseHandler!

    override func setUp() {
        notificationParser = SseNotificationParserStub()
        notificationProcessor = SseNotificationProcessorStub()
        notificationManagerKeeper = NotificationManagerKeeperStub()
        broadcasterChannel = PushManagerEventBroadcasterStub()
        sseHandler = DefaultSseHandler(notificationProcessor: notificationProcessor,
                                       notificationParser: notificationParser,
                                       notificationManagerKeeper: notificationManagerKeeper,
                                       broadcasterChannel: broadcasterChannel
        )
    }

    func testIncomingSplitUpdate() {
        notificationParser.incomingNotification = IncomingNotification(type: .splitUpdate, jsonData: "dummy")
        notificationParser.splitsUpdateNotification = SplitsUpdateNotification(changeNumber: -1)
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertTrue(notificationProcessor.processCalled)
    }

    func testIncomingSplitKill() {
        notificationParser.incomingNotification = IncomingNotification(type: .splitKill, jsonData: "dummy")
        notificationParser.splitKillNotification = SplitKillNotification(changeNumber: -1, splitName: "split1", defaultTreatment: "off")
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertTrue(notificationProcessor.processCalled)
    }

    func testIncomingMySegmentsUpdate() {
        notificationParser.incomingNotification = IncomingNotification(type: .mySegmentsUpdate, jsonData: "dummy")
        notificationParser.mySegmentsUpdateNotification = MySegmentsUpdateNotification(changeNumber: -1, includesPayload: true, segmentList: [])
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertTrue(notificationProcessor.processCalled)
    }

    func testIncomingOccupancy() {
        notificationParser.incomingNotification = IncomingNotification(type: .occupancy, jsonData: "dummy")
        notificationParser.occupancyNotification = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 1))
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertTrue(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertFalse(notificationProcessor.processCalled)
    }

    func testIncomingControlStreaming() {
        notificationParser.incomingNotification = IncomingNotification(type: .control, jsonData: "dummy", timestamp: 100)
        notificationParser.controlNotification = ControlNotification(type: .control, controlType: .streamingEnabled)
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertTrue(notificationManagerKeeper.handleIncomingControlCalled)
    }

    func testIncomingLowRetryableSseError() {
        incomingRetryableSseErrorTest(code: 40140)
    }

    func testIncomingHightRetryableSseError() {
        incomingRetryableSseErrorTest(code: 40149)
    }

    func incomingRetryableSseErrorTest(code: Int) {
        notificationParser.incomingNotification = IncomingNotification(type: .sseError, jsonData: "dummy")
        notificationParser.sseErrorNotification = StreamingError(message: "", code: code, statusCode: code)
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertFalse(notificationProcessor.processCalled)
        XCTAssertEqual(PushStatusEvent.pushRetryableError, broadcasterChannel.lastPushedEvent)
    }

    func testIncomingLowNonRetryableSseError() {
        incomingNonRetryableSseErrorTest(code: 40000)
    }

    func testIncomingHightNonRetryableSseError() {
        incomingNonRetryableSseErrorTest(code: 49999)
    }

    func incomingNonRetryableSseErrorTest(code: Int) {
        notificationParser.incomingNotification = IncomingNotification(type: .sseError, jsonData: "dummy")
        notificationParser.sseErrorNotification = StreamingError(message: "", code: code, statusCode: code)
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertFalse(notificationProcessor.processCalled)
        XCTAssertEqual(PushStatusEvent.pushNonRetryableError, broadcasterChannel.lastPushedEvent)
    }

    func testIncomingIgnorableSseErrorTest() {
        notificationParser.incomingNotification = IncomingNotification(type: .sseError, jsonData: "dummy")
        notificationParser.sseErrorNotification = StreamingError(message: "", code: 50000, statusCode: 50000)
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertFalse(notificationProcessor.processCalled)
        XCTAssertNil(broadcasterChannel.lastPushedEvent)
    }

    override func tearDown() {
    }
}
