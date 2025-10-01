//
//  KTPFieldExtractors.swift
//  Scan OCR KTP - Data Layer
//
//  Field extraction strategies following Strategy Pattern
//  Each extractor handles one specific field type
//
//  Created by Dicky Darmawan on 30/09/25.
//

import Foundation

// MARK: - Base Extractor with Shared Utilities

/// Base class providing common extraction utilities
class BaseKTPExtractor {
  
  // MARK: - Constants
  
  private let ktpLabels: [String] = [
    "NIK", "Nama", "Tempat/Tgl Lahir", "Jenis Kelamin", "Alamat", "RT/RW",
    "Kel/Desa", "Kecamatan", "Agama", "Status Perkawinan", "Pekerjaan",
    "Kewarganegaraan", "Berlaku Hingga", "Gol. Darah"
  ]
  
  // MARK: - Utility Methods
  
  /// Check if string is likely a label rather than a value
  func isLikelyLabel(_ text: String) -> Bool {
    let upper = text.trimmingCharacters(in: .whitespaces).uppercased()
    return ktpLabels.contains { upper.contains($0.uppercased()) }
  }
  
  /// Clean value after removing label (case-insensitive)
  func cleanedValue(after label: String, in text: String) -> String {
    var result = text
    result = result.replacingOccurrences(of: label, with: "", options: .caseInsensitive)
    result = result.replacingOccurrences(of: ":", with: "")
    return result.trimmingCharacters(in: .whitespaces)
  }
  
  /// Find value for label, checking same line and next line
  func valueForLabel(_ label: String, in lines: [String], startAt: Int = 0) -> String? {
    let upperLabel = label.uppercased()
    
    for i in startAt..<lines.count {
      let line = lines[i]
      guard line.uppercased().contains(upperLabel) else { continue }
      
      // Check same line
      let sameLine = cleanedValue(after: label, in: line)
      if !sameLine.isEmpty && !isLikelyLabel(sameLine) {
        return sameLine
      }
      
      // Check next line
      guard i + 1 < lines.count else { return nil }
      var nextLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
      if nextLine.hasPrefix(":") {
        nextLine = String(nextLine.dropFirst()).trimmingCharacters(in: .whitespaces)
      }
      if !nextLine.isEmpty && !isLikelyLabel(nextLine) {
        return nextLine
      }
      
      return nil
    }
    
    return nil
  }
  
  /// Extract date in format DD-MM-YYYY or DD/MM/YYYY
  func extractDate(from text: String) -> String? {
    guard let range = text.range(of: #"\b\d{1,2}[-/]\d{1,2}[-/]\d{4}\b"#, options: .regularExpression) else {
      return nil
    }
    return String(text[range])
  }
}

// MARK: - Specific Field Extractors

/// NIK (16-digit ID number) extractor
final class NIKExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "NIK"
  
  func extract(from lines: [String]) -> String? {
    for (i, line) in lines.enumerated() {
      // Match 16 digits directly
      if let match = line.range(of: #"\b\d{16}\b"#, options: .regularExpression) {
        return String(line[match])
      }
      
      // Check if line contains "NIK" label and next line has 16 digits
      if line.uppercased().contains("NIK") && i + 1 < lines.count {
        let digits = lines[i + 1].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if digits.count == 16 {
          return digits
        }
      }
    }
    return nil
  }
}

/// Name extractor
final class NamaExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "Nama"
  
  func extract(from lines: [String]) -> String? {
    return valueForLabel("Nama", in: lines)
  }
}

/// Place of birth extractor (from "Tempat/Tgl Lahir" field) using regex
final class TempatLahirExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "TempatLahir"

  // Regex pattern: captures place name before comma and date or just before date
  private let pattern = #"(?:TEMPAT[/\s]*TG[LI][.\s]*LAHIR)\s*:?\s*([A-Z\s]+?)(?:\s*,\s*|\s+)(?=\d{1,2}[-/]\d{1,2}[-/]\d{4})"#

  func extract(from lines: [String]) -> String? {
    // Join lines to handle multi-line cases
    let joinedText = lines.joined(separator: " ")

    // Try to match pattern in joined text with regex
    if let range = joinedText.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
      let match = String(joinedText[range])

      // Extract the place name after the colon and before date
      var place = match
        .replacingOccurrences(of: #"TEMPAT[/\s]*TG[LI][.\s]*LAHIR"#, with: "", options: [.regularExpression, .caseInsensitive])
        .replacingOccurrences(of: ":", with: "")
        .trimmingCharacters(in: .whitespaces)

      // Clean up trailing comma if any
      if place.hasSuffix(",") {
        place = String(place.dropLast()).trimmingCharacters(in: .whitespaces)
      }

      return place.isEmpty ? nil : place
    }

    // Fallback: use original logic with valueForLabel
    guard var value = valueForLabel("Tempat/Tgl Lahir", in: lines) ?? valueForLabel("Tempat/Tgi Lahir", in: lines) else {
      return nil
    }

    // Split by comma if present
    if let commaIndex = value.firstIndex(of: ",") {
      value = String(value[..<commaIndex]).trimmingCharacters(in: .whitespaces)
    }
    // Remove date if present
    else if let date = extractDate(from: value) {
      value = value.replacingOccurrences(of: date, with: "")
        .trimmingCharacters(in: .whitespaces)
        .trimmingCharacters(in: CharacterSet(charactersIn: ","))
    }

    return value.isEmpty ? nil : value
  }
}

