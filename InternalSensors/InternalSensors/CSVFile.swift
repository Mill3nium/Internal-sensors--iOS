//
//  CSVFile.swift
//  InternalSensors
//
//  Created by Leo Zaki on 2021-12-11.
//

import Foundation
import CSV
import SwiftUI
import UniformTypeIdentifiers

struct CSVFile: FileDocument {
    // tell the system we support only plain text
    static var readableContentTypes = [UTType.commaSeparatedText]

    // by default our document is empty
    private let csv: CSVWriter
    
    func write(_ time: UInt32, _ ax: Float, _ ay: Float, _ az: Float, _ gx: Float, _ gy: Float, _ gz: Float) {
        try! csv.write(row: ["\(ax)", "\(ay)", "\(az)", "\(gx)", "\(gy)", "\(gz)"])
    }
    func write(_ time: Date, _ ax: Double, _ ay: Double, _ az: Double, _ gx: Double, _ gy: Double, _ gz: Double) {
        try! csv.write(row: [
            "\(time.timeIntervalSince1970)",
            "\(ax)",
            "\(ay)",
            "\(az)",
            "\(gx)",
            "\(gy)",
            "\(gz)"
        ])
    }
    
    init() {
        csv = try! CSVWriter(stream: .toMemory())
        try! csv.write(row: ["ax", "ay", "az", "gx", "gy", "gz"])
    }

    // this initializer loads data that has been saved previously
    init(configuration: ReadConfiguration) throws {
//            if let data = configuration.file.regularFileContents {
//
//            }
        throw CSVError.cannotReadFile
    }

    // this will be called when the system wants to write our data to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let csvData = csv.stream.property(forKey: .dataWrittenToMemoryStreamKey) as! Data
        return FileWrapper(regularFileWithContents: csvData)
    }
}
