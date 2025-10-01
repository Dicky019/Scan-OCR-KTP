//
//  KTPParserTests.swift
//  Scan OCR KTP Tests
//
//  Tests for KTP field extraction and parsing logic
//

import Testing
@testable import Scan_OCR_KTP

@Suite("KTP Parser", .tags(.parser))
struct KTPParserTests {
  let parser = KTPParser()
  
  @Test("Extract NIK from valid text")
  func extractNIK() async throws {
    let sampleText = """
        PROVINSI DKI JAKARTA
        KOTA JAKARTA SELATAN
        NIK: 3174051234567890
        Nama: BUDI SANTOSO
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.nik == "3174051234567890")
    #expect(result.nik?.count == 16)
  }
  
  @Test("Extract Nama from valid text")
  func extractNama() async throws {
    let sampleText = """
        NIK: 3174051234567890
        Nama: BUDI SANTOSO
        Tempat/Tgl Lahir: JAKARTA, 15-08-1990
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.nama == "BUDI SANTOSO")
  }
  
  @Test("Extract Tanggal Lahir with slash format")
  func extractTanggalLahirSlash() async throws {
    let sampleText = """
        Tempat/Tgl Lahir: JAKARTA, 15/08/1990
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.tanggalLahir == "15/08/1990")
  }
  
  @Test("Extract Tanggal Lahir with dash format")
  func extractTanggalLahirDash() async throws {
    let sampleText = """
        Tempat/Tgl Lahir: JAKARTA, 15-08-1990
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.tanggalLahir == "15-08-1990")
  }
  
  @Test("Extract Jenis Kelamin LAKI-LAKI")
  func extractJenisKelaminLaki() async throws {
    let sampleText = """
        Jenis Kelamin: LAKI-LAKI
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.jenisKelamin == "LAKI-LAKI")
  }
  
  @Test("Extract Jenis Kelamin PEREMPUAN")
  func extractJenisKelaminPerempuan() async throws {
    let sampleText = """
        Jenis Kelamin: PEREMPUAN
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.jenisKelamin == "PEREMPUAN")
  }
  
  @Test("Extract RT/RW")
  func extractRTRW() async throws {
    let sampleText = """
        RT/RW: 003/005
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.rtRw != nil)
    #expect(result.rtRw?.contains("003") == true)
    #expect(result.rtRw?.contains("005") == true)
  }
  
  @Test("Extract Agama Islam")
  func extractAgamaIslam() async throws {
    let sampleText = """
        Agama: ISLAM
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.agama == "ISLAM")
  }
  
  @Test("Extract Agama Kristen")
  func extractAgamaKristen() async throws {
    let sampleText = """
        Agama: KRISTEN
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.agama == "KRISTEN")
  }
  
  @Test("Extract Status Perkawinan KAWIN")
  func extractStatusKawin() async throws {
    let sampleText = """
        Status Perkawinan: KAWIN
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.statusPerkawinan == "KAWIN")
  }
  
  @Test("Extract Status Perkawinan BELUM KAWIN")
  func extractStatusBelumKawin() async throws {
    let sampleText = """
        Status Perkawinan: BELUM KAWIN
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.statusPerkawinan == "BELUM KAWIN")
  }
  
  @Test("Extract Kewarganegaraan WNI")
  func extractKewarganegaraanWNI() async throws {
    let sampleText = """
        Kewarganegaraan: WNI
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.kewarganegaraan == "WNI")
  }
  
  @Test("Extract Berlaku Hingga SEUMUR HIDUP")
  func extractBerlakuHingga() async throws {
    let sampleText = """
        Berlaku Hingga: SEUMUR HIDUP
        """
    
    let result = parser.parse(
      text: sampleText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.berlakuHingga == "SEUMUR HIDUP")
  }
  
  @Test("Parse complete KTP text")
  func parseCompleteKTP() async throws {
    let completeKTPText = """
        PROVINSI DKI JAKARTA
        KOTA JAKARTA SELATAN
        
        NIK: 3174051234567890
        Nama: BUDI SANTOSO
        Tempat/Tgl Lahir: JAKARTA, 15-08-1990
        Jenis Kelamin: LAKI-LAKI
        Alamat: JL. SUDIRMAN NO. 123
        RT/RW: 003/005
        Kel/Desa: KEBAYORAN BARU
        Kecamatan: KEBAYORAN BARU
        Agama: ISLAM
        Status Perkawinan: KAWIN
        Pekerjaan: KARYAWAN SWASTA
        Kewarganegaraan: WNI
        Berlaku Hingga: SEUMUR HIDUP
        """
    
    let result = parser.parse(
      text: completeKTPText,
      confidence: 0.95,
      engine: .vision,
      processingTime: 0.5
    )
    
    #expect(result.nik == "3174051234567890")
    #expect(result.nama == "BUDI SANTOSO")
    #expect(result.tanggalLahir == "15-08-1990")
    #expect(result.jenisKelamin == "LAKI-LAKI")
    #expect(result.agama == "ISLAM")
    #expect(result.statusPerkawinan == "KAWIN")
    #expect(result.kewarganegaraan == "WNI")
    #expect(result.berlakuHingga == "SEUMUR HIDUP")
    #expect(result.confidence == 0.95)
    #expect(result.ocrEngine == .vision)
  }
  
  @Test("Handle empty text gracefully")
  func emptyText() async throws {
    let result = parser.parse(
      text: "",
      confidence: 0.0,
      engine: .vision,
      processingTime: 0.1
    )
    
    #expect(result.nik == nil)
    #expect(result.nama == nil)
    #expect(result.rawText == "")
  }
  
  @Test("Handle malformed text")
  func malformedText() async throws {
    let malformedText = "RANDOM TEXT WITHOUT KTP DATA 12345"
    
    let result = parser.parse(
      text: malformedText,
      confidence: 0.5,
      engine: .vision,
      processingTime: 0.3
    )
    
    // Should not crash and return nil for most fields
    #expect(result.rawText == malformedText)
    #expect(result.confidence == 0.5)
  }
}
