//
//  SplitFactory+bgSync.swift
//  Split
//
//  Created by Javier Avrudsky on 22-Feb-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

class BgSyncConfigurator {
    static func setup(enabled: Bool, apiKey: String, userKey: String) {
#if os(iOS)
        if enabled {
            SplitBgSynchronizer.shared.register(apiKey: apiKey, userKey: userKey)
        } else {
            SplitBgSynchronizer.shared.unregister(apiKey: apiKey, userKey: userKey)
        }
#endif
    }
}