//
//  ImportButtons.swift
//  BaselineIQ
//
//  Created by Assistant on 2/8/26.
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct ImportButtons: View {
    @EnvironmentObject var model: AppModel
    @State private var showingCSVPicker = false
    @State private var showingHealthPicker = false

    var body: some View {
        HStack {
            Button {
                showingCSVPicker = true
            } label: {
                Label("Import CSV", systemImage: "tray.and.arrow.down")
            }
            .fileImporter(isPresented: $showingCSVPicker, allowedContentTypes: [.commaSeparatedText, .plainText], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        // Start security-scoped resource access for sandboxed apps
                        let didStart = url.startAccessingSecurityScopedResource()
                        Task {
                            await model.importCSV(from: url)
                            if didStart {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }
                    }
                case .failure(let error):
                    model.lastErrorMessage = error.localizedDescription
                }
            }

            Button {
                showingHealthPicker = true
            } label: {
                Label("Import Apple Health", systemImage: "heart.text.square")
            }
            .fileImporter(isPresented: $showingHealthPicker, allowedContentTypes: [UTType.xml], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        // Start security-scoped resource access for sandboxed apps
                        let didStart = url.startAccessingSecurityScopedResource()
                        Task {
                            await model.importAppleHealthXML(from: url)
                            if didStart {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }
                    }
                case .failure(let error):
                    model.lastErrorMessage = error.localizedDescription
                }
            }

            Divider().frame(height: 20)

            Button {
                let demo = DemoDataProvider.sampleSeries()
                model.ingestSeries(demo)
                model.lastImportMessage = "Loaded demo dataset (\(demo.count) metrics)."
            } label: {
                Label("Load Demo Data", systemImage: "sparkles")
            }

            Button {
                if let url = DemoDataProvider.writeSampleCSV() {
                    model.lastImportMessage = "Exported demo CSV."
                    NotificationCenter.default.post(name: .exportDemoCSV, object: url)
                } else {
                    model.lastErrorMessage = "Failed to write demo CSV."
                }
            } label: {
                Label("Export Demo CSV", systemImage: "square.and.arrow.up")
            }
        }
    }
}

extension Notification.Name {
    static let exportDemoCSV = Notification.Name("exportDemoCSVNotification")
}
