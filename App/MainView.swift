//
//  MainView.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import SwiftUI

struct MainView: View {
  @StateObject private var coordinator = NavigationCoordinator()
  
  var body: some View {
    NavigationStack(path: $coordinator.path) {
      HomeView()
        .navigationDestination(for: AppRoute.self) { route in
          NavigationFactory.makeView(for: route, coordinator: coordinator)
        }
    }
    .environmentObject(coordinator)
  }
}

#Preview {
  MainView()
}
