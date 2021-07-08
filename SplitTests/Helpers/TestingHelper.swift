//
//  TestingHelper.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 19/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

struct TestingHelper {

    static func basicStreamingConfig() -> SplitClientConfig {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 3
        splitConfig.segmentsRefreshRate = 3
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.eventsPushRate = 3
        return splitConfig
    }

    static func createEvents(count: Int = 10, timestamp: Int64 = 1000) -> [EventDTO] {
        var events = [EventDTO]()
        for i in 0..<count {
            let event = EventDTO(trafficType: "name", eventType: "type")
            event.storageId = "event\(i)"
            event.key = "key1"
            event.eventTypeId = "type1"
            event.trafficTypeName = "name1"
            event.value = (i % 2 > 0 ? 1.0 : 0.0)
            event.timestamp = timestamp
            event.properties = ["f": i]
            events.append(event)
        }
        return events
    }

    static func createImpressions(feature: String = "split", count: Int = 10, time: Int64 = 100) -> [Impression] {
        var impressions = [Impression]()
        for i in 0..<count {
            let impression = Impression()
            impression.storageId = "\(feature)_impression\(i)"
            impression.feature = feature
            impression.keyName = "key1"
            impression.treatment = "t1"
            impression.time = time
            impression.changeNumber = 1000
            impression.label = "t1"
            impression.attributes = ["pepe": 1]
            impressions.append(impression)
        }
        return impressions
    }

    static func createKeyImpressions(feature: String = "split", count: Int = 10, time: Int64 = 100) -> [KeyImpression] {
        var impressions = [KeyImpression]()
        for i in 0..<count {
            let impression = KeyImpression(featureName: feature,
                                           keyName: "key1",
                                           bucketingKey: nil,
                                           treatment: "t1",
                                           label: "t1",
                                           time: time,
                                           changeNumber: 1000,
                                           previousTime: nil,
                                           storageId:  "\(feature)_impression\(i)")
            impressions.append(impression)
        }
        return impressions
    }

    static func createTestImpressions(count: Int = 10) -> [ImpressionsTest] {
        var impressions = [ImpressionsTest]()
        for _ in 0..<count {
            let impressionTest = try! Json.encodeFrom(json: "{\"f\":\"T1\", \"i\":[]}", to: ImpressionsTest.self)
            impressions.append(impressionTest)
        }
        return impressions
    }

    static func createImpressionsCount(count: Int = 10) -> [ImpressionsCountPerFeature] {

        var counts = [ImpressionsCountPerFeature]()
        for i in 0..<count {
            var count = ImpressionsCountPerFeature(feature: "feature\(i)", timeframe: Date().unixTimestampInMiliseconds(), count: 1)
            count.storageId = UUID().uuidString
            counts.append(count)
        }
        return counts
    }

    static func createSplit(name: String, trafficType: String = "t1", status: Status = .active) -> Split {
        let split = Split()
        split.name = name
        split.trafficTypeName = trafficType
        split.status = status
        return split
    }

    static func createTestDatabase(name: String) -> SplitDatabase {
        let queue = DispatchQueue(label: name, target: DispatchQueue.global())
        let helper = IntegrationCoreDataHelper.get(databaseName: "trackTestDb", dispatchQueue: queue)
        return CoreDataSplitDatabase(coreDataHelper: helper)
    }
}
