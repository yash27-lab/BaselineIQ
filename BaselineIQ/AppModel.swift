//
//  AppModel.swift
//  BaselineIQ
//
//  Created by Assistant on 2/8/26.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    @Published var seriesByMetric: [MetricType: MetricSeries] = [:]
    @Published var driftEvents: [DriftEvent] = []
    @Published var lastImportMessage: String? = nil
    @Published var lastErrorMessage: String? = nil

    var metricsSorted: [MetricSeries] {
        seriesByMetric.values.sorted { $0.metric.displayName < $1.metric.displayName }
    }

    func clearAll() {
        seriesByMetric = [:]
        driftEvents = []
        lastImportMessage = nil
        lastErrorMessage = nil
    }

    func ingestSeries(_ imported: [MetricSeries]) {
        var updated = seriesByMetric
        for s in imported {
            var merged = (updated[s.metric]?.points ?? []) + s.points
            // dedup by date timestamp
            let grouped = Dictionary(grouping: merged, by: { $0.date.timeIntervalSince1970 })
            merged = grouped.values.compactMap { group in
                // average duplicates
                let v = group.map { $0.value }.reduce(0, +) / Double(group.count)
                return TimeSeriesPoint(date: group[0].date, value: v)
            }
            merged.sort { $0.date < $1.date }
            updated[s.metric] = MetricSeries(metric: s.metric, points: merged)
        }
        seriesByMetric = updated
        recomputeDrifts()
    }

    func recomputeDrifts() {
        var all: [DriftEvent] = []
        for s in seriesByMetric.values {
            let events = DriftDetector.detectDrifts(for: s)
            all.append(contentsOf: events)
        }
        driftEvents = all.sorted { $0.date < $1.date }
    }

    func importCSV(from url: URL) async {
        do {
            let imported = try CSVImporter.parse(url: url)
            await MainActor.run {
                self.ingestSeries(imported)
                self.lastImportMessage = "Imported CSV with \(imported.count) metrics."
            }
        } catch {
            await MainActor.run {
                self.lastErrorMessage = "CSV import failed: \(error.localizedDescription)"
            }
        }
    }

    func importAppleHealthXML(from url: URL) async {
        do {
            let imported = try AppleHealthImporter.parseExportXML(url: url)
            await MainActor.run {
                self.ingestSeries(imported)
                self.lastImportMessage = "Imported Apple Health export with \(imported.count) metrics."
            }
        } catch AppleHealthImporter.HealthExportError.zipNotSupported {
            await MainActor.run {
                self.lastErrorMessage = "Please unzip the Apple Health export and select export.xml."
            }
        } catch {
            await MainActor.run {
                self.lastErrorMessage = "Apple Health import failed: \(error.localizedDescription)"
            }
        }
    }

    func generatePDF() -> URL? {
        PDFGenerator.generateSummaryPDF(seriesByMetric: seriesByMetric, driftEvents: driftEvents)
    }
}
