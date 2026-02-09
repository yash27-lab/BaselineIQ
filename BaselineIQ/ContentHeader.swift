//
//  ContentHeader.swift
//  BaselineIQ
//
//  Created by Assistant on 2/8/26.
//

import SwiftUI
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif

struct ContentHeader: View {
    @EnvironmentObject var model: AppModel
    @State private var isExporting = false
    @State private var exportSuccess: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("BaselineIQ")
                    .font(.largeTitle).bold()
                Spacer()
                Button {
                    exportPDF()
                } label: {
                    Label("Export PDF", systemImage: "arrow.down.doc")
                }
                .disabled(model.seriesByMetric.isEmpty || isExporting)
            }
            Text("Local-only processing. Upload CSV or Apple Health export.xml. BaselineIQ highlights potential drift across vitals and labs. Not medical advice.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let msg = model.lastImportMessage {
                Text(msg).font(.footnote).foregroundStyle(.green)
            }
            if let err = model.lastErrorMessage {
                Text(err).font(.footnote).foregroundStyle(.red)
            }
            if let success = exportSuccess {
                Text(success).font(.footnote).foregroundStyle(.blue)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportDemoCSV)) { output in
            if let url = output.object as? URL {
                shareFile(url: url)
            }
        }
    }
    
    private func exportPDF() {
        #if canImport(AppKit)
        isExporting = true
        exportSuccess = nil
        
        // Generate the PDF first
        guard let tempURL = model.generatePDF() else {
            model.lastErrorMessage = "Failed to generate PDF"
            isExporting = false
            return
        }
        
        // Show save panel
        let savePanel = NSSavePanel()
        savePanel.title = "Export BaselineIQ Summary"
        savePanel.nameFieldStringValue = "BaselineIQ_Summary.pdf"
        savePanel.allowedContentTypes = [.pdf]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        
        savePanel.begin { response in
            defer { isExporting = false }
            
            if response == .OK, let destinationURL = savePanel.url {
                do {
                    // Remove existing file if present
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    // Copy the generated PDF to the chosen location
                    try FileManager.default.copyItem(at: tempURL, to: destinationURL)
                    
                    DispatchQueue.main.async {
                        exportSuccess = "PDF exported to \(destinationURL.lastPathComponent)"
                        
                        // Clear success message after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            exportSuccess = nil
                        }
                    }
                    
                    // Optionally reveal in Finder
                    NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
                    
                } catch {
                    DispatchQueue.main.async {
                        model.lastErrorMessage = "Failed to save PDF: \(error.localizedDescription)"
                    }
                }
            }
        }
        #endif
    }
    
    private func shareFile(url: URL) {
        #if canImport(AppKit)
        guard let window = NSApplication.shared.keyWindow,
              let contentView = window.contentView else { return }
        let picker = NSSharingServicePicker(items: [url])
        picker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        #endif
    }
}
