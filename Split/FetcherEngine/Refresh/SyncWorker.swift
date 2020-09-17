//
//  SyncWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 15-Sep-2020
//
//

import Foundation

protocol SyncWorker {
    typealias SyncCompletion = (Bool) -> Void
    var completion: SyncCompletion? { get set }
    func start()
    func stop()
}

class RetryableSyncWorker: SyncWorker {

    var completion: SyncCompletion?
    private var reconnectBackoffCounter: ReconnectBackoffCounter
    private var splitEventsManager: SplitEventsManager?
    private var isFirstFetch = Atomic<Bool>(true)
    private var isRunning = Atomic<Bool>(false)
    private let loopQueue = DispatchQueue.global()

    init(eventsManager: SplitEventsManager? = nil,
         reconnectBackoffCounter: ReconnectBackoffCounter) {

        self.splitEventsManager = eventsManager
        self.reconnectBackoffCounter = reconnectBackoffCounter
    }

    func start() {
        isRunning.set(true)
        loopQueue.async {
            self.fetchFromRemoteLoop()
        }
    }

    func stop() {
        isRunning.set(false)
    }

    private func fetchFromRemoteLoop() {
        var success = false
        while isRunning.value, !success {
            success = fetchFromRemote()
            if !success {
                let retryTimeInSeconds = reconnectBackoffCounter.getNextRetryTime()
                Logger.d("Retrying fetch in: \(retryTimeInSeconds)")
                ThreadUtils.delay(seconds: retryTimeInSeconds)
            }
        }
        isRunning.set(false)
        if let handler = completion {
            handler(success)
        }
    }

    func fireReadyIsNeeded(event: SplitInternalEvent) {
        if isFirstFetch.getAndSet(false) {
            splitEventsManager?.notifyInternalEvent(event)
        }
    }

    func resetBackoffCounter() {
        reconnectBackoffCounter.resetCounter()
    }

    // This methods should be overrided by child class
    func fetchFromRemote() -> Bool {
        fatalError("fetch from remote not overriden")
    }
}

class RetryableMySegmentsSyncWorker: RetryableSyncWorker {

    private let mySegmentsChangeFetcher: MySegmentsChangeFetcher
    private let matchingKey: String
    private let mySegmentsCache: MySegmentsCacheProtocol

    init(matchingKey: String, mySegmentsChangeFetcher: MySegmentsChangeFetcher,
         mySegmentsCache: MySegmentsCacheProtocol,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter) {

        self.matchingKey = matchingKey
        self.mySegmentsCache = mySegmentsCache
        self.mySegmentsChangeFetcher = mySegmentsChangeFetcher
        super.init(eventsManager: eventsManager, reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() -> Bool {
        do {
            if let segments = try self.mySegmentsChangeFetcher.fetch(user: self.matchingKey, policy: .network) {
                Logger.d(segments.debugDescription)
                fireReadyIsNeeded(event: SplitInternalEvent.mySegmentsAreReady)
                resetBackoffCounter()
                return true
            }
        } catch let error {
            DefaultMetricsManager.shared.count(delta: 1, for: Metrics.Counter.mySegmentsFetcherException)
            Logger.e("Problem fetching mySegments: %@", error.localizedDescription)
        }
        return false
    }
}

class RetryableSplitsSyncWorker: RetryableSyncWorker {

    private let splitChangeFetcher: SplitChangeFetcher
    private let splitCache: SplitCacheProtocol
    private let cacheExpiration: Int

    init(splitChangeFetcher: SplitChangeFetcher,
         splitCache: SplitCacheProtocol,
         cacheExpiration: Int,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter) {

        self.splitChangeFetcher = splitChangeFetcher
        self.splitCache = splitCache
        self.cacheExpiration = cacheExpiration
        super.init(eventsManager: eventsManager, reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() -> Bool {
        do {
            var changeNumber = splitCache.getChangeNumber()
            if changeNumber != -1 {
                let timestamp = splitCache.getTimestamp()
                let elapsedTime = Int(Date().timeIntervalSince1970) - timestamp
                if timestamp > 0 && elapsedTime > self.cacheExpiration {
                    changeNumber = -1
                    self.splitCache.clear()
                }
            }
            if let splitChanges = try self.splitChangeFetcher.fetch(since: changeNumber) {
                fireReadyIsNeeded(event: SplitInternalEvent.splitsAreReady)
                resetBackoffCounter()
                Logger.d(splitChanges.debugDescription)
                return true
            }
        } catch let error {
            DefaultMetricsManager.shared.count(delta: 1, for: Metrics.Counter.splitChangeFetcherException)
            Logger.e("Problem fetching splits: %@", error.localizedDescription)
        }
        return false
    }
}

class RetryableSplitsUpdateWorker: RetryableSyncWorker {

    private let splitChangeFetcher: SplitChangeFetcher
    private let splitCache: SplitCacheProtocol
    private let changeNumber: Int64

    init(splitChangeFetcher: SplitChangeFetcher,
         splitCache: SplitCacheProtocol,
         changeNumber: Int64,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter) {

        self.splitChangeFetcher = splitChangeFetcher
        self.splitCache = splitCache
        self.changeNumber = changeNumber
        super.init(eventsManager: eventsManager, reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() -> Bool {
        do {
            if changeNumber < splitCache.getChangeNumber() {
                return true
            }
            if let splitChanges = try self.splitChangeFetcher.fetch(since: changeNumber) {
                resetBackoffCounter()
                Logger.d(splitChanges.debugDescription)
                return true
            }
        } catch let error {
            DefaultMetricsManager.shared.count(delta: 1, for: Metrics.Counter.splitChangeFetcherException)
            Logger.e("Problem updating splits: %@", error.localizedDescription)
        }
        return false
    }
}
