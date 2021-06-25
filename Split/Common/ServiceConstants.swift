//
//  ServiceConstants.swift
//  Split
//
//  Created by Javier Avrudsky on 12/01/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

struct ServiceConstants {
    static let estimatedImpressionSizeInBytes = 150
    static let recordedDataExpirationPeriodInSeconds: Int64 = 3600 * 24 * 90 // 90 days
    static let cacheControlHeader = "Cache-Control"
    static let cacheControlNoCache = "no-cache"
    static let eventsPerPush: Int = 2000
    static let impressionsQueueSize: Int = 30000
    static let defaultDataFolder = "split_data"
    static let cacheExpirationInSeconds = 864000
    static let controlNoCacheHeader = [ServiceConstants.cacheControlHeader: ServiceConstants.cacheControlNoCache]
    static let backgroundSyncPeriod = 15.0 * 60 // 15 min
    static let defaultImpressionCountRowsPop = 200
}
