//
//  EventDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import CoreData

protocol SplitDao {
    func insertOrUpdate(splits: [Split])
    func insertOrUpdate(split: Split)
    func getAll() -> [Split]
    func delete(_ splits: [String])
    func deleteAll()
    func syncInsertOrUpdate(split: Split)
}

class CoreDataSplitDao: BaseCoreDataDao, SplitDao {
    let decoder: SplitsDecoder = SplitsParallelDecoder()
    let encoder: SplitsEncoder = SplitsParallelEncoder()

    func insertOrUpdate(splits: [Split]) {
        let parsed = self.encoder.encode(splits)
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }

            parsed.forEach { name, json in
                if let obj = self.getBy(name: name) ?? self.coreDataHelper.create(entity: .split) as? SplitEntity {
                    obj.name = name
                    obj.body = json
                    obj.updatedAt = Date.now()
                    // Saving one by one to avoid losing all
                    // if an error occurs
                    self.coreDataHelper.save()
                }
            }
        }
    }

    func insertOrUpdate(split: Split) {
        executeAsync { [weak self] in
            if let self = self {
                self.insertOrUpdate(split)
            }
        }
    }

    // For testing purposes only
    func syncInsertOrUpdate(split: Split) {
        execute { [weak self] in
            if let self = self {
                self.insertOrUpdate(split)
            }
        }
    }

    func getAll() -> [Split] {
        var splits: [Split]?
        execute { [weak self] in
            guard let self = self else {
                return
            }

            let jsonSplits = self.coreDataHelper.fetch(entity: .split)
                .compactMap { return $0 as? SplitEntity }
                .compactMap { return $0.body }

            let start = Date.nowMillis()
            splits = self.decoder.decode(jsonSplits).map { $0 }
            let time = Date().unixTimestampInMiliseconds() - start
            print("Time to parse splits : \(time)")
        }
        return splits ?? []
    }

    func delete(_ splits: [String]) {
        if splits.count == 0 {
            return
        }

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.delete(entity: .split, by: "name", values: splits)
        }
    }

    func deleteAll() {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.deleteAll(entity: .split)
        }
    }

    private func insertOrUpdate(_ split: Split) {
        if let splitName = split.name,
           let obj = self.getBy(name: splitName) ?? self.coreDataHelper.create(entity: .split) as? SplitEntity {
            do {
                obj.name = splitName
                obj.body = try Json.encodeToJson(split)
                obj.updatedAt = Date.now()
                // Saving one by one to avoid losing all
                // if an error occurs
                self.coreDataHelper.save()
            } catch {
                Logger.e("An error occurred while inserting split in storage: \(error.localizedDescription)")
            }
        }
    }

    private func getBy(name: String) -> SplitEntity? {
        let predicate = NSPredicate(format: "name == %@", name)
        let entities = coreDataHelper.fetch(entity: .split,
                                            where: predicate).compactMap { return $0 as? SplitEntity }
        return entities.count > 0 ? entities[0] : nil
    }

    private func mapEntityToModel(_ entity: SplitEntity) throws -> Split {
        let model = try Json.encodeFrom(json: entity.body, to: Split.self)
        return model
    }
}
