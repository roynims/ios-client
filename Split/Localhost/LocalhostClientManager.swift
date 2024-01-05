//
//  LocalhostClientManager.swift
//  Split
//
//  Created by Javier Avrudsky on 05-Jan-2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

class LocalhostClientManager: SplitClientManager {
    
    struct LocalhostComponentsGroup {
        let client: SplitClient
        let eventsManager: SplitEventsManager
    }

    private var clients = SynchronizedDictionary<String, LocalhostComponentsGroup>()

    private(set) var defaultClient: SplitClient?

    private let config: SplitClientConfig

    private var eventsManagerCoordinator: SplitEventsManagerCoordinator
    private var synchronizer: FeatureFlagsSynchronizer

    private let defaultKey: Key
    private let evaluator: Evaluator
    private let splitsStorage: SplitsStorage
    private let splitManager: SplitManager

    init(config: SplitClientConfig,
         key: Key,
         splitManager: SplitManager,
         splitsStorage: SplitsStorage,
         synchronizer: FeatureFlagsSynchronizer,
         eventsManagerCoordinator: SplitEventsManagerCoordinator) {

        self.defaultKey = key
        self.config = config
        self.splitManager = splitManager
        self.synchronizer = synchronizer
        self.eventsManagerCoordinator = eventsManagerCoordinator
        self.splitsStorage = splitsStorage

        self.evaluator = DefaultEvaluator(splitsStorage: splitsStorage,
                                          mySegmentsStorage: EmptyMySegmentsStorage())

        defaultClient = client(forKey: key,
                               eventsManager: eventsManagerCoordinator)

        eventsManagerCoordinator.start()

    }

    func get(forKey key: Key) -> SplitClient {
        return client(forKey: key)
    }

    func flush() {
    }

    func destroy(forKey key: Key) {

        if let _ = clients.takeValue(forKey: key.matchingKey),
           clients.count == 0 {
            splitsStorage.destroy()
            (self.splitManager as? Destroyable)?.destroy()

            eventsManagerCoordinator.stop()
            synchronizer.stop()
            Logger.i("Localhost Split SDK destroyed")
        }
    }

    private func client(forKey key: Key,
                        eventsManager: SplitEventsManager? = nil) -> SplitClient {

        if let group = clients.value(forKey: key.matchingKey) {
            return group.client
        }

        let newEventsManager = eventsManager ?? DefaultSplitEventsManager(config: config)
        newEventsManager.start()

        let newClient = LocalhostSplitClient(key: key,
                                             splitsStorage: splitsStorage,
                                             eventsManager: newEventsManager,
                                             evaluator: evaluator)

        let newGroup = LocalhostComponentsGroup(client: newClient, eventsManager: newEventsManager)
        newEventsManager.executorResources.client = newClient
        clients.setValue(newGroup, forKey: key.matchingKey)

        return newClient
    }

}
