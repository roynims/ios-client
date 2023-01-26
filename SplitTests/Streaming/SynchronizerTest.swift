//
//  SynchronizerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10-03-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SynchronizerTest: XCTestCase {

    var splitsFetcher: HttpSplitFetcherStub!
    var splitsSyncWorker: RetryableSyncWorkerStub!
    var mySegmentsSyncWorker: RetryableSyncWorkerStub!
    var periodicSplitsSyncWorker: PeriodicSyncWorkerStub!
    var persistentSplitsStorage: PersistentSplitsStorageStub!

    var splitsStorage: SplitsStorageStub!
    var mySegmentsStorage: ByKeyMySegmentsStorageStub!

    var updateWorkerCatalog = ConcurrentDictionary<Int64, RetryableSyncWorker>()
    var syncWorkerFactory: SyncWorkerFactoryStub!

    var synchronizer: Synchronizer!

    var eventsManager: SplitEventsManagerStub!
    var telemetryProducer: TelemetryStorageStub!
    var byKeyApiFacade: ByKeyFacadeStub!
    var impressionsTracker: ImpressionsTrackerStub!
    var eventsSynchronizer: EventsSynchronizerStub!
    var telemetrySynchronizer: TelemetrySynchronizerStub!

    let userKey = "CUSTOMER_KEY"

    var splitConfig: SplitClientConfig!

    override func setUp() {
        synchronizer = buildSynchronizer()
    }

    func buildSynchronizer(impressionsAccumulator: RecorderFlushChecker? = nil,
                           eventsAccumulator: RecorderFlushChecker? = nil,
                           syncEnabled: Bool = true) -> Synchronizer {

        eventsManager = SplitEventsManagerStub()
        persistentSplitsStorage = PersistentSplitsStorageStub()
        splitsFetcher = HttpSplitFetcherStub()

        splitsSyncWorker = RetryableSyncWorkerStub()
        mySegmentsSyncWorker = RetryableSyncWorkerStub()
        periodicSplitsSyncWorker = PeriodicSyncWorkerStub()
        syncWorkerFactory = SyncWorkerFactoryStub()

        impressionsTracker = ImpressionsTrackerStub()
        eventsSynchronizer = EventsSynchronizerStub()

        syncWorkerFactory.splitsSyncWorker = splitsSyncWorker
        syncWorkerFactory.mySegmentsSyncWorker = mySegmentsSyncWorker
        syncWorkerFactory.periodicSplitsSyncWorker = periodicSplitsSyncWorker

        mySegmentsStorage = ByKeyMySegmentsStorageStub()
        telemetryProducer = TelemetryStorageStub()
        splitsStorage = SplitsStorageStub()
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [], archivedSplits: [],
                                                               changeNumber: 100, updateTimestamp: 100))

        let storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                     fileStorage: FileStorageStub(), splitsStorage: splitsStorage,
                                                     persistentSplitsStorage: persistentSplitsStorage,
                                                     impressionsStorage: ImpressionsStorageStub(),
                                                     persistentImpressionsStorage: PersistentImpressionsStorageStub(),
                                                     impressionsCountStorage: PersistentImpressionsCountStorageStub(),
                                                     eventsStorage: EventsStorageStub(),
                                                     persistentEventsStorage: PersistentEventsStorageStub(),
                                                     telemetryStorage: telemetryProducer,
                                                     mySegmentsStorage: MySegmentsStorageStub(),
                                                     attributesStorage: AttributesStorageStub(),
                                                     uniqueKeyStorage: PersistentUniqueKeyStorageStub())

        let apiFacade = try! SplitApiFacade.builder()
            .setUserKey("userKey")
            .setRestClient(RestClientStub())
            .setSplitConfig(SplitClientConfig())
            .setEventsManager(SplitEventsManagerStub())
            .setStreamingHttpClient(HttpClientMock(session: HttpSessionMock()))
            .build()

        splitConfig =  SplitClientConfig()
        splitConfig.syncEnabled = syncEnabled
        splitConfig.sync = SyncConfig.builder().addSplitFilter(SplitFilter.byName(["SPLIT1"])).build()

        byKeyApiFacade = ByKeyFacadeStub()

        telemetrySynchronizer = TelemetrySynchronizerStub()

        synchronizer = DefaultSynchronizer(splitConfig: splitConfig,
                                           defaultUserKey: userKey,
                                           telemetrySynchronizer: telemetrySynchronizer,
                                           byKeyFacade: byKeyApiFacade,
                                           splitApiFacade: apiFacade,
                                           splitStorageContainer: storageContainer,
                                           syncWorkerFactory: syncWorkerFactory,
                                           impressionsTracker: impressionsTracker,
                                           eventsSynchronizer: eventsSynchronizer,
                                           syncTaskByChangeNumberCatalog: updateWorkerCatalog,
                                           splitsFilterQueryString: "",
                                           splitEventsManager: eventsManager)
        return synchronizer
    }

    func testSyncAll() {

        synchronizer.syncAll()

        XCTAssertTrue(splitsSyncWorker.startCalled)
        XCTAssertTrue(byKeyApiFacade.syncAllCalled)
    }

    func testSynchronizeSplits() {

        synchronizer.synchronizeSplits()

        XCTAssertTrue(splitsSyncWorker.startCalled)
    }

    func testLoadAndSyncSplitsClearedOnLoadBecauseNotInFilter() {
        // Existent splits does not belong to split filter on config so they gonna be deleted because filter has changed
        persistentSplitsStorage.update(split: TestingHelper.createSplit(name: "pepe"))
        persistentSplitsStorage.update(filterQueryString: "?p=1")
        persistentSplitsStorage.update(split: TestingHelper.createSplit(name: "SPLIT_TO_DELETE"))
        synchronizer.loadAndSynchronizeSplits()

        ThreadUtils.delay(seconds: 0.5)

        XCTAssertTrue(persistentSplitsStorage.getAllCalled)
        XCTAssertTrue(persistentSplitsStorage.deleteCalled)
        XCTAssertTrue(splitsStorage.loadLocalCalled)
        XCTAssertEqual(0, eventsManager.splitsLoadedEventFiredCount)
    }

    func testLoadAndSyncSplitsNoClearedOnLoad() {
        // Splits filter doesn't vary so splits don't gonna be removed
        // loaded splits > 0, ready from cache should be fired
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [TestingHelper.createSplit(name: "new_pepe")],
                                                  archivedSplits: [], changeNumber: 100, updateTimestamp: 100))
        persistentSplitsStorage.update(filterQueryString: "")
        synchronizer.loadAndSynchronizeSplits()

        ThreadUtils.delay(seconds: 0.5)

        XCTAssertTrue(splitsStorage.loadLocalCalled)
        XCTAssertEqual(1, eventsManager.splitsLoadedEventFiredCount)
    }

    func testLoadMySegmentsFromCache() {

        synchronizer.loadMySegmentsFromCache(forKey: userKey)

        ThreadUtils.delay(seconds: 0.2)

        XCTAssertTrue(byKeyApiFacade.loadMySegmentsFromCacheCalled[userKey] ?? false)
    }

    func testSynchronizeMySegments() {

        synchronizer.synchronizeMySegments(forKey: userKey)

        XCTAssertTrue(byKeyApiFacade.syncMySegmentsCalled[userKey] ?? false)
    }

    func testForceSynchronizeMySegments() {

        synchronizer.forceMySegmentsSync(forKey: userKey)

        XCTAssertTrue(byKeyApiFacade.forceMySegmentsSyncCalled[userKey] ?? false)
    }

    func testSynchronizeSplitsWithChangeNumber() {

        let sw1 = RetryableSyncWorkerStub()
        let sw2 = RetryableSyncWorkerStub()

        syncWorkerFactory.retryableSplitsUpdateWorkers = [sw1, sw2]
        synchronizer.synchronizeSplits(changeNumber: 101)
        synchronizer.synchronizeSplits(changeNumber: 102)

        let initialSyncCount = updateWorkerCatalog.count
        sw1.completion?(true)
        let oneCompletedSyncCount = updateWorkerCatalog.count
        sw2.completion?(true)

        XCTAssertEqual(2, initialSyncCount)
        XCTAssertEqual(1, oneCompletedSyncCount)
        XCTAssertEqual(0, updateWorkerCatalog.count)

        XCTAssertFalse(sw1.stopCalled)
        XCTAssertFalse(sw2.stopCalled)
    }

    func testStartPeriodicFetching() {

        synchronizer.startPeriodicFetching()

        XCTAssertTrue(periodicSplitsSyncWorker.startCalled)
        XCTAssertTrue(byKeyApiFacade.startPeriodicSyncCalled)
    }

    func testStartPeriodicFetchingSingleModeEnabled() {

        synchronizer = buildSynchronizer(syncEnabled: false)
        synchronizer.startPeriodicFetching()

        XCTAssertFalse(periodicSplitsSyncWorker.startCalled)
        XCTAssertFalse(byKeyApiFacade.startPeriodicSyncCalled)
    }

    func testUpdateSplitsSingleModeEnabled() {

        synchronizer = buildSynchronizer(syncEnabled: false)
        synchronizer.synchronizeSplits(changeNumber: -1)

        XCTAssertFalse(splitsSyncWorker.startCalled)
    }

    func testForceMySegmentsSyncSingleModeEnabled() {
        let syncKey = IntegrationHelper.dummyUserKey
        synchronizer = buildSynchronizer(syncEnabled: false)
        synchronizer.forceMySegmentsSync(forKey: syncKey)

        XCTAssertFalse(byKeyApiFacade.forceMySegmentsSyncCalled[syncKey] ?? false)
    }

    func testStopPeriodicFetching() {

        synchronizer.stopPeriodicFetching()

        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
        XCTAssertTrue(byKeyApiFacade.stopPeriodicSyncCalled)
    }

    func testStartPeriodicRecordingUserData() {
        impressionsTracker.startCalled = false
        eventsSynchronizer.startCalled = false
        synchronizer.startRecordingUserData()

        XCTAssertTrue(impressionsTracker.startCalled)
        XCTAssertTrue(eventsSynchronizer.startCalled)
    }

    func testStopRecordingUserData() {
        impressionsTracker.startCalled = false
        eventsSynchronizer.startCalled = false

        synchronizer.stopRecordingUserData()

        XCTAssertTrue(impressionsTracker.stopCalled)
        XCTAssertTrue(eventsSynchronizer.stopCalled)
    }

    func testStartRecordingTelemetry() {
        telemetrySynchronizer.startCalled = false
        synchronizer.startRecordingTelemetry()

        XCTAssertTrue(telemetrySynchronizer.startCalled)
    }

    func testStopRecordingTelemetry() {
        telemetrySynchronizer.destroyCalled = true
        synchronizer.stopRecordingTelemetry()

        XCTAssertTrue(telemetrySynchronizer.destroyCalled)
    }

    func testStartByKey() {
        let key = Key(matchingKey: userKey)
        synchronizer.start(forKey: key)

        XCTAssertTrue(byKeyApiFacade.startSyncForKeyCalled[key] ?? false)
    }

    func testFlush() {

        synchronizer.flush()
        sleep(1)
        XCTAssertTrue(impressionsTracker.flushCalled)
        XCTAssertTrue(eventsSynchronizer.flushCalled)
    }

    func testDestroy() {

        let sw1 = RetryableSyncWorkerStub()
        let sw2 = RetryableSyncWorkerStub()

        syncWorkerFactory.retryableSplitsUpdateWorkers = [sw1, sw2]
        synchronizer.synchronizeSplits(changeNumber: 101)
        synchronizer.synchronizeSplits(changeNumber: 102)

        synchronizer.destroy()

        XCTAssertTrue(splitsSyncWorker.stopCalled)
        XCTAssertTrue(byKeyApiFacade.destroyCalled)
        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
        XCTAssertTrue(byKeyApiFacade.destroyCalled)
        XCTAssertTrue(sw1.stopCalled)
        XCTAssertTrue(sw2.stopCalled)
        XCTAssertEqual(0, updateWorkerCatalog.count)
    }

    func testEventPush() {


        for i in 0..<5 {
            synchronizer.pushEvent(event: EventDTO(trafficType: "t1", eventType: "e\(i)"))
        }


        ThreadUtils.delay(seconds: 1)
        XCTAssertTrue(eventsSynchronizer.pushCalled)

    }

    override func tearDown() {
    }
}
