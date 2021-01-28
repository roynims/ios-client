//
//  ImpressionsRecorderWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class ImpressionsRecorderWorker: RecorderWorker {

    private let impressionsStorage: PersistentImpressionsStorage
    private let impressionsRecorder: HttpImpressionsRecorder
    private let impressionsPerPush: Int
    private let impressionsSyncHelper: ImpressionsRecorderSyncHelper?

    init(impressionsStorage: PersistentImpressionsStorage,
         impressionsRecorder: HttpImpressionsRecorder,
         impressionsPerPush: Int,
         impressionsSyncHelper: ImpressionsRecorderSyncHelper? = nil) {

        self.impressionsStorage = impressionsStorage
        self.impressionsRecorder = impressionsRecorder
        self.impressionsPerPush = impressionsPerPush
        self.impressionsSyncHelper = impressionsSyncHelper

    }

    func flush() {
        var rowCount = 0
        var failedImpressions = [Impression]()
        repeat {
            let impressions = impressionsStorage.pop(count: impressionsPerPush)
            if impressions.count == 0 {
                return
            }
            rowCount = impressions.count
            Logger.d("Sending impressions")

            do {
                _ = try impressionsRecorder.execute(group(impressions: impressions))
                // Removing sent impressions
                impressionsStorage.delete(impressions)
                Logger.d("Impression posted successfully")
            } catch let error {
                Logger.e("Impression error: \(String(describing: error))")
                failedImpressions.append(contentsOf: impressions)
            }
        } while rowCount == impressionsPerPush
        // Activate non sent impressions to retry in next iteration
        impressionsStorage.setActive(failedImpressions)
        if let syncHelper = impressionsSyncHelper {
            syncHelper.updateAccumulator(count: failedImpressions.count,
                                         bytes: failedImpressions.count *
                                            ServiceConstants.estimatedImpressionSizeInBytes)
        }

    }

    private func group(impressions: [Impression]) -> [ImpressionsTest] {
        return Dictionary(grouping: impressions, by: { $0.feature ?? "" })
            .compactMap { return ImpressionsTest(testName: $0.key, keyImpressions: $0.value) }
    }
}
