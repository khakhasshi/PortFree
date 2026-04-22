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

        MenuBarExtra {
            MenuBarView()
                .environmentObject(viewModel)
        } label: {
            Image("iconbar")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .accessibilityLabel("PortFree")
        }
        .menuBarExtraStyle(.window)
    }
}