/// Date of birth extractor
final class TanggalLahirExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "TanggalLahir"
  
  func extract(from lines: [String]) -> String? {
    // First check "Tempat/Tgl Lahir" field
    if let value = valueForLabel("Tempat/Tgl Lahir", in: lines),
       let date = extractDate(from: value) {
      return date
    }
    
    // Fallback: search all lines for date pattern
    for line in lines {
      if let date = extractDate(from: line) {
        return date
      }
    }
    
    return nil
  }
}

/// Gender extractor
final class JenisKelaminExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "JenisKelamin"
  
  private let maleKeywords = ["LAKI", "PRIA"]
  private let femaleKeywords = ["PEREMPUAN", "WANITA"]
  
  func extract(from lines: [String]) -> String? {
    guard let value = valueForLabel("Jenis Kelamin", in: lines) else {
      return nil
    }
    
    let upper = value.uppercased()
    
    if maleKeywords.contains(where: { upper.contains($0) }) {
      return "LAKI-LAKI"
    }
    
    if femaleKeywords.contains(where: { upper.contains($0) }) {
      return "PEREMPUAN"
    }
    
    return nil
  }
}

/// Address extractor
final class AlamatExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "Alamat"
  
  func extract(from lines: [String]) -> String? {
    return valueForLabel("Alamat", in: lines)
  }
}

/// RT/RW (neighborhood/hamlet) extractor
final class RTRWExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "RTRW"
  
  private let simplePattern = #"\b\d{2,3}/\d{2,3}\b"#
  private let fullPattern = #"RT\s*[:/]?\s*\d{2,3}\s*/\s*RW\s*[:/]?\s*\d{2,3}"#
  
  func extract(from lines: [String]) -> String? {
    for (i, line) in lines.enumerated() {
      // Pattern 1: Direct numbers like "007/008"
      if let range = line.range(of: simplePattern, options: .regularExpression) {
        return String(line[range])
      }
      
      // Pattern 2: Full format with "RT" and "RW" keywords
      if line.range(of: fullPattern, options: [.regularExpression, .caseInsensitive]) != nil {
        if let range = line.range(of: simplePattern, options: .regularExpression) {
          return String(line[range])
        }
      }
      
      // Pattern 3: Label on one line, value on next line
      if line.uppercased().contains("RT/RW") && i + 1 < lines.count {
        var nextLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
        if nextLine.hasPrefix(":") {
          nextLine = String(nextLine.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        if let range = nextLine.range(of: simplePattern, options: .regularExpression) {
          return String(nextLine[range])
        }
      }
    }
    
    return nil
  }
}

/// Village/Kelurahan extractor using regex
final class KelurahanExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "Kelurahan"

  // Regex pattern: matches "Kel/Desa", "KelDesa", "KelLesa", etc. with variations
  private let pattern = #"(?:KEL[/\s]*[DL]ESA|KELURAHAN)\s*:?\s*([A-Z\s]+?)(?=\s*$|\s+[A-Z]+\s*:|\s*,)"#

  func extract(from lines: [String]) -> String? {
    // Try regex pattern on each line
    for line in lines {
      if let range = line.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
        let match = String(line[range])

        // Extract the value after the label
        var value = match
          .replacingOccurrences(of: #"KEL[/\s]*[DL]ESA"#, with: "", options: [.regularExpression, .caseInsensitive])
          .replacingOccurrences(of: "KELURAHAN", with: "", options: .caseInsensitive)
          .replacingOccurrences(of: ":", with: "")
          .trimmingCharacters(in: .whitespaces)

        if !value.isEmpty && !isLikelyLabel(value) {
          return value
        }
      }
    }

    // Fallback: use original logic with valueForLabel
    if let value = valueForLabel("Kel/Desa", in: lines) {
      return value
    }

    if let value = valueForLabel("KelDesa", in: lines) {
      return value
    }

    if let value = valueForLabel("KelLesa", in: lines) {
      return value
    }

    if let value = valueForLabel("Kelurahan", in: lines) {
      return value
    }

    return nil
  }
}

