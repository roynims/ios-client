//
//  DefaultTreatmentManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 05/07/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class DefaultTreatmentManager: TreatmentManager {
    
    private let key: Key
    private let metricsManager: DefaultMetricsManager
    private let impressionsManager: ImpressionsManager
    private let eventsManager: SplitEventsManager
    private let keyValidator: KeyValidator
    private let splitValidator: SplitValidator
    private let validationLogger: ValidationMessageLogger
    private let evaluator: Evaluator
    private let splitConfig: SplitClientConfig
    
    init(evaluator: Evaluator,
         key: Key,
         splitConfig: SplitClientConfig,
         eventsManager: SplitEventsManager,
         impressionsManager: ImpressionsManager,
         metricsManager: DefaultMetricsManager,
         keyValidator: KeyValidator,
         splitValidator: SplitValidator,
         validationLogger: ValidationMessageLogger) {
        
        self.key = key
        self.splitConfig = splitConfig
        self.evaluator = evaluator
        self.eventsManager = eventsManager
        self.impressionsManager = impressionsManager
        self.metricsManager = metricsManager
        self.keyValidator = keyValidator
        self.splitValidator = splitValidator
        self.validationLogger = validationLogger
    }
    
    func getTreatmentWithConfig(_ splitName: String, attributes: [String : Any]?) -> SplitResult {
        let timeMetricStart = Date().unixTimestampInMicroseconds()
        let result = getTreatmentWithConfigNoMetrics(splitName: splitName, shouldValidate: true, attributes: attributes, validationTag: ValidationTag.getTreatmentWithConfig)
        metricsManager.time(microseconds: Date().unixTimestampInMicroseconds() - timeMetricStart, for: Metrics.time.getTreatmentWithConfig)
        return result
    }
    
    func getTreatment(_ splitName: String, attributes: [String : Any]?) -> String {
        let timeMetricStart = Date().unixTimestampInMicroseconds()
        let result = getTreatmentWithConfigNoMetrics(splitName: splitName, shouldValidate: true, attributes: attributes, validationTag: ValidationTag.getTreatment).treatment
        metricsManager.time(microseconds: Date().unixTimestampInMicroseconds() - timeMetricStart, for: Metrics.time.getTreatment)
        return result
    }
    
    func getTreatments(splits: [String], attributes:[String:Any]?) ->  [String:String] {
        let timeMetricStart = Date().unixTimestampInMicroseconds()
        let result = getTreatmentsWithConfigNoMetrics(splits: splits, attributes: attributes, validationTag: ValidationTag.getTreatments).mapValues { $0.treatment }
        metricsManager.time(microseconds: Date().unixTimestampInMicroseconds() - timeMetricStart, for: Metrics.time.getTreatments)
        return result
    }
    
    func getTreatmentsWithConfig(splits: [String], attributes:[String:Any]?) ->  [String:SplitResult] {
        let timeMetricStart = Date().unixTimestampInMicroseconds()
        let result = getTreatmentsWithConfigNoMetrics(splits: splits, attributes: attributes, validationTag: ValidationTag.getTreatmentsWithConfig)
        metricsManager.time(microseconds: Date().unixTimestampInMicroseconds() - timeMetricStart, for: Metrics.time.getTreatmentsWithConfig)
        return result
    }
    
    private func getTreatmentsWithConfigNoMetrics(splits: [String], attributes:[String:Any]?, validationTag: String) ->  [String:SplitResult] {
        var results = [String:SplitResult]()
        
        if let errorInfo = keyValidator.validate(matchingKey: key.matchingKey, bucketingKey: key.bucketingKey) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            return splits.filter { !$0.isEmpty() }.reduce([String: SplitResult]()) { results, splitName in
                var res = results
                res[splitName] = SplitResult(treatment: SplitConstants.CONTROL)
                return res
            }
        }
        
        if splits.count > 0 {
            let splitsNoDuplicated = Set(splits.filter { !$0.isEmpty() }.map { $0 })
            for splitName in splitsNoDuplicated {
                results[splitName] = getTreatmentWithConfigNoMetrics(splitName: splitName, shouldValidate: false, attributes: attributes, validationTag: validationTag)
            }
        } else {
            Logger.d("\(validationTag): split_names is an empty array or has null values")
        }
        return results
    }
    
    private func getTreatmentWithConfigNoMetrics(splitName: String, shouldValidate: Bool = true, attributes:[String:Any]? = nil, validationTag: String) -> SplitResult {
        
        if shouldValidate, let errorInfo = keyValidator.validate(matchingKey: key.matchingKey, bucketingKey: key.bucketingKey) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            return SplitResult(treatment: SplitConstants.CONTROL)
        }
        
        if let errorInfo = splitValidator.validate(name: splitName) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            if errorInfo.isError {
                return SplitResult(treatment: SplitConstants.CONTROL)
            }
        }
        
        if let errorInfo = splitValidator.validateSplit(name: splitName) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            if errorInfo.isError || errorInfo.hasWarning(.nonExistingSplit) {
                return SplitResult(treatment: SplitConstants.CONTROL)
            }
        }
        
        let trimmedSplitName = splitName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let result = try evaluateIfReady(splitName: trimmedSplitName, attributes: attributes)
            logImpression(label: result.label, changeNumber: result.splitVersion, treatment: result.treatment, splitName: trimmedSplitName, attributes: attributes)
            return SplitResult(treatment: result.treatment, config: result.configuration)
        }
        catch {
            logImpression(label: ImpressionsConstants.EXCEPTION, treatment: SplitConstants.CONTROL, splitName: trimmedSplitName, attributes: attributes)
            return SplitResult(treatment: SplitConstants.CONTROL)
        }
    }
    
    private func evaluateIfReady(splitName: String, attributes:[String:Any]?) throws -> EvaluationResult {
        if !isSdkReady() {
            return EvaluationResult(treatment: SplitConstants.CONTROL, label: ImpressionsConstants.NOT_READY);
        }
        return try evaluator.evalTreatment(matchingKey: key.matchingKey, bucketingKey: key.bucketingKey, splitName: splitName, attributes: attributes)
    }
    
    private func logImpression(label: String, changeNumber: Int64? = nil, treatment: String, splitName: String, attributes:[String:Any]? = nil) {
        let impression: Impression = Impression()
        impression.keyName = key.matchingKey
        impression.bucketingKey = key.bucketingKey
        impression.label = (splitConfig.isLabelsEnabled ? label : nil)
        impression.changeNumber = changeNumber
        impression.treatment = treatment
        impression.time = Date().unixTimestampInMiliseconds()
        impressionsManager.appendImpression(impression: impression, splitName: splitName)
        
        if let externalImpressionHandler = splitConfig.impressionListener {
            impression.attributes = attributes
            externalImpressionHandler(impression)
        }
    }
    
    private func isSdkReady() -> Bool {
        return eventsManager.eventAlreadyTriggered(event: SplitEvent.sdkReady)
    }
    
}
