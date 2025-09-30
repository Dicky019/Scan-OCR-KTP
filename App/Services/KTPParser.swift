//
//  KTPParser.swift
//  Scan OCR KTP
//
//  Versi lengkap – diperkuat agar robust terhadap layout KTP: nilai sering berada di baris berikutnya setelah label.
//  Menambahkan helper valueForLabel(), findDate(), normalisasi pembersihan label case-insensitive,
//  ekstraksi Tempat/Tgl Lahir menjadi dua field, dan RT/RW yang mendukung pola di baris berikut.
//

import Foundation

class KTPParser {
  private let logger = OCRLogger.shared

  // MARK: - Public API
  func parseKTPData(from text: String, confidence: Double, engine: OCREngine, processingTime: Double, sessionId: String? = nil) -> KTPData {
    logger.logProcess("Starting KTP data parsing", details: "Engine: \(engine.rawValue), Text length: \(text.count), Text: \(text)", sessionId: sessionId)

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

  // MARK: - Helpers
  private let ktpLabels: [String] = [
    "NIK","Nama","Tempat/Tgl Lahir","Jenis Kelamin","Alamat","RT/RW",
    "Kel/Desa","Kecamatan","Agama","Status Perkawinan","Pekerjaan",
    "Kewarganegaraan","Berlaku Hingga","Gol. Darah"
  ]

  private func isLikelyLabel(_ s: String) -> Bool {
    let upper = s.trimmingCharacters(in: .whitespaces).uppercased()
    return ktpLabels.contains { upper.contains($0.uppercased()) }
  }

  // Bersihkan nilai setelah label (case-insensitive) dan buang ':'
  private func cleanedValueAfterLabel(_ raw: String, label: String) -> String {
    var s = raw
    s = s.replacingOccurrences(of: label, with: "", options: .caseInsensitive)
    s = s.replacingOccurrences(of: ":", with: "")
    return s.trimmingCharacters(in: .whitespaces)
  }

  // Ambil nilai di baris label; jika kosong/masih label, coba baris berikutnya
  private func valueForLabel(_ label: String, in lines: [String], startAt: Int = 0) -> String? {
    let upperLabel = label.uppercased()
    for i in startAt..<lines.count {
      let line = lines[i]
      if line.uppercased().contains(upperLabel) {
        let sameLine = cleanedValueAfterLabel(line, label: label)
        if !sameLine.isEmpty, !isLikelyLabel(sameLine) { return sameLine }
        let j = i + 1
        if j < lines.count {
          var next = lines[j].trimmingCharacters(in: .whitespaces)
          if next.hasPrefix(":") { next = String(next.dropFirst()).trimmingCharacters(in: .whitespaces) }
          if !next.isEmpty, !isLikelyLabel(next) { return next }
        }
        return nil
      }
    }
    return nil
  }

  // Temukan tanggal (DD-MM-YYYY / DD/MM/YYYY)
  private func findDate(in s: String) -> String? {
    if let r = s.range(of: #"\b\d{1,2}[-/]\d{1,2}[-/]\d{4}\b"#, options: .regularExpression) {
      return String(s[r])
    }
    return nil
  }

  // MARK: - Field Extraction Methods
  private func extractNIK(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
    for (i, line) in lines.enumerated() {
      // 16 digit di baris mana pun
      if let match = line.range(of: #"\b\d{16}\b"#, options: .regularExpression) {
        let result = String(line[match])
        logger.logFieldExtraction(field: "NIK", value: result, success: true, sessionId: sessionId)
        return result
      }
      // Jika ada kata NIK diikuti baris berikutnya berisi angka
      if line.uppercased().contains("NIK"), i + 1 < lines.count {
        let digits = lines[i + 1].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
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
    if let v = valueForLabel("Nama", in: lines) {
      logger.logFieldExtraction(field: "Nama", value: v, success: true, sessionId: sessionId)
      return v
    }
    logger.logFieldExtraction(field: "Nama", value: nil, success: false, sessionId: sessionId)
    return nil
  }

  private func extractTempatLahir(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
    guard var v = valueForLabel("Tempat/Tgl Lahir", in: lines) else {
      logger.logFieldExtraction(field: "TempatLahir", value: nil, success: false, sessionId: sessionId)
      return nil
    }
    if let comma = v.firstIndex(of: ",") {
      v = String(v[..<comma]).trimmingCharacters(in: .whitespaces)
    } else if let date = findDate(in: v) {
      v = v.replacingOccurrences(of: date, with: "").trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: ","))
    }
    let result = v.isEmpty ? nil : v
    logger.logFieldExtraction(field: "TempatLahir", value: result, success: result != nil, sessionId: sessionId)
    return result
  }

  private func extractTanggalLahir(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
    if let v = valueForLabel("Tempat/Tgl Lahir", in: lines), let date = findDate(in: v) {
      logger.logFieldExtraction(field: "TanggalLahir", value: date, success: true, sessionId: sessionId)
      return date
    }
    for line in lines { // fallback
      if let date = findDate(in: line) {
        logger.logFieldExtraction(field: "TanggalLahir", value: date, success: true, sessionId: sessionId)
        return date
      }
    }
    logger.logFieldExtraction(field: "TanggalLahir", value: nil, success: false, sessionId: sessionId)
    return nil
  }

  private func extractJenisKelamin(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
    if let v = valueForLabel("Jenis Kelamin", in: lines) {
      let upper = v.uppercased()
      let result: String?
      if upper.contains("LAKI") || upper.contains("PRIA") { result = "LAKI-LAKI" }
      else if upper.contains("PEREMPUAN") || upper.contains("WANITA") { result = "PEREMPUAN" }
      else { result = nil }
      logger.logFieldExtraction(field: "JenisKelamin", value: result, success: result != nil, sessionId: sessionId)
      return result
    }
    logger.logFieldExtraction(field: "JenisKelamin", value: nil, success: false, sessionId: sessionId)
    return nil
  }

  private func extractAlamat(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
    if let v = valueForLabel("Alamat", in: lines) {
      logger.logFieldExtraction(field: "Alamat", value: v, success: true, sessionId: sessionId)
      return v
    }
    logger.logFieldExtraction(field: "Alamat", value: nil, success: false, sessionId: sessionId)
    return nil
  }

  private func extractRTRW(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
    let simplePattern = #"\b\d{2,3}/\d{2,3}\b"#
    let fullPattern = #"RT\s*[:/]?\s*\d{2,3}\s*/\s*RW\s*[:/]?\s*\d{2,3}"#

    for (i, line) in lines.enumerated() {
      // 1) baris yang langsung berisi angka "007/008"
      if let r = line.range(of: simplePattern, options: .regularExpression) {
        let val = String(line[r])
        logger.logFieldExtraction(field: "RTRW", value: val, success: true, sessionId: sessionId)
        return val
      }
      // 2) baris gaya lengkap dengan kata RT/RW
      if let _ = line.range(of: fullPattern, options: [.regularExpression, .caseInsensitive]) {
        if let r2 = line.range(of: simplePattern, options: .regularExpression) {
          let val = String(line[r2])
          logger.logFieldExtraction(field: "RTRW", value: val, success: true, sessionId: sessionId)
          return val
        }
      }
      // 3) label RT/RW lalu nilai di baris berikutnya
      if line.uppercased().contains("RT/RW"), i + 1 < lines.count {
        var next = lines[i + 1].trimmingCharacters(in: .whitespaces)
        if next.hasPrefix(":") { next = String(next.dropFirst()).trimmingCharacters(in: .whitespaces) }
        if let r = next.range(of: simplePattern, options: .regularExpression) {
          let val = String(next[r])
          logger.logFieldExtraction(field: "RTRW", value: val, success: true, sessionId: sessionId)
          return val
        }
      }
    }

    logger.logFieldExtraction(field: "RTRW", value: nil, success: false, sessionId: sessionId)
    return nil
  }

  private func extractKelurahan(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
    if let v = valueForLabel("Kel/Desa", in: lines) {
      logger.logFieldExtraction(field: "Kelurahan", value: v, success: true, sessionId: sessionId)
      return v
    }
    // fallback pola alternatif “KELURAHAN”
    if let v2 = valueForLabel("Kelurahan", in: lines) {
      logger.logFieldExtraction(field: "Kelurahan", value: v2, success: true, sessionId: sessionId)
      return v2
    }
    logger.logFieldExtraction(field: "Kelurahan", value: nil, success: false, sessionId: sessionId)
    return nil
  }

  private func extractKecamatan(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
    if let v = valueForLabel("Kecamatan", in: lines) {
      logger.logFieldExtraction(field: "Kecamatan", value: v, success: true, sessionId: sessionId)
      return v
    }
    // fallback singkatan “KEC”
    for (i, line) in lines.enumerated() where line.uppercased().contains("KEC") {
      let cleaned = line
        .replacingOccurrences(of: "KECAMATAN", with: "", options: .caseInsensitive)
        .replacingOccurrences(of: "KEC", with: "", options: .caseInsensitive)
        .replacingOccurrences(of: ":", with: "")
        .trimmingCharacters(in: .whitespaces)
      if !cleaned.isEmpty, !isLikelyLabel(cleaned) {
        logger.logFieldExtraction(field: "Kecamatan", value: cleaned, success: true, sessionId: sessionId)
        return cleaned
      }
      if i + 1 < lines.count {
        var next = lines[i + 1].trimmingCharacters(in: .whitespaces)
        if next.hasPrefix(":") { next = String(next.dropFirst()).trimmingCharacters(in: .whitespaces) }
        if !next.isEmpty, !isLikelyLabel(next) {
          logger.logFieldExtraction(field: "Kecamatan", value: next, success: true, sessionId: sessionId)
          return next
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
      for religion in religions where upperLine.contains(religion) {
        logger.logFieldExtraction(field: "Agama", value: religion, success: true, sessionId: sessionId)
        return religion
      }
    }
    logger.logFieldExtraction(field: "Agama", value: nil, success: false, sessionId: sessionId)
    return nil
  }

  private func extractStatusPerkawinan(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
    if let v = valueForLabel("Status Perkawinan", in: lines) {
      let upper = v.uppercased()
      var result: String? = nil
      if upper.contains("BELUM") { result = "BELUM KAWIN" }
      else if upper.contains("KAWIN") { result = "KAWIN" }
      else if upper.contains("CERAI") { result = "CERAI" }
      logger.logFieldExtraction(field: "StatusPerkawinan", value: result, success: result != nil, sessionId: sessionId)
      return result
    }
    // fallback cari kata kunci di mana pun
    for line in lines {
      let upper = line.uppercased()
      if upper.contains("STATUS") || upper.contains("KAWIN") || upper.contains("CERAI") {
        if upper.contains("BELUM") { logger.logFieldExtraction(field: "StatusPerkawinan", value: "BELUM KAWIN", success: true, sessionId: sessionId); return "BELUM KAWIN" }
        if upper.contains("KAWIN") && !upper.contains("BELUM") { logger.logFieldExtraction(field: "StatusPerkawinan", value: "KAWIN", success: true, sessionId: sessionId); return "KAWIN" }
        if upper.contains("CERAI") { logger.logFieldExtraction(field: "StatusPerkawinan", value: "CERAI", success: true, sessionId: sessionId); return "CERAI" }
      }
    }
    logger.logFieldExtraction(field: "StatusPerkawinan", value: nil, success: false, sessionId: sessionId)
    return nil
  }

  private func extractPekerjaan(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
    if let v = valueForLabel("Pekerjaan", in: lines) {
      logger.logFieldExtraction(field: "Pekerjaan", value: v, success: true, sessionId: sessionId)
      return v
    }
    logger.logFieldExtraction(field: "Pekerjaan", value: nil, success: false, sessionId: sessionId)
    return nil
  }

  private func extractKewarganegaraan(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
    for line in lines {
      let upper = line.uppercased()
      if upper.contains("KEWARGANEGARAAN") || upper.contains("WNI") || upper.contains("WNA") {
        if upper.contains("WNI") { logger.logFieldExtraction(field: "Kewarganegaraan", value: "WNI", success: true, sessionId: sessionId); return "WNI" }
        if upper.contains("WNA") { logger.logFieldExtraction(field: "Kewarganegaraan", value: "WNA", success: true, sessionId: sessionId); return "WNA" }
      }
    }
    logger.logFieldExtraction(field: "Kewarganegaraan", value: nil, success: false, sessionId: sessionId)
    return nil
  }

  private func extractBerlakuHingga(from lines: [String], engine: OCREngine, sessionId: String? = nil) -> String? {
    for (i, line) in lines.enumerated() {
      if line.uppercased().contains("BERLAKU") {
        if line.uppercased().contains("SEUMUR HIDUP") {
          logger.logFieldExtraction(field: "BerlakuHingga", value: "SEUMUR HIDUP", success: true, sessionId: sessionId)
          return "SEUMUR HIDUP"
        }
        if let d = findDate(in: line) {
          logger.logFieldExtraction(field: "BerlakuHingga", value: d, success: true, sessionId: sessionId)
          return d
        }
        if i + 1 < lines.count, let d2 = findDate(in: lines[i + 1]) {
          logger.logFieldExtraction(field: "BerlakuHingga", value: d2, success: true, sessionId: sessionId)
          return d2
        }
      }
    }
    logger.logFieldExtraction(field: "BerlakuHingga", value: nil, success: false, sessionId: sessionId)
    return nil
  }
}
