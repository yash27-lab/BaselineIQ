//
//  Models.swift
//  BaselineIQ
//
//  Created by Assistant on 2/8/26.
//

import Foundation
import SwiftUI

enum MetricType: String, CaseIterable, Identifiable, Codable {
    case restingHeartRate
    case sleepDuration
    case oxygenSaturation
    case weight
    case glucose
    case bloodPressureSystolic
    case bloodPressureDiastolic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .restingHeartRate: return "Resting HR"
        case .sleepDuration: return "Sleep Duration"
        case .oxygenSaturation: return "SpO₂"
        case .weight: return "Weight"
        case .glucose: return "Glucose"
        case .bloodPressureSystolic: return "BP Systolic"
        case .bloodPressureDiastolic: return "BP Diastolic"
        }
    }

    var unitSymbol: String {
        switch self {
        case .restingHeartRate: return "bpm"
        case .sleepDuration: return "hr"
        case .oxygenSaturation: return "%"
        case .weight: return "kg"
        case .glucose: return "mg/dL"
        case .bloodPressureSystolic, .bloodPressureDiastolic: return "mmHg"
        }
    }

    var color: Color {
        switch self {
        case .restingHeartRate: return .red
        case .sleepDuration: return .blue
        case .oxygenSaturation: return .green
        case .weight: return .orange
        case .glucose: return .purple
        case .bloodPressureSystolic: return .pink
        case .bloodPressureDiastolic: return .teal
        }
    }

    func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        switch self {
        case .restingHeartRate:
            formatter.maximumFractionDigits = 0
        case .sleepDuration:
            formatter.maximumFractionDigits = 2
        case .oxygenSaturation:
            formatter.maximumFractionDigits = 1
        case .weight:
            formatter.maximumFractionDigits = 1
        case .glucose:
            formatter.maximumFractionDigits = 0
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            formatter.maximumFractionDigits = 0
        }
        let n = NSNumber(value: value)
        return (formatter.string(from: n) ?? String(format: "%.2f", value)) + " " + unitSymbol
    }
}

struct TimeSeriesPoint: Identifiable, Codable, Hashable {
    var date: Date
    var value: Double
    var id: Double { date.timeIntervalSince1970 }
}

struct MetricSeries: Identifiable, Codable, Hashable {
    var metric: MetricType
    var points: [TimeSeriesPoint]
    var id: String { metric.rawValue }

    var sortedPoints: [TimeSeriesPoint] {
        points.sorted { $0.date < $1.date }
    }

    var latest: TimeSeriesPoint? { sortedPoints.last }
}

enum DriftDirection: String, Codable {
    case up
    case down
}

struct DriftEvent: Identifiable, Codable, Hashable {
    var id = UUID()
    var metric: MetricType
    var date: Date
    var direction: DriftDirection
    var magnitude: Double
    var beforeMean: Double
    var afterMean: Double
    var confidence: Double // 0.0 - 1.0
    var method: String // "baseline-comparison"
    
    // Enhanced fields
    var zScore: Double = 0
    var percentChange: Double = 0
    var dataDensity: Double = 1.0  // 0-1 based on data coverage
    var startDate: Date = Date()
    var missingDataWarning: String? = nil

    var summary: String {
        let dir = direction == .up ? "increased" : "decreased"
        return "\(metric.displayName) \(dir) by \(String(format: "%.1f", abs(percentChange)))%"
    }
    
    var detailedExplanation: String {
        let dir = direction == .up ? "increased" : "decreased"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var explanation = """
        What changed: \(metric.displayName) \(dir) from baseline
        When it started: Around \(dateFormatter.string(from: startDate))
        How big: \(String(format: "%.1f", abs(percentChange)))% change (z-score: \(String(format: "%.2f", zScore)))
        Why flagged: Z-score exceeds threshold (|z| ≥ 2.0 indicates statistical significance)
        """
        
        if let warning = missingDataWarning {
            explanation += "\n⚠️ Data warning: \(warning)"
        }
        
        return explanation
    }
}

struct SuggestionBundle: Hashable {
    var questions: [String]
    var followUps: [String]
}

enum HealthSuggestions {
    static func suggestions(for event: DriftEvent) -> SuggestionBundle {
        switch event.metric {
        case .restingHeartRate:
            return SuggestionBundle(
                questions: [
                    "Any recent illness, fever, or infection?",
                    "Changes in training intensity, stress, or caffeine intake?",
                    "Any new medications or supplements?",
                    "Changes in sleep quality or duration?"
                ],
                followUps: [
                    "Discuss an ECG or rhythm evaluation if symptoms are present.",
                    "Consider thyroid function tests per clinician judgment.",
                    "Review training load and recovery." 
                ]
            )
        case .sleepDuration:
            return SuggestionBundle(
                questions: [
                    "Have your bedtimes or wake times changed recently?",
                    "Any issues with insomnia or frequent awakenings?",
                    "Changes in work schedule, travel, or stress?"
                ],
                followUps: [
                    "Discuss sleep hygiene and possible sleep study if indicated.",
                    "Consider screening for mood or anxiety if appropriate."
                ]
            )
        case .oxygenSaturation:
            return SuggestionBundle(
                questions: [
                    "Any shortness of breath, cough, or respiratory symptoms?",
                    "Changes in altitude or travel?",
                    "Any new wearables or sensor placement changes?"
                ],
                followUps: [
                    "Discuss pulse oximetry recheck and correlation with clinical context.",
                    "Consider pulmonary evaluation if persistent and symptomatic."
                ]
            )
        case .weight:
            return SuggestionBundle(
                questions: [
                    "Any changes in diet, appetite, or fluid intake?",
                    "Changes in activity level?",
                    "Any swelling, bloating, or GI symptoms?"
                ],
                followUps: [
                    "Discuss trend consistency and body composition context.",
                    "Consider metabolic labs per clinician judgment."
                ]
            )
        case .glucose:
            return SuggestionBundle(
                questions: [
                    "Any changes in diet or carbohydrate intake?",
                    "Missed medications or changes to dosing?",
                    "Any infections, stress, or illness?"
                ],
                followUps: [
                    "Discuss SMBG/CGM review and A1c if appropriate.",
                    "Consider medication review with clinician."
                ]
            )
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            return SuggestionBundle(
                questions: [
                    "Any headaches, dizziness, or vision changes?",
                    "Changes in salt intake or hydration?",
                    "Any missed doses of BP medications?"
                ],
                followUps: [
                    "Discuss home BP cuff calibration and technique.",
                    "Consider ambulatory BP monitoring per clinician judgment."
                ]
            )
        }
    }
}
