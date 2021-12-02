//
//  TelemetryStats.swift
//  Split
//
//  Created by Javier Avrudsky on 01-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

struct TelemetryHttpLatencies {

    var splits: [Int64]
    var mySegments: [Int64]
    var impressions: [Int64]
    var impressionsCount: [Int64]
    var events: [Int64]
    var token: [Int64]
    var telemetry: [Int64]

    enum CodingKeys: String, CodingKey {
        case splits = "sp"
        case mySegments = "ms"
        case impressions = "im"
        case impressionsCount = "ic"
        case events = "ev"
        case token = "to"
        case telemetry = "te"
    }
}

struct TelemetryStreamingEvent {

    enum EventType: Int {
        case connectionStablished = 0
        case occupancyPri = 10
        case occupancySec = 20
        case streamingStatus = 30
        case connectionError = 40
        case tokenRefresh = 50
        case ablyError = 60
        case syncModeUpdate = 70
    }

    var type: Int
    var data: Int64
    var timestamp: Int64

    enum CodingKeys: String, CodingKey {
        case type = "e"
        case data = "d"
        case timestamp = "t"
    }
}

struct TelemetryHttpErrors {

    var splits: [Int: Int64]
    var mySegments: [Int: Int64]
    var impressions: [Int: Int64]
    var impressionsCount: [Int: Int64]
    var events: [Int: Int64]
    var token: [Int: Int64]
    var telemetry: [Int: Int64]

    enum CodingKeys: String, CodingKey {
        case splits = "sp"
        case mySegments = "ms"
        case impressions = "im"
        case impressionsCount = "ic"
        case events = "ev"
        case token = "to"
        case telemetry = "te"
    }
}

struct TelemetryMethodExceptions: Encodable {
    var treatment: Int64
    var treatments: Int64
    var treatmentWithConfig: Int64
    var treatmentsWithConfig: Int64
    var track: Int64

    enum CodingKeys: String, CodingKey {
        case treatment = "t"
        case treatments = "ts"
        case treatmentWithConfig = "tc"
        case treatmentsWithConfig = "tcs"
        case track = "tr"
    }
}

struct TelemetryLastSynchronization {

    var splits: Int64
    var impressions: Int64
    var impressionsCount: Int64
    var events: Int64
    var token: Int64
    var telemetry: Int64
    var mySegments: Int64

    enum CodingKeys: String, CodingKey {
        case splits = "sp"
        case impressions = "im"
        case impressionsCount = "ic"
        case events = "ev"
        case token = "to"
        case telemetry = "te"
        case mySegments = "ms"
    }
}

struct TelemetryMethodLatencies {

    var treatment: [Int64]
    var treatments: [Int64]
    var treatmentWithConfig: [Int64]
    var treatmentsWithConfig: [Int64]
    var track: [Int64]

    enum CodingKeys: String, CodingKey {
        case treatment = "t"
        case treatments = "ts"
        case treatmentWithConfig = "tc"
        case treatmentsWithConfig = "tcs"
        case track = "tr"
    }
}

struct TelemetryStats {

    var lastSynchronization: TelemetryLastSynchronization
    var methodLatencies: TelemetryMethodLatencies
    var methodExceptions: TelemetryMethodExceptions
    var httpErrors: TelemetryHttpErrors
    var httpLatencies: TelemetryHttpLatencies
    var tokenRefreshes: Int64
    var authRejections: Int64
    var impressionsQueued: Int64
    var impressionsDeduped: Int64
    var impressionsDropped: Int64
    var splitCount: Int64
    var segmentCount: Int64
    var segmentKeyCount: Int64
    var sessionLengthMs: Int64
    var eventsQueued: Int64
    var eventsDropped: Int64
    var streamingEvents: [TelemetryStreamingEvent]
    var tags: [String]

    enum CodingKeys: String, CodingKey {
        case lastSynchronization = "lS"
        case methodLatencies = "ml"
        case methodExceptions = "mE"
        case httpErrors = "hE"
        case httpLatencies = "hL"
        case tokenRefreshes = "tR"
        case authRejections = "aR"
        case impressionsQueued = "iQ"
        case impressionsDeduped = "iDe"
        case impressionsDropped = "iDr"
        case splitCount = "spC"
        case segmentCount = "seC"
        case segmentKeyCount = "skC"
        case sessionLengthMs = "sL"
        case eventsQueued = "eQ"
        case eventsDropped = "eD"
        case streamingEvents = "sE"
        case tags = "t"
    }
}
