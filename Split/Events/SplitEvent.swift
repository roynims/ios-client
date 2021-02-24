//
//  SplitEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

@objc public enum SplitEvent: Int {
    case sdkReady
    case sdkReadyTimedOut
    case sdkReadyFromCache

    func toString() -> String {
        switch self {
        case .sdkReady:
            return "SDK_READY"
        case .sdkReadyTimedOut:
            return "SDK_READY_TIMED_OUT"
        case .sdkReadyFromCache:
            return "SDK_READY_FROM_CACHE"
        }
    }
}
