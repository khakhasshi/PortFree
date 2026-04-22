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
    @StateObject private var languageSettings: AppLanguageSettings
    @StateObject private var viewModel: PortManagerViewModel
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        let languageSettings = AppLanguageSettings()
        _languageSettings = StateObject(wrappedValue: languageSettings)
        _viewModel = StateObject(wrappedValue: PortManagerViewModel(languageSettings: languageSettings))
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(languageSettings)
                .environment(\.locale, Locale(identifier: languageSettings.currentLanguage.localeIdentifier))
                .onAppear {
                    appDelegate.openWindowAction = {
                        NSApp.activate(ignoringOtherApps: true)
                        for window in NSApp.windows where window.identifier?.rawValue.contains("main") == true || window.title.contains("Port") {
                            window.makeKeyAndOrderFront(nil)
                            return
                        }
                    }
                }
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(viewModel)
                .environmentObject(languageSettings)
                .environment(\.locale, Locale(identifier: languageSettings.currentLanguage.localeIdentifier))
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

final class AppDelegate: NSObject, NSApplicationDelegate {
    var openWindowAction: (() -> Void)?
    private var globalMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Cmd + Shift + P
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == [.command, .shift], event.charactersIgnoringModifiers?.lowercased() == "p" {
                DispatchQueue.main.async {
                    self?.openWindowAction?()
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
