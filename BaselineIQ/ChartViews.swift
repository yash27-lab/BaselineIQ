//
//  ChartViews.swift
//  BaselineIQ
//
//  Created by Assistant on 2/8/26.
//

import SwiftUI
import Charts

struct MetricChartView: View {
    let series: MetricSeries
    let events: [DriftEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(series.metric.displayName)
                    .font(.headline)
                Spacer()
                if let latest = series.latest {
                    Text(series.metric.formatValue(latest.value))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Chart {
                ForEach(series.sortedPoints) { p in
                    LineMark(
                        x: .value("Date", p.date),
                        y: .value("Value", p.value)
                    )
                    .foregroundStyle(series.metric.color)
                }

                ForEach(events) { e in
                    RuleMark(x: .value("Drift", e.date))
                        .foregroundStyle(e.direction == .up ? Color.red.opacity(0.5) : Color.blue.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4,4]))
                        .annotation(position: .top, alignment: .leading) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Drift: \(e.method)")
                                    .font(.caption2)
                                    .bold()
                                Text("Conf: \(Int(e.confidence * 100))%")
                                    .font(.caption2)
                            }
                            .padding(4)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .frame(height: 180)
        }
        .padding(.vertical, 8)
    }
}
