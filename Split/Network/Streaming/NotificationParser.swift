//
//  NotificationParser.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class NotificationParser {

    private static let kErrorNotificationName = "error"

    func parseIncoming(jsonString: String) -> IncomingNotification? {
        do {
            let rawNotification = try Json.encodeFrom(json: jsonString, to: RawNotification.self)
            if isError(notification: rawNotification) {
                return IncomingNotification(type: .error)
            }
            var type = NotificationType.occupancy
            if let notificationType = try? Json.encodeFrom(json: rawNotification.data,
                                                           to: NotificationTypeValue.self) {
                type = notificationType.type
            }
            return IncomingNotification(type: type, jsonData: rawNotification.data)
        } catch {
            Logger.e("Unexpected error while parsing streaming notification \(error.localizedDescription)")
        }
        return nil
    }

    func  parseSplitUpdate(jsonString: String) throws -> SplitsChangeNotification {
        return try Json.encodeFrom(json: jsonString, to: SplitsChangeNotification.self)
    }

    func  parseSplitKill(jsonString: String) throws -> SplitKillNotification {
        return try Json.encodeFrom(json: jsonString, to: SplitKillNotification.self)
    }

    func  parseMySegmentUpdate(jsonString: String) throws -> MySegmentsChangeNotification {
        return try Json.encodeFrom(json: jsonString, to: MySegmentsChangeNotification.self)
    }

    func  parseOccupancy(jsonString: String) throws -> OccupancyNotification {
        return try Json.encodeFrom(json: jsonString, to: OccupancyNotification.self)
    }

    func  parseControl(jsonString: String) throws -> ControlNotification {
        return try Json.encodeFrom(json: jsonString, to: ControlNotification.self)
    }
}

extension NotificationParser {
    func isError(notification: RawNotification) -> Bool {
        return Self.kErrorNotificationName == notification.name
    }
}
