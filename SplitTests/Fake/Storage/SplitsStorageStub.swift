//
//  SplitsStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 03/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SplitsStorageStub: SplitsStorage {
    
    var updatedSplitChange: ProcessedSplitChange? = nil
    
    var changeNumber: Int64 = 0
    
    var updateTimestamp: Int64 = 0
    
    var splitsFilterQueryString: String = ""
    
    var clearCalled = false

    var updatedWithoutChecksSplit: Split?
    var updatedWithoutChecksExp: XCTestExpectation?

    private let inMemorySplits = SyncDictionarySingleWrapper<String, Split>()
    
    func loadLocal() {
        
    }
    
    func get(name: String) -> Split? {
        return inMemorySplits.value(forKey: name.lowercased())
    }
    
    func getMany(splits: [String]) -> [String : Split] {
        let names = Set(splits.compactMap { $0.lowercased() })
        return inMemorySplits.all.filter { return names.contains($0.key) }
    }
    
    func getAll() -> [String : Split] {
        return inMemorySplits.all
    }
    
    func update(splitChange: ProcessedSplitChange) {
        updatedSplitChange = splitChange
        let active = splitChange.activeSplits
        let archived = splitChange.archivedSplits
        changeNumber = splitChange.changeNumber
        updateTimestamp = splitChange.updateTimestamp
        active.forEach {
            inMemorySplits.setValue($0, forKey: $0.name?.lowercased() ?? "")
        }
        archived.forEach {
            inMemorySplits.removeValue(forKey: $0.name?.lowercased() ?? "")
        }
    }
    
    func update(filterQueryString: String) {
        self.splitsFilterQueryString = filterQueryString
    }
    
    func updateWithoutChecks(split: Split) {
        inMemorySplits.setValue(split, forKey: split.name ?? "")
        updatedWithoutChecksSplit = split
        if let exp = updatedWithoutChecksExp {
            exp.fulfill()
        }
    }
    
    func isValidTrafficType(name: String) -> Bool {
        let splits = inMemorySplits.all.compactMap { return $0.value }
        let count =  splits.filter { return $0.trafficTypeName == name && $0.status == .active }.count
        return count > 0
    }
    
    func clear() {
        clearCalled = true
        inMemorySplits.removeAll()
    }
}
