//
//  DemoDataProvider.swift
//  BaselineIQ
//
//  Created by Assistant on 2/8/26.
//

import Foundation

enum DemoDataProvider {
    static func sampleSeries() -> [MetricSeries] {
        let days = 120
        let driftStartIndex = 80 // drift begins ~40 days ago
        let dates = (0..<days).map { i -> Date in
            let day = Calendar.current.date(byAdding: .day, value: -(days - 1 - i), to: Date())!
            // normalize to noon local time for stability
            let comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
            return Calendar.current.date(from: DateComponents(year: comps.year, month: comps.month, day: comps.day, hour: 12))!
        }

        func noise(_ s: Double) -> Double { (Double.random(in: -1...1) + Double.random(in: -1...1)) * 0.5 * s }

        // Resting HR: baseline 58 bpm; +8 bpm after drift start
        let hrPoints: [TimeSeriesPoint] = dates.enumerated().map { (i, d) in
            let base = 58.0
            let drift = i >= driftStartIndex ? 8.0 : 0.0
            let v = max(40.0, base + drift + noise(2.0))
            return TimeSeriesPoint(date: d, value: v)
        }

        // Sleep duration: baseline 7.2 hr; -1.0 hr after drift start
        let sleepPoints: [TimeSeriesPoint] = dates.enumerated().map { (i, d) in
            let base = 7.2
            let drift = i >= driftStartIndex ? -1.0 : 0.0
            let v = max(3.0, base + drift + noise(0.25))
            return TimeSeriesPoint(date: d, value: v)
        }

        // SpO2: baseline 97%; -1.5% after drift start
        let spo2Points: [TimeSeriesPoint] = dates.enumerated().map { (i, d) in
            let base = 97.0
            let drift = i >= driftStartIndex ? -1.5 : 0.0
            let v = min(100.0, max(90.0, base + drift + noise(0.3)))
            return TimeSeriesPoint(date: d, value: v)
        }

        // Weight: baseline 72 kg; +3 kg after drift start
        let weightPoints: [TimeSeriesPoint] = dates.enumerated().map { (i, d) in
            let base = 72.0
            let drift = i >= driftStartIndex ? 3.0 : 0.0
            let v = max(40.0, base + drift + noise(0.4))
            return TimeSeriesPoint(date: d, value: v)
        }

        // Glucose: baseline 95 mg/dL; +20 after drift start
        let glucosePoints: [TimeSeriesPoint] = dates.enumerated().map { (i, d) in
            let base = 95.0
            let drift = i >= driftStartIndex ? 20.0 : 0.0
            let v = max(60.0, base + drift + noise(5.0))
            return TimeSeriesPoint(date: d, value: v)
        }

        // BP Systolic: baseline 118; +10 after drift start
        let bpSysPoints: [TimeSeriesPoint] = dates.enumerated().map { (i, d) in
            let base = 118.0
            let drift = i >= driftStartIndex ? 10.0 : 0.0
            let v = max(80.0, base + drift + noise(4.0))
            return TimeSeriesPoint(date: d, value: v)
        }

        // BP Diastolic: baseline 76; +6 after drift start
        let bpDiaPoints: [TimeSeriesPoint] = dates.enumerated().map { (i, d) in
            let base = 76.0
            let drift = i >= driftStartIndex ? 6.0 : 0.0
            let v = max(50.0, base + drift + noise(3.0))
            return TimeSeriesPoint(date: d, value: v)
        }

        return [
            MetricSeries(metric: .restingHeartRate, points: hrPoints),
            MetricSeries(metric: .sleepDuration, points: sleepPoints),
            MetricSeries(metric: .oxygenSaturation, points: spo2Points),
            MetricSeries(metric: .weight, points: weightPoints),
            MetricSeries(metric: .glucose, points: glucosePoints),
            MetricSeries(metric: .bloodPressureSystolic, points: bpSysPoints),
            MetricSeries(metric: .bloodPressureDiastolic, points: bpDiaPoints)
        ]
    }

    static func sampleCSVString() -> String {
        let series = sampleSeries()
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"; df.timeZone = .current
        var rows: [String] = ["date,metric,value"]
        for s in series {
            for p in s.points {
                let dateStr = df.string(from: p.date)
                rows.append("\(dateStr),\(s.metric.rawValue),\(String(format: "%.3f", p.value))")
            }
        }
        return rows.joined(separator: "\n")
    }

    static func writeSampleCSV() -> URL? {
        let csv = sampleCSVString()
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("demo_health_timeline.csv")
        do {
            try csv.data(using: .utf8)?.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
