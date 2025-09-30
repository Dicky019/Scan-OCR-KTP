//
//  KTPData.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import Foundation

struct KTPData {
  let nik: String?
  let nama: String?
  let tempatLahir: String?
  let tanggalLahir: String?
  let jenisKelamin: String?
  let alamat: String?
  let rtRw: String?
  let kelurahan: String?
  let kecamatan: String?
  let agama: String?
  let statusPerkawinan: String?
  let pekerjaan: String?
  let kewarganegaraan: String?
  let berlakuHingga: String?
  let rawText: String
  let confidence: Double
  let ocrEngine: OCREngine
  let processingTime: Double
  
  init(
    nik: String? = nil,
    nama: String? = nil,
    tempatLahir: String? = nil,
    tanggalLahir: String? = nil,
    jenisKelamin: String? = nil,
    alamat: String? = nil,
    rtRw: String? = nil,
    kelurahan: String? = nil,
    kecamatan: String? = nil,
    agama: String? = nil,
    statusPerkawinan: String? = nil,
    pekerjaan: String? = nil,
    kewarganegaraan: String? = nil,
    berlakuHingga: String? = nil,
    rawText: String,
    confidence: Double,
    ocrEngine: OCREngine,
    processingTime: Double
  ) {
    self.nik = nik
    self.nama = nama
    self.tempatLahir = tempatLahir
    self.tanggalLahir = tanggalLahir
    self.jenisKelamin = jenisKelamin
    self.alamat = alamat
    self.rtRw = rtRw
    self.kelurahan = kelurahan
    self.kecamatan = kecamatan
    self.agama = agama
    self.statusPerkawinan = statusPerkawinan
    self.pekerjaan = pekerjaan
    self.kewarganegaraan = kewarganegaraan
    self.berlakuHingga = berlakuHingga
    self.rawText = rawText
    self.confidence = confidence
    self.ocrEngine = ocrEngine
    self.processingTime = processingTime
  }
}

enum OCREngine: String, CaseIterable {
  case vision = "Apple Vision"
  case mlkit = "Google MLKit"
}

struct OCRComparisonResult {
  let visionResult: KTPData?
  let mlkitResult: KTPData?
  let processingTime: (vision: Double, mlkit: Double)
  
  var hasBothResults: Bool {
    visionResult != nil && mlkitResult != nil
  }
  
  var bestResult: KTPData? {
    guard let vision = visionResult, let mlkit = mlkitResult else {
      return visionResult ?? mlkitResult
    }
    
    // Return result with higher confidence
    return vision.confidence >= mlkit.confidence ? vision : mlkit
  }
}
