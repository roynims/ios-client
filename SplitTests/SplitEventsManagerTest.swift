//
//  SplitEventsManagerTest.swift
//  Split_Tests
//
//  Created by Sebastian Arrubia on 4/24/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class SplitEventsManagerTest: XCTestCase {
    
    let expectationTimeOut = 10.0
    let intervalExecutionTime = 1
    var queue = DispatchQueue(label: "test", attributes: .concurrent)
    
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testSdkReady() {
        var shouldStop = false
        let client = SplitClientStub()
        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.executorResources.client = client
        let updatedTask = TestTask(exp: nil)
        eventManager.register(event: .sdkUpdated, task: updatedTask)
        eventManager.start()
        
        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)
        ThreadUtils.delay(seconds: 0.2)
        
        let expectation = XCTestExpectation(description: "SDK Readky triggered")
        queue.async {
            while !shouldStop {
                sleep(UInt32(self.intervalExecutionTime))
                if eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady) {
                    shouldStop = true;
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: expectationTimeOut)
        
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkUpdated), "SDK Update shouldn't be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out shouldn't be triggered");
    }

    func testSdkReadyFromCacheAndReady() {

        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsLoadedFromCache)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsLoadedFromCache)

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)
        var shouldStop = false
        let expectation = XCTestExpectation(description: "SDK Readky from cache triggered")
        queue.async {
            while !shouldStop {
                sleep(UInt32(self.intervalExecutionTime))
                if eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady) {
                    shouldStop = true;
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyFromCache), "SDK Ready should from cache be triggered");
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out shouldn't be triggered");
    }

    func testSdkReadyFromCacheAndReadyTimeout() {

        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = 1000
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        let client = SplitClientStub()
        eventManager.executorResources.client = client
        eventManager.start()

        let cacheExp = XCTestExpectation()
        eventManager.register(event: .sdkReadyFromCache, task: TestTask(exp: cacheExp))
        let timeoutExp = XCTestExpectation()
        eventManager.register(event: .sdkReadyTimedOut, task: TestTask(exp: timeoutExp))

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsLoadedFromCache)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsLoadedFromCache)
        eventManager.notifyInternalEvent(SplitInternalEvent.sdkReadyTimeoutReached)

        wait(for: [cacheExp, timeoutExp], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyFromCache), "SDK Ready should from cache be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should not be triggered");
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out should be triggered");
    }
    
    func testSdkReadyTimeOut() {
        
        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = 1000
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        let client = SplitClientStub()
        eventManager.executorResources.client = client
        eventManager.start()

        let timeoutExp = XCTestExpectation()
        eventManager.register(event: .sdkReadyTimedOut, task: TestTask(exp: timeoutExp))
        wait(for: [timeoutExp], timeout: expectationTimeOut)
        
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out should be triggered")
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready shouldn't be triggered")
        
    }
    
    func testSdkReadyAndReadyTimeOut() {
        
        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = 1000
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        let client = SplitClientStub()
        eventManager.executorResources.client = client
        eventManager.start()

        let expectationTimeout = XCTestExpectation(description: "SDK Readky triggered")
        eventManager.register(event: .sdkReadyTimedOut, task: TestTask(exp: expectationTimeout))

        wait(for: [expectationTimeout], timeout: expectationTimeOut)
        
        //At this line timeout has been reached
        let timeoutTriggered  = eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut)

        let readyExp = XCTestExpectation(description: "SDK Readky triggered")
        eventManager.register(event: .sdkReady, task: TestTask(exp: readyExp))

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)

        wait(for: [readyExp], timeout: expectationTimeOut)
        
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should be triggered");
        XCTAssertTrue(timeoutTriggered)
    }

    func testSdkUpdateSplits() {
        let sdkUpdatedExp = XCTestExpectation()

        let client =  SplitClientStub()
        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.executorResources.client = client
        eventManager.start()

        let readyExp = XCTestExpectation()
        let updatedTask = sdkTask(exp: sdkUpdatedExp)
        eventManager.register(event: .sdkReady, task: TestTask(exp: readyExp))
        eventManager.register(event: .sdkUpdated, task: updatedTask)

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)

        wait(for: [readyExp, sdkUpdatedExp], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should be triggered");
        XCTAssertTrue(updatedTask.taskTriggered, "SDK Update should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out shouldn't be triggered");
    }

    func testSdkUpdateMySegments() {
        let sdkUpdatedExp = XCTestExpectation()

        let client =  SplitClientStub()
        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.executorResources.client = client
        eventManager.start()
        let readyExp = XCTestExpectation()
        let updatedTask = sdkTask(exp: sdkUpdatedExp)
        eventManager.register(event: .sdkReady, task: TestTask(exp: readyExp))
        eventManager.register(event: .sdkUpdated, task: updatedTask)


        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)

        wait(for: [readyExp, sdkUpdatedExp], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should be triggered");
        XCTAssertTrue(updatedTask.taskTriggered, "SDK Update should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out shouldn't be triggered");
    }

    func testSplitKilledWhenReady() {
        let sdkUpdatedExp = XCTestExpectation()

        let client =  SplitClientStub()
        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.executorResources.client = client
        eventManager.start()
        let readyExp = XCTestExpectation()
        let updatedTask = sdkTask(exp: sdkUpdatedExp)
        eventManager.register(event: .sdkReady, task: TestTask(exp: readyExp))
        eventManager.register(event: .sdkUpdated, task: updatedTask)

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitKilledNotification)

        wait(for: [readyExp, sdkUpdatedExp], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should be triggered");
        XCTAssertTrue(updatedTask.taskTriggered, "SDK Update should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out shouldn't be triggered");
    }

    func testSplitKilledNoSdkReady() {
        let sdkTiemoutExp = XCTestExpectation()
        let timeout = 3.0
        let client =  SplitClientStub()
        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = Int(timeout) - 1
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.executorResources.client = client
        let timeOutTask = sdkTask(exp: sdkTiemoutExp)
        let updatedTask = sdkTask(exp: sdkTiemoutExp)
        eventManager.register(event: .sdkUpdated, task: updatedTask)
        eventManager.register(event: .sdkReadyTimedOut, task: timeOutTask)
        eventManager.start()

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitKilledNotification)

        wait(for: [sdkTiemoutExp], timeout: timeout)

        XCTAssertFalse(updatedTask.taskTriggered);
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady));
        XCTAssertTrue(timeOutTask.taskTriggered);
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut));
    }
    
    // MARK: Helpers
    func currentTimestamp() -> Int {
        return Int(Date().unixTimestamp())
    }

    func sdkTask(exp: XCTestExpectation) -> TestTask {
        return TestTask(exp: exp)
    }
}

class TestTask: SplitEventTask {
    var taskTriggered = false
    var exp: XCTestExpectation?
    init(exp: XCTestExpectation?) {
        self.exp = exp
    }
    override func onPostExecute(client: SplitClient) {
    }

    override func onPostExecuteView(client: SplitClient) {
        taskTriggered = true
        if let exp = self.exp {
            exp.fulfill()
        }
    }
}
