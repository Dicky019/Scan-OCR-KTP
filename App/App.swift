//
//  Scan_OCR_KTPApp.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import SwiftUI

@main
struct MainApp: App {

  init() {
    // Disable MLKit analytics to prevent background task warnings
    #if !targetEnvironment(simulator)
    disableMLKitAnalytics()
    #endif
  }

  var body: some Scene {
    WindowGroup {
      MainView()
    }
  }

  #if !targetEnvironment(simulator)
  private func disableMLKitAnalytics() {
    // Disable Google MLKit data collection
    UserDefaults.standard.set(false, forKey: "firebase_data_collection_default_enabled")
    UserDefaults.standard.set(false, forKey: "google_app_measurement_default_enabled")
    UserDefaults.standard.synchronize()
  }
  #endif
}
