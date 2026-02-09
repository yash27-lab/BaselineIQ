//
//  CSVImporter.swift
//  BaselineIQ
//
//  Created by Assistant on 2/8/26.
//

import Foundation

enum CSVImporter {
    // Expected CSV format:
    // date,metric,value
    // 2025-11-01,restingHeartRate,58
    // 2025-11-01,sleepDuration,7.2
    // Dates parsed in ISO8601 or yyyy-MM-dd HH:mm

    static func parse(url: URL) throws -> [MetricSeries] {
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "CSVImporter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid encoding"])
        }
        let lines = text.split(whereSeparator: { "\n\r".contains($0) })
        guard !lines.isEmpty else { return [] }
        // optional header detection
        var startIndex = 0
        if lines[0].lowercased().contains("metric") && lines[0].lowercased().contains("date") {
            startIndex = 1
        }
        var buckets: [MetricType: [TimeSeriesPoint]] = [:]
        for i in startIndex..<lines.count {
            let line = String(lines[i])
            let parts = splitCSV(line)
            guard parts.count >= 3 else { continue }
            let dateStr = parts[0].trimmingCharacters(in: .whitespaces)
            let metricStr = parts[1].trimmingCharacters(in: .whitespaces)
            let valueStr = parts[2].trimmingCharacters(in: .whitespaces)
            guard let metric = MetricType(rawValue: metricStr) else { continue }
            guard let date = parseDate(dateStr) else { continue }
            guard let value = Double(valueStr) else { continue }
            buckets[metric, default: []].append(TimeSeriesPoint(date: date, value: value))
        }
        return buckets.map { MetricSeries(metric: $0.key, points: $0.value) }
    }

    private static func splitCSV(_ line: String) -> [String] {
        // naive split supporting quoted commas
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for c in line {
            if c == Character("\"") { inQuotes.toggle(); continue }
            if c == Character(",") && !inQuotes { result.append(current); current = "" } else { current.append(c) }
        }
        result.append(current)
        return result
    }

    private static func parseDate(_ s: String) -> Date? {
        if let d = ISO8601DateFormatter().date(from: s) { return d }
        let f1 = DateFormatter(); f1.dateFormat = "yyyy-MM-dd HH:mm"; f1.timeZone = .current
        if let d = f1.date(from: s) { return d }
        let f2 = DateFormatter(); f2.dateFormat = "yyyy-MM-dd"; f2.timeZone = .current
        if let d = f2.date(from: s) { return d }
        return nil
    }
}
