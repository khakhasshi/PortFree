//
//  PortFreeApp.swift
//  PortFree
//
//  Created by JIANGJINGZHE on 22/4/2026.
//

import AppKit
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
            Image(nsImage: Self.menuBarIcon)
                .accessibilityLabel("PortFree")
        }
        .menuBarExtraStyle(.window)
    }

    private static let menuBarIcon: NSImage = {
        guard let sourceImage = NSImage(named: "iconbar") else {
            let fallback = NSImage(systemSymbolName: "bolt.circle", accessibilityDescription: "PortFree") ?? NSImage()
            fallback.isTemplate = true
            return fallback
        }

        let canvasSize = NSSize(width: 18, height: 18)
            let insetRect = NSRect(x: 0, y: 0, width: 18, height: 18)
        let outputImage = NSImage(size: canvasSize)

        outputImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        sourceImage.draw(in: insetRect, from: .zero, operation: .sourceOver, fraction: 1)
        outputImage.unlockFocus()

        outputImage.isTemplate = true
        return outputImage
    }()
}
