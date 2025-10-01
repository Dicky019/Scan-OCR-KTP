//
//  KTPData.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import Foundation

// MARK: - KTP Data Model

struct KTPData: Equatable {
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
  let golonganDarah: String?
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
    golonganDarah: String? = nil,
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
    self.golonganDarah = golonganDarah
    self.rawText = rawText
    self.confidence = confidence
    self.ocrEngine = ocrEngine
    self.processingTime = processingTime
  }
}
