//
//  String+Utils.swift
//  Split
//
//  Created by Javier L. Avrudsky on 04/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

extension String {
    func isEmpty() -> Bool {
        return (self.trimmingCharacters(in: .whitespacesAndNewlines) == "")
    }

    func hasUpperCaseChar() -> Bool {
        return self.lowercased() != self
    }

    var dataBytes: Data? {
        return self.data(using: .utf8)
    }


}
