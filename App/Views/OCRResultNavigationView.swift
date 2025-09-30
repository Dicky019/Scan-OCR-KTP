//
//  OCRResultNavigationView.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import SwiftUI

struct OCRResultNavigationView: View {
    let image: UIImage
    let imageId: String

    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var isProcessing = true
    @State private var ocrResults: OCRComparisonResult?
    @State private var selectedEngine: OCREngine = .vision
    @State private var showingPerformanceDetails = false
    @State private var processingTask: Task<Void, Never>?

    private let logger = OCRLogger.shared
    private let ocrManager = OCRManager()

    var body: some View {
        VStack {
            if isProcessing {
                // Processing State
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Processing OCR...")
                        .font(.headline)

                    Text("Analyzing your KTP image")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let results = ocrResults {
                // Results State
                OCRResultsContentView(
                    results: results,
                    originalImage: image,
                    selectedEngine: $selectedEngine,
                    showingPerformanceDetails: $showingPerformanceDetails
                )
            } else {
                // Error State
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text("OCR Processing Failed")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Unable to process the image. Please try again.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Try Again") {
                        processOCR()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Go Back") {
                        coordinator.pop()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .onAppear {
            processOCR()
        }
        .onDisappear {
            processingTask?.cancel()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Home") {
                    coordinator.popToRoot()
                }
            }
        }
    }

    private func processOCR() {
        isProcessing = true
        ocrResults = nil

        // Cancel any existing task
        processingTask?.cancel()

        processingTask = Task {
            do {
                logger.logUIEvent("OCR processing started", details: "Image ID: \(imageId)")
                let results = await ocrManager.processImage(image)

                guard !Task.isCancelled else {
                    logger.logUIEvent("OCR processing cancelled")
                    return
                }

                await MainActor.run {
                    self.ocrResults = results
                    self.isProcessing = false
                    logger.logUIEvent("OCR processing completed", details: "Success: \(results.visionResult != nil || results.mlkitResult != nil)")
                }
            } catch {
                guard !Task.isCancelled else {
                    logger.logUIEvent("OCR processing cancelled")
                    return
                }

                await MainActor.run {
                    self.isProcessing = false
                    self.ocrResults = nil
                    logger.logError("OCR processing failed", error: error)
                }
            }
        }
    }
}

// MARK: - OCR Results Content View
struct OCRResultsContentView: View {
    let results: OCRComparisonResult
    let originalImage: UIImage
    @Binding var selectedEngine: OCREngine
    @Binding var showingPerformanceDetails: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Engine Selection
                if results.visionResult != nil && results.mlkitResult != nil {
                    VStack(alignment: .leading) {
                        Text("OCR Engine")
                            .font(.headline)

                        Picker("OCR Engine", selection: $selectedEngine) {
                            Text("Vision Framework").tag(OCREngine.vision)
                            Text("Google ML Kit").tag(OCREngine.mlkit)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }

                // Selected Results
                if let data = currentEngineData {
                    KTPDataDisplayView(data: data, engine: selectedEngine)
                } else {
                    Text("No results available for the selected engine")
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                // Performance Details Toggle
                if results.visionResult != nil && results.mlkitResult != nil {
                    Button(action: {
                        showingPerformanceDetails.toggle()
                    }) {
                        HStack {
                            Text("Performance Details")
                            Spacer()
                            Image(systemName: showingPerformanceDetails ? "chevron.up" : "chevron.down")
                        }
                    }
                    .foregroundColor(.blue)

                    if showingPerformanceDetails {
                        PerformanceComparisonView(results: results)
                    }
                }
            }
            .padding()
        }
    }

