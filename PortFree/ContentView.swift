//
//  ContentView.swift
//  PortFree
//
//  Created by JIANGJINGZHE on 22/4/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: PortManagerViewModel
    @EnvironmentObject private var languageSettings: AppLanguageSettings
    @State private var showCopiedToast = false
    @State private var isPortListExpanded = false
    @State private var showAddPortField = false
    @State private var newPortInput = ""

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 250, ideal: 280)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    portInputSection
                    quickActionStrip
                    resultSection
                }
                .padding(24)
                .frame(maxWidth: 760, alignment: .leading)
            }
            .background(Color.clear)
            .navigationTitle(t(.portManagement))
        }
        .frame(minWidth: 960, minHeight: 620)
        .confirmationDialog(t(.forceKillConfirmTitle), isPresented: $viewModel.showingForceKillConfirmation, titleVisibility: .visible) {
            Button(t(.forceKillConfirmButton), role: .destructive) {
                Task {
                    await viewModel.killCurrentProcess(force: true)
                }
            }
            Button(t(.cancel), role: .cancel) { }
        } message: {
            Text(viewModel.forceKillMessage)
        }
    }

    private var sidebar: some View {
        List {
            Section(header: HStack {
                Text(t(.allListeningPorts))
                Spacer()
                if viewModel.isScanningAll {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Button {
                        Task { await viewModel.scanAllPorts() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .help(t(.scanAllPorts))
                }
            }) {
                if viewModel.allListeningPorts.isEmpty {
                    if viewModel.isScanningAll {
                        Text(t(.scanning))
                            .foregroundStyle(.secondary)
                    } else {
                        Button {
                            Task { await viewModel.scanAllPorts() }
                        } label: {
                            Label(t(.scanAllPorts), systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .modifier(SidebarRowHoverEffect())
                    }
                } else {
                    let visiblePorts = isPortListExpanded ? viewModel.allListeningPorts : Array(viewModel.allListeningPorts.prefix(5))
                    ForEach(visiblePorts, id: \.port) { result in
                        Button {
                            viewModel.fillPortAndCheck(result.port)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t(.portWithNumber, languageSettings.plainNumber(result.port)))
                                        .font(.headline)
                                    Text("\(result.processName) · PID \(result.pid)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 8, height: 8)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .modifier(SidebarRowHoverEffect())
                    }

                    if viewModel.allListeningPorts.count > 5 {
                        Button {
                            withAnimation { isPortListExpanded.toggle() }
                        } label: {
                            HStack {
                                Text(isPortListExpanded ? t(.collapse) : t(.showAll, languageSettings.plainNumber(viewModel.allListeningPorts.count)))
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                                Spacer()
                                Image(systemName: isPortListExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .modifier(SidebarRowHoverEffect())
                    }
                }
            }

            Section(header: HStack {
                Text(t(.commonPorts))
                Spacer()
                Button {
                    withAnimation { showAddPortField.toggle() }
                } label: {
                    Image(systemName: showAddPortField ? "minus" : "plus")
                }
                .buttonStyle(.plain)
                .help(t(.addCustomPort))
            }) {
                if showAddPortField {
                    HStack(spacing: 8) {
                        TextField(t(.portPlaceholder), text: $newPortInput)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { addPort() }
                        Button {
                            addPort()
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                        .disabled(newPortInput.isEmpty)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }

                ForEach(viewModel.quickPorts, id: \.self) { port in
                    Button {
                        viewModel.fillPortAndCheck(port)
                    } label: {
                        HStack {
                            Text(t(.portWithNumber, languageSettings.plainNumber(port)))
                            Spacer()
                            if viewModel.customQuickPorts.contains(port) {
                                Button {
                                    withAnimation { viewModel.removeCustomPort(port) }
                                } label: {
                                    Image(systemName: "xmark.circle")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help(t(.removeCustomPort))
                            } else {
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .modifier(SidebarRowHoverEffect())
                }
            }

            Section(header: HStack {
                Text(t(.recentHistory))
                Spacer()
                if !viewModel.items.isEmpty {
                    Button {
                        viewModel.clearAllHistory()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .help(t(.clearHistory))
                }
            }) {
                if viewModel.items.isEmpty {
                    Text(t(.noHistory))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.recentItems(limit: 12)) { item in
                        Button {
                            viewModel.fillPortAndCheck(item.port)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(viewModel.historyActionTitle(for: item)) · \(t(.portWithNumber, languageSettings.plainNumber(item.port)))")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(viewModel.historySubtitle(for: item))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(languageSettings.formattedDate(item.timestamp))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .modifier(SidebarRowHoverEffect())
                    }
                    .onDelete { offsets in
                        viewModel.deleteRecentItems(offsets: offsets)
                    }
                }
            }
            
            Section(header: Text(t(.settings))) {
                Toggle(t(.launchAtLogin), isOn: $viewModel.launchAtLogin)
                    .toggleStyle(.switch)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)

                Text(t(.globalHotkeyHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
            }
        }
        .navigationTitle("PortFree")
        .listStyle(.sidebar)
        .task {
            await viewModel.scanAllPorts()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(t(.releaseOccupiedPort))
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text(t(.releaseOccupiedPortSubtitle))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            LanguageMenuButton()
        }
    }

    private var portInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(t(.inspectPort))
                    .font(.headline)
                Spacer()
                if let currentResult = viewModel.currentResult {
                    statusBadge(for: currentResult)
                }
            }

            HStack(spacing: 12) {
                TextField(t(.portPlaceholder), text: $viewModel.portInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 240)
                    .onSubmit {
                        Task {
                            await viewModel.inspectCurrentPort()
                        }
                    }

                Button(t(.inspectPortButton)) {
                    Task {
                        await viewModel.inspectCurrentPort()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.isLoading)

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline)
            } else {
                Text(viewModel.statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .modifier(HoverCardEffect())
    }

    private var quickActionStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.quickPorts, id: \.self) { port in
                    Button {
                        viewModel.fillPortAndCheck(port)
                    } label: {
                        Label("\(port)", systemImage: "bolt.circle")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .modifier(HoverLiftEffect())
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if let result = viewModel.currentResult {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(t(.portWithNumber, languageSettings.plainNumber(result.port)))
                            .font(.title2)
                            .fontWeight(.medium)
                        Text(result.isOccupied ? t(.currentlyOccupied) : t(.currentlyFree))
                            .foregroundStyle(result.isOccupied ? .orange : .green)
                    }

                    Spacer()

                    Label(result.protocolName, systemImage: result.isOccupied ? "network" : "checkmark.circle")
                        .foregroundStyle(.secondary)
                }

                Divider()

                if result.isOccupied {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                        detailCard(title: t(.process), value: result.processName)
                        detailCard(title: t(.pid), value: String(result.pid))
                        detailCard(title: t(.user), value: result.user)
                        detailCard(title: t(.protocol), value: result.protocolName)
                        detailCard(title: t(.endpoint), value: result.endpoint)
                        detailCard(title: t(.command), value: result.command)
                    }

                    HStack(spacing: 12) {
                        Button(t(.endProcess)) {
                            Task {
                                await viewModel.killCurrentProcess(force: false)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading)

                        Button(t(.forceEnd)) {
                            viewModel.showingForceKillConfirmation = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(viewModel.isLoading)

                        Spacer()

                        Button {
                            viewModel.copyProcessInfo()
                            showCopiedToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showCopiedToast = false
                            }
                        } label: {
                            Label(t(.copyInfo), systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }

                    if showCopiedToast {
                        Label(t(.copiedToClipboard), systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                } else {
                    Label(t(.noProcessDetected), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .modifier(HoverCardEffect())
        } else {
            ContentUnavailableView(
                t(.notCheckedYet),
                systemImage: "point.3.connected.trianglepath.dotted",
                description: Text(t(.notCheckedYetDescription))
            )
            .frame(maxWidth: .infinity, minHeight: 280)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .modifier(HoverCardEffect())
        }
    }

    private func detailCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.medium))
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(16)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .modifier(HoverCardEffect(cornerRadius: 16, baseOpacity: 0.04, hoverOpacity: 0.08, yOffset: -2))
    }

    private func statusBadge(for result: PortInspectionResult) -> some View {
        Text(result.isOccupied ? t(.occupied) : t(.available))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((result.isOccupied ? Color.orange : Color.green).opacity(0.14), in: Capsule())
            .foregroundStyle(result.isOccupied ? .orange : .green)
    }

    private func t(_ key: AppTextKey, _ arguments: CVarArg...) -> String {
        languageSettings.text(key, arguments)
    }

    private func addPort() {
        let normalized = newPortInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "，", with: "")
        if let port = Int(normalized), (1...65535).contains(port) {
            viewModel.addCustomPort(port)
            newPortInput = ""
            withAnimation { showAddPortField = false }
        }
    }
}

private struct HoverCardEffect: ViewModifier {
    let cornerRadius: CGFloat
    let baseOpacity: Double
    let hoverOpacity: Double
    let yOffset: CGFloat

    @State private var isHovering = false

    init(cornerRadius: CGFloat = 18, baseOpacity: Double = 0.05, hoverOpacity: Double = 0.1, yOffset: CGFloat = -3) {
        self.cornerRadius = cornerRadius
        self.baseOpacity = baseOpacity
        self.hoverOpacity = hoverOpacity
        self.yOffset = yOffset
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(isHovering ? hoverOpacity : baseOpacity), lineWidth: 1)
            }
            .scaleEffect(isHovering ? 1.006 : 1)
            .offset(y: isHovering ? yOffset : 0)
            .animation(.easeOut(duration: 0.16), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

private struct HoverLiftEffect: ViewModifier {
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? 1.04 : 1)
            .animation(.easeOut(duration: 0.14), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

private struct SidebarRowHoverEffect: ViewModifier {
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(isHovering ? 0.08 : 0.0001))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(isHovering ? 0.08 : 0), lineWidth: 1)
            }
            .offset(x: isHovering ? 2 : 0)
            .animation(.easeOut(duration: 0.14), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    @MainActor
    private static let previewLanguageSettings = AppLanguageSettings()

    static var previews: some View {
        ContentView()
            .environmentObject(PortManagerViewModel(languageSettings: previewLanguageSettings))
            .environmentObject(previewLanguageSettings)
    }
}