/// District/Kecamatan extractor
final class KecamatanExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "Kecamatan"
  
  func extract(from lines: [String]) -> String? {
    // Primary pattern: "Kecamatan"
    if let value = valueForLabel("Kecamatan", in: lines) {
      return value
    }
    
    // Fallback: abbreviated "KEC"
    for (i, line) in lines.enumerated() where line.uppercased().contains("KEC") {
      let cleaned = line
        .replacingOccurrences(of: "KECAMATAN", with: "", options: .caseInsensitive)
        .replacingOccurrences(of: "KEC", with: "", options: .caseInsensitive)
        .replacingOccurrences(of: ":", with: "")
        .trimmingCharacters(in: .whitespaces)
      
      if !cleaned.isEmpty && !isLikelyLabel(cleaned) {
        return cleaned
      }
      
      // Check next line
      if i + 1 < lines.count {
        var nextLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
        if nextLine.hasPrefix(":") {
          nextLine = String(nextLine.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        if !nextLine.isEmpty && !isLikelyLabel(nextLine) {
          return nextLine
        }
      }
    }
    
    return nil
  }
}

/// Religion extractor
final class AgamaExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "Agama"
  
  private let validReligions = ["ISLAM", "KRISTEN", "KATOLIK", "HINDU", "BUDDHA", "KONGHUCU"]
  
  func extract(from lines: [String]) -> String? {
    for line in lines {
      let upperLine = line.uppercased()
      for religion in validReligions where upperLine.contains(religion) {
        return religion
      }
    }
    return nil
  }
}

/// Marital status extractor
final class StatusPerkawinanExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "StatusPerkawinan"
  
  func extract(from lines: [String]) -> String? {
    // Check label-based extraction first
    if let value = valueForLabel("Status Perkawinan", in: lines) {
      return normalizeMaritalStatus(value)
    }
    
    // Fallback: search all lines
    for line in lines {
      let upper = line.uppercased()
      if upper.contains("STATUS") || upper.contains("KAWIN") || upper.contains("CERAI") {
        if let normalized = normalizeMaritalStatus(upper) {
          return normalized
        }
      }
    }
    
    return nil
  }
  
  private func normalizeMaritalStatus(_ text: String) -> String? {
    let upper = text.uppercased()
    
    if upper.contains("BELUM") {
      return "BELUM KAWIN"
    }
    
    if upper.contains("KAWIN") && !upper.contains("BELUM") {
      return "KAWIN"
    }
    
    if upper.contains("CERAI") {
      return "CERAI"
    }
    
    return nil
  }
}

/// Occupation extractor
final class PekerjaanExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "Pekerjaan"
  
  func extract(from lines: [String]) -> String? {
    return valueForLabel("Pekerjaan", in: lines)
  }
}

/// Citizenship extractor
final class KewarganegaraanExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "Kewarganegaraan"
  
  func extract(from lines: [String]) -> String? {
    for line in lines {
      let upper = line.uppercased()
      if upper.contains("KEWARGANEGARAAN") || upper.contains("WNI") || upper.contains("WNA") {
        if upper.contains("WNI") {
          return "WNI"
        }
        if upper.contains("WNA") {
          return "WNA"
        }
      }
    }
    return nil
  }
}

/// Valid until extractor
final class BerlakuHinggaExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "BerlakuHingga"
  
  func extract(from lines: [String]) -> String? {
    let newLines = lines.map(\.localizedUppercase).joined(separator: " ")
    
    if newLines.contains("SEUMUR HIDUP") {
      return "SEUMUR HIDUP"
    }
    
    for (i, line) in lines.enumerated() {
      guard line.uppercased().contains("BERLAKU") else { continue }

      // Check for date on same line
      if let date = extractDate(from: line) {
        return date
      }
      
      // Check next line for date
      if i + 1 < lines.count, let date = extractDate(from: lines[i + 1]) {
        return date
      }
    }
    
    return nil
  }
}

/// Blood type extractor using regex (includes +/- if present)
final class GolonganDarahExtractor: BaseKTPExtractor, KTPFieldExtractionStrategy {
  let fieldName = "GolonganDarah"

  // Regex pattern: matches "GOL. DARAH" followed by ":" and blood type or "-" for empty
  private let pattern = #"(?:GOL\.?\s*DARAH)\s*:\s*(A(?:\+|-)?|B(?:\+|-)?|AB(?:\+|-)?|O(?:\+|-)?|-)"#

  func extract(from lines: [String]) -> String? {
    // Check each line individually - MUST contain "DARAH" keyword
    for line in lines {
      let upperLine = line.uppercased()

      // MUST contain "DARAH" keyword to be valid blood type line
      guard upperLine.contains("DARAH") else { continue }

      // MUST NOT contain "ALAMAT" or other field names
      guard !upperLine.contains("ALAMAT") && !upperLine.contains("AGAMA") else { continue }

      // Extract blood type from this specific line using regex
      if let range = line.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
        let match = String(line[range])

        // Extract just the blood type value after colon
        if let bloodTypeRange = match.range(of: #":\s*(A(?:\+|-)?|B(?:\+|-)?|AB(?:\+|-)?|O(?:\+|-)?|-)"#, options: .regularExpression) {
          let bloodType = String(match[bloodTypeRange])
            .replacingOccurrences(of: ":", with: "")
            .trimmingCharacters(in: .whitespaces)

          // Return "-" if blood type is empty/dash, otherwise return the blood type
          return bloodType.isEmpty ? "-" : bloodType
        }
      }
    }

    return nil
  }
}