    private var currentEngineData: KTPData? {
        switch selectedEngine {
        case .vision:
            return results.visionResult
        case .mlkit:
            return results.mlkitResult
        }
    }
}

// MARK: - KTP Data Display View
struct KTPDataDisplayView: View {
    let data: KTPData
    let engine: OCREngine

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Engine and Confidence Header
            HStack {
                Text("\(engine.rawValue.capitalized) Results")
                    .font(.headline)
                Spacer()
                Text("\(Int(data.confidence * 100))% confidence")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Parsed Fields
            LazyVGrid(columns: [
                GridItem(.flexible(), alignment: .leading),
                GridItem(.flexible(), alignment: .leading)
            ], spacing: 12) {
                KTPFieldView(label: "NIK", value: data.nik)
                KTPFieldView(label: "Nama", value: data.nama)
                KTPFieldView(label: "Tempat Lahir", value: data.tempatLahir)
                KTPFieldView(label: "Tanggal Lahir", value: data.tanggalLahir)
                KTPFieldView(label: "Jenis Kelamin", value: data.jenisKelamin)
                KTPFieldView(label: "Alamat", value: data.alamat)
                KTPFieldView(label: "RT/RW", value: data.rtRw)
                KTPFieldView(label: "Kelurahan", value: data.kelurahan)
                KTPFieldView(label: "Kecamatan", value: data.kecamatan)
                KTPFieldView(label: "Agama", value: data.agama)
                KTPFieldView(label: "Status Perkawinan", value: data.statusPerkawinan)
                KTPFieldView(label: "Pekerjaan", value: data.pekerjaan)
                KTPFieldView(label: "Kewarganegaraan", value: data.kewarganegaraan)
                KTPFieldView(label: "Berlaku Hingga", value: data.berlakuHingga)
            }

            // Raw Text Section
            DisclosureGroup("Raw OCR Text") {
                Text(data.rawText)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}


// MARK: - KTP Field View
struct KTPFieldView: View {
    let label: String
    let value: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value ?? "N/A")
                .font(.body)
                .foregroundColor(value != nil ? .primary : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Performance Comparison View
struct PerformanceComparisonView: View {
    let results: OCRComparisonResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Analysis")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal)

            // Processing Time Comparison
            VStack(alignment: .leading, spacing: 8) {
                Text("Processing Time")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Vision")
                            .font(.caption2)
                        Text("\(String(format: "%.3f", results.processingTime.vision))s")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    // Visual comparison bar
                    HStack(spacing: 2) {
                        let maxTime = max(results.processingTime.vision, results.processingTime.mlkit)
                        let visionRatio = results.processingTime.vision / maxTime
                        let mlkitRatio = results.processingTime.mlkit / maxTime

                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: CGFloat(visionRatio * 80), height: 8)

                        Rectangle()
                            .fill(Color.green)
                            .frame(width: CGFloat(mlkitRatio * 80), height: 8)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("MLKit")
                            .font(.caption2)
                        Text("\(String(format: "%.3f", results.processingTime.mlkit))s")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.horizontal)

            // Confidence Comparison
            if let visionData = results.visionResult, let mlkitData = results.mlkitResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confidence Scores")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Vision")
                                .font(.caption2)
                            Text("\(String(format: "%.1f", visionData.confidence * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(confidenceColor(visionData.confidence))
                        }

                        Spacer()

                        // Visual confidence bars
                        HStack(spacing: 2) {
                            Rectangle()
                                .fill(confidenceColor(visionData.confidence))
                                .frame(width: CGFloat(visionData.confidence * 80), height: 8)

                            Rectangle()
                                .fill(confidenceColor(mlkitData.confidence))
                                .frame(width: CGFloat(mlkitData.confidence * 80), height: 8)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("MLKit")
                                .font(.caption2)
                            Text("\(String(format: "%.1f", mlkitData.confidence * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(confidenceColor(mlkitData.confidence))
                        }
                    }
                }
                .padding(.horizontal)

                // Speed vs Accuracy Comparison
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Summary")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    let timeDiff = abs(results.processingTime.vision - results.processingTime.mlkit)
                    let confidenceDiff = abs(visionData.confidence - mlkitData.confidence)

                    VStack(alignment: .leading, spacing: 4) {
                        if timeDiff > 0.1 {
                            let fasterEngine = results.processingTime.vision < results.processingTime.mlkit ? "Vision" : "MLKit"
                            let timeSavings = timeDiff
                            Text("• \(fasterEngine) is \(String(format: "%.2f", timeSavings))s faster")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }

                        if confidenceDiff > 0.05 {
                            let moreAccurateEngine = visionData.confidence > mlkitData.confidence ? "Vision" : "MLKit"
                            let accuracyGain = confidenceDiff * 100
                            Text("• \(moreAccurateEngine) is \(String(format: "%.1f", accuracyGain))% more confident")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }

                        // Character count comparison
                        let textLengthDiff = abs(visionData.rawText.count - mlkitData.rawText.count)
                        if textLengthDiff > 10 {
                            let longerEngine = visionData.rawText.count > mlkitData.rawText.count ? "Vision" : "MLKit"
                            Text("• \(longerEngine) extracted \(textLengthDiff) more characters")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    NavigationStack {
        OCRResultNavigationView(
            image: UIImage(systemName: "photo")!,
            imageId: "preview-id"
        )
        .environmentObject(NavigationCoordinator())
    }
}