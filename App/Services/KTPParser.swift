//
//  KTPParser.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import Foundation

class KTPParser {
    private let logger = OCRLogger.shared

    func parseKTPData(from text: String, confidence: Double, engine: OCREngine, processingTime: Double, sessionId: String? = nil) -> KTPData {
        logger.logProcess("Starting KTP data parsing", details: "Engine: \(engine.rawValue), Text length: \(text.count)", sessionId: sessionId)

        let parsingOperationId = logger.logPerformanceStart("KTP_Field_Extraction", engine: engine, sessionId: sessionId)

        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        logger.logProcess("Text preprocessing complete", details: "\(lines.count) lines to process", sessionId: sessionId)
        logger.logPerformanceMetric("text_lines_count", value: Double(lines.count), engine: engine, sessionId: sessionId)

        // Extract all fields with logging
        let nik = extractNIK(from: lines, engine: engine, sessionId: sessionId)
        let nama = extractNama(from: lines, engine: engine, sessionId: sessionId)
        let tempatLahir = extractTempatLahir(from: lines, engine: engine, sessionId: sessionId)
        let tanggalLahir = extractTanggalLahir(from: lines, engine: engine, sessionId: sessionId)
        let jenisKelamin = extractJenisKelamin(from: lines, engine: engine, sessionId: sessionId)
        let alamat = extractAlamat(from: lines, engine: engine, sessionId: sessionId)
        let rtRw = extractRTRW(from: lines, engine: engine, sessionId: sessionId)
        let kelurahan = extractKelurahan(from: lines, engine: engine, sessionId: sessionId)
        let kecamatan = extractKecamatan(from: lines, engine: engine, sessionId: sessionId)
        let agama = extractAgama(from: lines, engine: engine, sessionId: sessionId)
        let statusPerkawinan = extractStatusPerkawinan(from: lines, engine: engine, sessionId: sessionId)
        let pekerjaan = extractPekerjaan(from: lines, engine: engine, sessionId: sessionId)
        let kewarganegaraan = extractKewarganegaraan(from: lines, engine: engine, sessionId: sessionId)
        let berlakuHingga = extractBerlakuHingga(from: lines, engine: engine, sessionId: sessionId)

        // Calculate extraction success rate
        let extractedFields = [nik, nama, tempatLahir, tanggalLahir, jenisKelamin, alamat, rtRw, kelurahan, kecamatan, agama, statusPerkawinan, pekerjaan, kewarganegaraan, berlakuHingga]
        let successfulExtractions = extractedFields.compactMap { $0 }.count
        let totalFields = extractedFields.count
        let extractionRate = Double(successfulExtractions) / Double(totalFields)

        logger.logPerformanceMetric("extraction_success_rate", value: extractionRate, engine: engine, sessionId: sessionId)
        logger.logPerformanceMetric("extracted_fields_count", value: Double(successfulExtractions), engine: engine, sessionId: sessionId)
        logger.logPerformanceMetric("total_fields_count", value: Double(totalFields), engine: engine, sessionId: sessionId)

        logger.logPerformanceEnd(parsingOperationId, sessionId: sessionId, result: "\(successfulExtractions)/\(totalFields) fields extracted")

        logger.logSuccess("KTP parsing complete", details: "Success rate: \(String(format: "%.1f", extractionRate * 100))% (\(successfulExtractions)/\(totalFields))", sessionId: sessionId)

        return KTPData(
            nik: nik,
            nama: nama,
            tempatLahir: tempatLahir,
            tanggalLahir: tanggalLahir,
            jenisKelamin: jenisKelamin,
            alamat: alamat,
            rtRw: rtRw,
            kelurahan: kelurahan,
            kecamatan: kecamatan,
            agama: agama,
            statusPerkawinan: statusPerkawinan,
            pekerjaan: pekerjaan,
            kewarganegaraan: kewarganegaraan,
            berlakuHingga: berlakuHingga,
            rawText: text,
            confidence: confidence,
            ocrEngine: engine,
            processingTime: processingTime
        )
    }

    // MARK: - Field Extraction Methods

