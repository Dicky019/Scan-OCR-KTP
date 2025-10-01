//
//  ModelTests.swift
//  Scan OCR KTP Tests
//
//  Tests for data models and structures
//

import Testing
import UIKit
@testable import Scan_OCR_KTP

@Suite("Models", .tags(.models))
struct ModelTests {
  
  @Test("KTPData model initialization")
  func ktpDataInit() {
    let ktpData = KTPData(
      nik: "1234567890123456",
      nama: "JOHN DOE",
      tempatLahir: "JAKARTA",
      tanggalLahir: "01-01-1990",
      jenisKelamin: "LAKI-LAKI",
      alamat: "JL. TEST NO. 123",
      rtRw: "001/002",
      kelurahan: "TEST KELURAHAN",
      kecamatan: "TEST KECAMATAN",
      agama: "ISLAM",
      statusPerkawinan: "KAWIN",
      pekerjaan: "KARYAWAN",
      kewarganegaraan: "WNI",
      berlakuHingga: "SEUMUR HIDUP",
      rawText: "Sample text",
      confidence: 0.95,
      ocrEngine: .vision,
      processingTime: 1.5
    )
    
    #expect(ktpData.nik == "1234567890123456")
    #expect(ktpData.nama == "JOHN DOE")
    #expect(ktpData.confidence == 0.95)
    #expect(ktpData.ocrEngine == .vision)
    #expect(ktpData.processingTime == 1.5)
  }
  
  @Test("ImageData model initialization")
  func imageDataInit() {
    let testImage = UIImage(resource: .ktpTesting)
    let imageData = CapturedImage(
      image: testImage,
      source: .camera
    )
    
    #expect(imageData.image == testImage)
    #expect(imageData.source == .camera)
  }
  
  @Test("ImageSource enum")
  func imageSource() {
    let cameraSource: ImageSource = .camera
    let gallerySource: ImageSource = .gallery
    
    #expect(cameraSource != gallerySource)
  }
  
  @Test("OCREngine enum")
  func ocrEngine() {
    let vision: OCREngine = .vision
    let mlkit: OCREngine = .mlkit
    
    #expect(vision.rawValue == "Apple Vision")
    #expect(mlkit.rawValue == "Google MLKit")
    #expect(vision != mlkit)
  }
}
