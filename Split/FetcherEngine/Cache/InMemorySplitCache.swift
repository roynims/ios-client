//
//  InMemorySplitCache.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

class InMemorySplitCache: NSObject, SplitCacheProtocol {

    private let queueName = "split.inmemcache-queue.splits"
    private var queue: DispatchQueue
    private var splits: [String: Split]
    private var changeNumber: Int64
    private var queryString: String = ""
    private var trafficTypes = [String: Int]()
    private var timestamp: Int = 0

    init(splits: [String: Split] = [:], changeNumber: Int64 = -1, timestamp: Int? = 0, queryString: String = "") {
        self.queue = DispatchQueue(label: queueName, attributes: .concurrent)
        self.splits = [:]
        self.changeNumber = changeNumber
        self.timestamp = timestamp ?? 0
        self.queryString = queryString
        super.init()
        initSplits(splits: splits)
    }

    func addSplit(splitName: String, split: Split) {
        queue.async(flags: .barrier) {
            self.updateTrafficTypes(with: split)
            self.splits[splitName] = split
        }
    }

    func setChangeNumber(_ changeNumber: Int64) {
        queue.async(flags: .barrier) {
            self.changeNumber = changeNumber
        }
    }

    func getChangeNumber() -> Int64 {
        var number: Int64 = -1
        queue.sync {
            number = self.changeNumber
        }
        return number
    }

    func getSplit(splitName: String) -> Split? {
        var split: Split?
        queue.sync {
            split = self.splits[splitName]
        }
        return split
    }

    func getSplits() -> [String: Split] {
        var splits: [String: Split]!
        queue.sync {
            splits = self.splits
        }
        return splits
    }

    func getAllSplits() -> [Split] {
        var splits = [Split]()
        queue.sync {
            splits = Array(self.splits.values)
        }
        return splits
    }

    func clear() {
        queue.async(flags: .barrier) {
            self.splits.removeAll()
        }
    }

    func exists(trafficType: String) -> Bool {
        var exists = false
        queue.sync {
            exists = (self.trafficTypes[trafficType] != nil)
        }
        return exists
    }

    func getTimestamp() -> Int {
        return timestamp
    }

    func setTimestamp(_ timestamp: Int) {
        self.timestamp = timestamp
    }

    func kill(splitName: String, defaultTreatment: String, changeNumber: Int64) {
        if let split = splits[splitName], split.changeNumber ?? -1 < changeNumber {
            split.killed = true
            split.changeNumber = changeNumber
            split.defaultTreatment = defaultTreatment
            splits[splitName] = split
        }
    }
}

extension InMemorySplitCache {
    private func initSplits(splits: [String: Split]) {
        for (splitName, split) in splits {
            addSplit(splitName: splitName, split: split)
        }
    }
    private func updateTrafficTypes(with split: Split) {
        if let trafficTypeName = split.trafficTypeName,
            let status = split.status,
            let splitName = split.name {
            if status == .active {
                if let loadedSplit = splits[splitName], let loadedTrafficType = loadedSplit.trafficTypeName {
                    self.removeTrafficType(name: loadedTrafficType)
                }
                self.addTrafficType(name: trafficTypeName)
            } else {
                self.removeTrafficType(name: trafficTypeName)
            }
        }
    }

    private func addTrafficType(name: String) {
        let trafficType = name
        let newCount = (trafficTypes[trafficType] ?? 0) + 1
        trafficTypes[trafficType] = newCount
    }

    private func removeTrafficType(name: String) {
        let trafficType = name
        let newCount = (trafficTypes[trafficType] ?? 0) - 1
        if newCount > 0 {
            trafficTypes[trafficType] = newCount
        } else {
            trafficTypes.removeValue(forKey: trafficType)
        }
    }

    func setQueryString(_ queryString: String) {
        self.queryString = queryString
    }

    func getQueryString() -> String {
        return queryString
    }

    func deleteSplit(name: String) {
        splits.removeValue(forKey: name)
    }
}