    private func extractNIK(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for line in lines {
            // Look for 16-digit number (NIK format)
            if let match = line.range(of: #"\b\d{16}\b"#, options: .regularExpression) {
                let result = String(line[match])
                logger.logFieldExtraction(field: "NIK", value: result, success: true, sessionId: sessionId)
                return result
            }
            // Also check lines that contain "NIK"
            if line.uppercased().contains("NIK") {
                let digits = line.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                if digits.count == 16 {
                    logger.logFieldExtraction(field: "NIK", value: digits, success: true, sessionId: sessionId)
                    return digits
                }
            }
        }
        logger.logFieldExtraction(field: "NIK", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractNama(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for (index, line) in lines.enumerated() {
            if line.uppercased().contains("NAMA") {
                // Look for name in the same line or next line
                let namePatterns = [line, index + 1 < lines.count ? lines[index + 1] : ""]
                for pattern in namePatterns {
                    let cleanedLine = pattern.replacingOccurrences(of: "NAMA", with: "")
                        .replacingOccurrences(of: ":", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    if !cleanedLine.isEmpty && cleanedLine.count > 2 {
                        logger.logFieldExtraction(field: "Nama", value: cleanedLine, success: true, sessionId: sessionId)
                        return cleanedLine
                    }
                }
            }
        }
        logger.logFieldExtraction(field: "Nama", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractTempatLahir(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for line in lines {
            if line.uppercased().contains("TEMPAT") || line.uppercased().contains("TGL") || line.uppercased().contains("LAHIR") {
                // Extract city name before comma
                if let commaRange = line.range(of: ",") {
                    let place = String(line[..<commaRange.lowerBound])
                        .replacingOccurrences(of: "TEMPAT/TGL LAHIR", with: "")
                        .replacingOccurrences(of: ":", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    if !place.isEmpty {
                        logger.logFieldExtraction(field: "TempatLahir", value: place, success: true, sessionId: sessionId)
                        return place
                    }
                }
            }
        }
        logger.logFieldExtraction(field: "TempatLahir", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractTanggalLahir(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for line in lines {
            // Look for date patterns: DD-MM-YYYY or DD/MM/YYYY
            if let match = line.range(of: #"\b\d{1,2}[-/]\d{1,2}[-/]\d{4}\b"#, options: .regularExpression) {
                let result = String(line[match])
                logger.logFieldExtraction(field: "TanggalLahir", value: result, success: true, sessionId: sessionId)
                return result
            }
        }
        logger.logFieldExtraction(field: "TanggalLahir", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractJenisKelamin(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for line in lines {
            let upperLine = line.uppercased()
            if upperLine.contains("JENIS KELAMIN") || upperLine.contains("KEL") {
                if upperLine.contains("LAKI") || upperLine.contains("PRIA") {
                    logger.logFieldExtraction(field: "JenisKelamin", value: "LAKI-LAKI", success: true, sessionId: sessionId)
                    return "LAKI-LAKI"
                } else if upperLine.contains("PEREMPUAN") || upperLine.contains("WANITA") {
                    logger.logFieldExtraction(field: "JenisKelamin", value: "PEREMPUAN", success: true, sessionId: sessionId)
                    return "PEREMPUAN"
                }
            }
        }
        logger.logFieldExtraction(field: "JenisKelamin", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractAlamat(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for (index, line) in lines.enumerated() {
            if line.uppercased().contains("ALAMAT") {
                let alamatLine = line.replacingOccurrences(of: "ALAMAT", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)

                // If current line has content, use it; otherwise check next line
                if !alamatLine.isEmpty {
                    logger.logFieldExtraction(field: "Alamat", value: alamatLine, success: true, sessionId: sessionId)
                    return alamatLine
                } else if index + 1 < lines.count {
                    let nextLine = lines[index + 1]
                    logger.logFieldExtraction(field: "Alamat", value: nextLine, success: true, sessionId: sessionId)
                    return nextLine
                }
            }
        }
        logger.logFieldExtraction(field: "Alamat", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractRTRW(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for line in lines {
            if let match = line.range(of: #"RT\s*[:/]?\s*\d+\s*/?\s*RW\s*[:/]?\s*\d+"#, options: [.regularExpression, .caseInsensitive]) {
                let result = String(line[match])
                logger.logFieldExtraction(field: "RTRW", value: result, success: true, sessionId: sessionId)
                return result
            }
        }
        logger.logFieldExtraction(field: "RTRW", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractKelurahan(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for line in lines {
            if line.uppercased().contains("KEL") && !line.uppercased().contains("KELAMIN") {
                let cleaned = line.replacingOccurrences(of: "KEL/DESA", with: "")
                    .replacingOccurrences(of: "KELURAHAN", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !cleaned.isEmpty {
                    logger.logFieldExtraction(field: "Kelurahan", value: cleaned, success: true, sessionId: sessionId)
                    return cleaned
                }
            }
        }
        logger.logFieldExtraction(field: "Kelurahan", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractKecamatan(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for line in lines {
            if line.uppercased().contains("KEC") {
                let cleaned = line.replacingOccurrences(of: "KECAMATAN", with: "")
                    .replacingOccurrences(of: "KEC", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !cleaned.isEmpty {
                    logger.logFieldExtraction(field: "Kecamatan", value: cleaned, success: true, sessionId: sessionId)
                    return cleaned
                }
            }
        }
        logger.logFieldExtraction(field: "Kecamatan", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractAgama(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        let religions = ["ISLAM", "KRISTEN", "KATOLIK", "HINDU", "BUDDHA", "KONGHUCU"]
        for line in lines {
            let upperLine = line.uppercased()
            for religion in religions {
                if upperLine.contains(religion) {
                    logger.logFieldExtraction(field: "Agama", value: religion, success: true, sessionId: sessionId)
                    return religion
                }
            }
        }
        logger.logFieldExtraction(field: "Agama", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractStatusPerkawinan(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for line in lines {
            let upperLine = line.uppercased()
            if upperLine.contains("STATUS") || upperLine.contains("KAWIN") {
                if upperLine.contains("BELUM") {
                    logger.logFieldExtraction(field: "StatusPerkawinan", value: "BELUM KAWIN", success: true, sessionId: sessionId)
                    return "BELUM KAWIN"
                } else if upperLine.contains("KAWIN") && !upperLine.contains("BELUM") {
                    logger.logFieldExtraction(field: "StatusPerkawinan", value: "KAWIN", success: true, sessionId: sessionId)
                    return "KAWIN"
                } else if upperLine.contains("CERAI") {
                    logger.logFieldExtraction(field: "StatusPerkawinan", value: "CERAI", success: true, sessionId: sessionId)
                    return "CERAI"
                }
            }
        }
        logger.logFieldExtraction(field: "StatusPerkawinan", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractPekerjaan(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for (index, line) in lines.enumerated() {
            if line.uppercased().contains("PEKERJAAN") {
                let pekerjaanLine = line.replacingOccurrences(of: "PEKERJAAN", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)

                if !pekerjaanLine.isEmpty {
                    logger.logFieldExtraction(field: "Pekerjaan", value: pekerjaanLine, success: true, sessionId: sessionId)
                    return pekerjaanLine
                } else if index + 1 < lines.count {
                    let nextLine = lines[index + 1]
                    logger.logFieldExtraction(field: "Pekerjaan", value: nextLine, success: true, sessionId: sessionId)
                    return nextLine
                }
            }
        }
        logger.logFieldExtraction(field: "Pekerjaan", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractKewarganegaraan(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for line in lines {
            let upperLine = line.uppercased()
            if upperLine.contains("KEWARGANEGARAAN") || upperLine.contains("WNI") || upperLine.contains("WNA") {
                if upperLine.contains("WNI") {
                    logger.logFieldExtraction(field: "Kewarganegaraan", value: "WNI", success: true, sessionId: sessionId)
                    return "WNI"
                } else if upperLine.contains("WNA") {
                    logger.logFieldExtraction(field: "Kewarganegaraan", value: "WNA", success: true, sessionId: sessionId)
                    return "WNA"
                }
            }
        }
        logger.logFieldExtraction(field: "Kewarganegaraan", value: nil, success: false, sessionId: sessionId)
        return nil
    }

    private func extractBerlakuHingga(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
        for line in lines {
            if line.uppercased().contains("BERLAKU") {
                if line.uppercased().contains("SEUMUR HIDUP") {
                    logger.logFieldExtraction(field: "BerlakuHingga", value: "SEUMUR HIDUP", success: true, sessionId: sessionId)
                    return "SEUMUR HIDUP"
                } else {
                    // Look for date pattern
                    if let match = line.range(of: #"\b\d{1,2}[-/]\d{1,2}[-/]\d{4}\b"#, options: .regularExpression) {
                        let result = String(line[match])
                        logger.logFieldExtraction(field: "BerlakuHingga", value: result, success: true, sessionId: sessionId)
                        return result
                    }
                }
            }
        }
        logger.logFieldExtraction(field: "BerlakuHingga", value: nil, success: false, sessionId: sessionId)
        return nil
    }
}