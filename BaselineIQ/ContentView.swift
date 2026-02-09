//
//  ContentView.swift
//  BaselineIQ
//
//  Created by yash negi on 2/8/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ContentHeader()
                    ImportButtons()

                    Divider()

                    if model.seriesByMetric.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Get started")
                                .font(.headline)
                            Text("• Import a CSV with columns: date,metric,value. Supported metrics: restingHeartRate, sleepDuration, oxygenSaturation, weight, glucose, bloodPressureSystolic, bloodPressureDiastolic.")
                            Text("• Or import the Apple Health export.xml (unzip first).")
                            Text("• Or tap \"Load Demo Data\" to try it instantly, or \"Export Demo CSV\" to share a sample file.")
                            Text("All processing is done locally on-device.")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                    } else {
                        ForEach(model.metricsSorted) { s in
                            MetricChartView(series: s, events: model.driftEvents.filter { $0.metric == s.metric })
                        }
                        .padding(.horizontal, 4)
                    }

                    Divider()

                    HStack {
                        Button(role: .destructive) {
                            model.clearAll()
                        } label: {
                            Label("Clear Data", systemImage: "trash")
                        }

                        Spacer()

                        Button {
                            model.recomputeDrifts()
                        } label: {
                            Label("Re-run Analysis", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .disabled(model.seriesByMetric.isEmpty)
                    }

                    Text("Disclaimer: This tool is not a medical device and does not provide medical advice. It highlights potential changes for clinician review.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("BaselineIQ")
        }
        .environmentObject(model)
    }
}

#Preview {
    ContentView()
}
