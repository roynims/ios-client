//
// HttpError.swift
// Split
//
// Created by Javier L. Avrudsky on 04/06/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

enum HttpError: Error {
    case couldNotCreateRequest(message: String)
}

// MARK: Get message
extension HttpError {
    var message: String {
        switch self {
        case .couldNotCreateRequest(let message):
            return message
        default:
            return "An unknown error has occurred"
        }
    }
}
