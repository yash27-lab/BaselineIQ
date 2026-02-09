//
//  AppleHealthImporter.swift
//  BaselineIQ
//
//  Created by Assistant on 2/8/26.
//

import Foundation

enum AppleHealthImporter {
    enum HealthExportError: Error { case zipNotSupported }

    // Parse unzipped Apple Health export: export.xml
    // We support a subset of HKQuantityTypeIdentifiers
    static func parseExportXML(url: URL) throws -> [MetricSeries] {
        if url.pathExtension.lowercased() == "zip" { throw HealthExportError.zipNotSupported }
        let data = try Data(contentsOf: url)
        let parser = HealthXMLParser()
        return parser.parse(data: data)
    }
}

private final class HealthXMLParser: NSObject, XMLParserDelegate {
    private var currentElement: String = ""
    private var records: [MetricType: [TimeSeriesPoint]] = [:]

    func parse(data: Data) -> [MetricSeries] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return records.map { MetricSeries(metric: $0.key, points: $0.value) }
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "Record" {
            guard let type = attributeDict["type"],
                  let valueStr = attributeDict["value"],
                  let start = attributeDict["startDate"] else { return }
            guard let date = isoDate(start) else { return }
            guard var value = Double(valueStr) else { return }

            // Unit conversions where needed
            if type == "HKQuantityTypeIdentifierBloodGlucose", let unit = attributeDict["unit"]?.lowercased() {
                if unit.contains("mmol") {
                    // mmol/L to mg/dL
                    value *= 18.0
                }
            }
            if type == "HKQuantityTypeIdentifierBodyMass", let unit = attributeDict["unit"]?.lowercased() {
                if unit.contains("lb") {
                    // pounds to kilograms
                    value *= 0.45359237
                }
            }

            if let metric = mapHKType(to: type, attributes: attributeDict, value: value) {
                records[metric, default: []].append(TimeSeriesPoint(date: date, value: value))
            }
        }
    }

    private func isoDate(_ s: String) -> Date? {
        // Apple Health export uses ISO8601 with timezone
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        let g = ISO8601DateFormatter(); g.formatOptions = [.withInternetDateTime]
        return g.date(from: s)
    }

    private func mapHKType(to hkType: String, attributes: [String: String], value: Double) -> MetricType? {
        switch hkType {
        case "HKQuantityTypeIdentifierRestingHeartRate":
            return .restingHeartRate
        case "HKQuantityTypeIdentifierOxygenSaturation":
            return .oxygenSaturation
        case "HKQuantityTypeIdentifierBodyMass":
            return .weight
        case "HKQuantityTypeIdentifierBloodGlucose":
            return .glucose
        case "HKQuantityTypeIdentifierBloodPressureSystolic":
            return .bloodPressureSystolic
        case "HKQuantityTypeIdentifierBloodPressureDiastolic":
            return .bloodPressureDiastolic
        case "HKCategoryTypeIdentifierSleepAnalysis":
            return nil
        default:
            return nil
        }
    }
}
