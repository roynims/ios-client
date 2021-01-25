//
//  RecorderWorkerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class RecorderWorkerStub: RecorderWorker {
    var flushCalled = false
    var flushCallCount = 0
    func flush() {
        flushCalled = true
        flushCallCount+=1
    }
}
