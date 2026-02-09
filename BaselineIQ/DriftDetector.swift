//
//  DriftDetector.swift
//  BaselineIQ
//
//  Created by Assistant on 2/8/26.
//

import Foundation

struct DriftDetector {
    struct Config {
        var baselineWindowDays: Double = 30   // Last 30 days as baseline
        var recentWindowDays: Double = 7      // Compare last 7 days vs baseline
        var zThreshold: Double = 2.0
        var minDataPoints: Int = 5
        var minSeparationDays: Double = 3
    }

    /// Detect drifts by comparing last 7 days to 30-day baseline
    static func detectDrifts(for series: MetricSeries, config: Config = Config()) -> [DriftEvent] {
        let points = series.sortedPoints
        guard points.count >= config.minDataPoints else { return [] }
        
        guard let latestDate = points.last?.date else { return [] }
        
        // Define time windows
        let recentStart = latestDate.addingTimeInterval(-config.recentWindowDays * 24 * 3600)
        let baselineStart = latestDate.addingTimeInterval(-config.baselineWindowDays * 24 * 3600)
        
        // Get recent points (last 7 days)
        let recentPoints = points.filter { $0.date >= recentStart }
        
        // Get baseline points (30 days, excluding last 7 days for cleaner comparison)
        let baselinePoints = points.filter { $0.date >= baselineStart && $0.date < recentStart }
        
        guard recentPoints.count >= 3 else { return [] }
        guard baselinePoints.count >= config.minDataPoints else { return [] }
        
        // Calculate baseline statistics
        let baselineMean = baselinePoints.map { $0.value }.reduce(0, +) / Double(baselinePoints.count)
        let baselineStd = stddev(baselinePoints.map { $0.value })
        
        // Calculate recent statistics
        let recentMean = recentPoints.map { $0.value }.reduce(0, +) / Double(recentPoints.count)
        
        // Calculate z-score (how many standard deviations from baseline)
        let zScore = baselineStd > 0.001 ? (recentMean - baselineMean) / baselineStd : 0
        
        // Calculate percent change
        let percentChange = baselineMean != 0 ? ((recentMean - baselineMean) / abs(baselineMean)) * 100 : 0
        
        // Calculate data density (coverage in recent window)
        let expectedRecentDays = config.recentWindowDays
        let actualRecentDays = Double(recentPoints.count)
        let dataDensity = min(actualRecentDays / expectedRecentDays, 1.0)
        
        // Calculate baseline data density
        let expectedBaselineDays = config.baselineWindowDays - config.recentWindowDays
        let actualBaselineDays = Double(baselinePoints.count)
        let baselineDataDensity = min(actualBaselineDays / expectedBaselineDays, 1.0)
        
        // Generate missing data warning
        var missingDataWarning: String? = nil
        if dataDensity < 0.5 {
            missingDataWarning = "Limited recent data (\(recentPoints.count) points in last 7 days)"
        } else if baselineDataDensity < 0.3 {
            missingDataWarning = "Sparse baseline data (\(baselinePoints.count) points in baseline)"
        }
        
        // Check if drift is significant
        guard abs(zScore) >= config.zThreshold else { return [] }
        
        // Determine direction
        let direction: DriftDirection = zScore > 0 ? .up : .down
        
        // Find when drift started (first point in recent window that deviates)
        let startDate = recentPoints.first?.date ?? latestDate
        
        // Calculate confidence based on z-score magnitude and data density
        let zConfidence = min(abs(zScore) / 4.0, 1.0)
        let confidence = zConfidence * (0.5 + 0.5 * min(dataDensity, baselineDataDensity))
        
        let event = DriftEvent(
            metric: series.metric,
            date: latestDate,
            direction: direction,
            magnitude: abs(recentMean - baselineMean),
            beforeMean: baselineMean,
            afterMean: recentMean,
            confidence: confidence,
            method: "baseline-comparison",
            zScore: zScore,
            percentChange: percentChange,
            dataDensity: dataDensity,
            startDate: startDate,
            missingDataWarning: missingDataWarning
        )
        
        return [event]
    }

    private static func stddev(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return variance.squareRoot()
    }
}
