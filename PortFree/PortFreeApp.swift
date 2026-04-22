//
//  PortFreeApp.swift
//  PortFree
//
//  Created by JIANGJINGZHE on 22/4/2026.
//

import SwiftUI

@main
struct PortFreeApp: App {
    @StateObject private var viewModel = PortManagerViewModel()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(viewModel)
        }

        MenuBarExtra("PortFree", systemImage: "bolt.circle") {
            MenuBarView()
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
