//
//  PDFGenerator.swift
//  BaselineIQ
//
//  Created by Assistant on 2/8/26.
//

import Foundation
import SwiftUI
import PDFKit
#if canImport(AppKit)
import AppKit
#endif

enum PDFGenerator {
    static func generateSummaryPDF(seriesByMetric: [MetricType: MetricSeries], driftEvents: [DriftEvent]) -> URL? {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ClinicalDriftSummary.pdf")
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        
        #if canImport(AppKit)
        let renderer = ImageRenderer(content: OnePageSummaryView(seriesByMetric: seriesByMetric, driftEvents: driftEvents))
        renderer.scale = 2.0
        
        var mediaBox = pageRect
        guard let consumer = CGDataConsumer(url: tmp as CFURL),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }
        
        let pdfPageInfo: [CFString: Any] = [
            kCGPDFContextTitle: "BaselineIQ Summary" as CFString
        ]
        
        pdfContext.beginPDFPage(pdfPageInfo as CFDictionary)
        
        renderer.render { size, render in
            let scale = min(pageRect.width / size.width, pageRect.height / size.height)
            pdfContext.saveGState()
            pdfContext.translateBy(x: 0, y: pageRect.height)
            pdfContext.scaleBy(x: 1, y: -1)
            pdfContext.translateBy(x: (pageRect.width - size.width * scale)/2, y: (pageRect.height - size.height * scale)/2)
            pdfContext.scaleBy(x: scale, y: scale)
            render(pdfContext)
            pdfContext.restoreGState()
        }
        
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        return tmp
        #else
        return nil
        #endif
    }
}

// MARK: - One-Page Clinician Summary View

struct OnePageSummaryView: View {
    let seriesByMetric: [MetricType: MetricSeries]
    let driftEvents: [DriftEvent]
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("BaselineIQ Summary")
                        .font(.title2).bold()
                    Text("Patient Health Metrics Analysis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Generated: \(Date().formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                    Text("Local processing only")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Key Drifts Table
            if driftEvents.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No significant drifts detected in the analysis period.")
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
            } else {
                Text("Key Drifts Detected")
                    .font(.headline)
                    .padding(.top, 4)
                
                // Table Header
                HStack(spacing: 0) {
                    Text("Metric").frame(width: 100, alignment: .leading)
                    Text("Direction").frame(width: 70, alignment: .center)
                    Text("Change").frame(width: 70, alignment: .trailing)
                    Text("Z-Score").frame(width: 60, alignment: .trailing)
                    Text("Confidence").frame(width: 70, alignment: .trailing)
                    Text("Trend").frame(width: 100, alignment: .center)
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
                
                Divider()
                
                // Table Rows
                ForEach(driftEvents.sorted { $0.confidence > $1.confidence }) { event in
                    DriftTableRow(event: event, series: seriesByMetric[event.metric])
                }
            }
            
            Divider().padding(.vertical, 4)
            
            // Drift Details
            if !driftEvents.isEmpty {
                Text("Drift Explanations")
                    .font(.headline)
                
                ForEach(driftEvents.sorted { $0.confidence > $1.confidence }) { event in
                    DriftExplanationRow(event: event)
                }
            }
            
            Divider().padding(.vertical, 4)
            
            // Metrics Overview (compact)
            Text("Metrics Overview")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(MetricType.allCases.filter { seriesByMetric[$0] != nil }) { metric in
                    if let series = seriesByMetric[metric] {
                        MetricMiniCard(series: series)
                    }
                }
            }
            
            Spacer(minLength: 8)
            
            // Disclaimer Footer
            VStack(alignment: .leading, spacing: 2) {
                Divider()
                Text("⚠️ NOT MEDICAL ADVICE")
                    .font(.caption.bold())
                Text("This summary is for informational purposes only. It is not a diagnosis or substitute for professional medical judgment. Clinical decisions should be made by a licensed healthcare provider with full patient context.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 560) // Fit within letter page margins
    }
}

// MARK: - Table Row

struct DriftTableRow: View {
    let event: DriftEvent
    let series: MetricSeries?
    
    var body: some View {
        HStack(spacing: 0) {
            Text(event.metric.displayName)
                .frame(width: 100, alignment: .leading)
            
            HStack(spacing: 2) {
                Image(systemName: event.direction == .up ? "arrow.up" : "arrow.down")
                    .foregroundColor(event.direction == .up ? .red : .blue)
                Text(event.direction == .up ? "Up" : "Down")
            }
            .frame(width: 70, alignment: .center)
            
            Text("\(String(format: "%.1f", abs(event.percentChange)))%")
                .frame(width: 70, alignment: .trailing)
            
            Text(String(format: "%.2f", event.zScore))
                .frame(width: 60, alignment: .trailing)
            
            Text("\(Int(event.confidence * 100))%")
                .frame(width: 70, alignment: .trailing)
            
            // Mini sparkline
            if let series = series {
                MiniSparkline(points: series.sortedPoints.suffix(14))
                    .frame(width: 100, height: 20)
            } else {
                Text("—").frame(width: 100, alignment: .center)
            }
        }
        .font(.caption)
        .padding(.vertical, 2)
    }
}

// MARK: - Drift Explanation

struct DriftExplanationRow: View {
    let event: DriftEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Circle()
                    .fill(event.metric.color)
                    .frame(width: 8, height: 8)
                Text(event.metric.displayName)
                    .font(.caption.bold())
                Spacer()
                if event.missingDataWarning != nil {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption2)
                }
            }
            
            Text("• What: \(event.direction == .up ? "Increased" : "Decreased") from \(event.metric.formatValue(event.beforeMean)) to \(event.metric.formatValue(event.afterMean))")
                .font(.caption2)
            
            Text("• When: Started around \(formattedDate(event.startDate))")
                .font(.caption2)
            
            Text("• Size: \(String(format: "%.1f", abs(event.percentChange)))% change (z=\(String(format: "%.2f", event.zScore)))")
                .font(.caption2)
            
            if let warning = event.missingDataWarning {
                Text("• Warning: \(warning)")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

// MARK: - Mini Sparkline

struct MiniSparkline: View {
    let points: ArraySlice<TimeSeriesPoint>
    
    var body: some View {
        GeometryReader { geo in
            if points.count >= 2 {
                let values = points.map { $0.value }
                let minVal = values.min() ?? 0
                let maxVal = values.max() ?? 1
                let range = max(maxVal - minVal, 0.001)
                
                Path { path in
                    for (i, point) in points.enumerated() {
                        let x = geo.size.width * CGFloat(i) / CGFloat(points.count - 1)
                        let y = geo.size.height * (1 - CGFloat((point.value - minVal) / range))
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 1.5)
            } else {
                Text("—")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Metric Mini Card

struct MetricMiniCard: View {
    let series: MetricSeries
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(series.metric.color)
                .frame(width: 6, height: 6)
            Text(series.metric.displayName)
                .font(.caption2)
            Spacer()
            if let latest = series.latest {
                Text(series.metric.formatValue(latest.value))
                    .font(.caption2.bold())
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
    }
}
