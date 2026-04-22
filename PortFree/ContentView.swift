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
    @State private var isBatchSelecting = false
    @FocusState private var isPortInputFocused: Bool

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
                .animation(.easeInOut(duration: 0.25), value: viewModel.currentResult?.port)
                .animation(.easeInOut(duration: 0.25), value: viewModel.currentResult?.isOccupied)
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
                if !viewModel.allListeningPorts.isEmpty {
                    Text("\(viewModel.allListeningPorts.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(.orange))
                }
                Spacer()
                if !viewModel.allListeningPorts.isEmpty {
                    Button {
                        withAnimation { isBatchSelecting.toggle() }
                        if !isBatchSelecting { viewModel.selectedPortsForKill.removeAll() }
                    } label: {
                        Image(systemName: isBatchSelecting ? "xmark.circle" : "checklist")
                    }
                    .buttonStyle(.plain)
                    .help(isBatchSelecting ? t(.cancel) : t(.batchSelect))
                }
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
                // Search field
                if !viewModel.allListeningPorts.isEmpty || !viewModel.portSearchText.isEmpty {
                    TextField(t(.searchPorts), text: $viewModel.portSearchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }

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
                    let filtered = viewModel.filteredListeningPorts
                    let visiblePorts = isPortListExpanded ? filtered : Array(filtered.prefix(5))

                    if filtered.isEmpty && !viewModel.portSearchText.isEmpty {
                        Text(t(.noMatchingPorts))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                    }

                    ForEach(visiblePorts, id: \.port) { result in
                        Button {
                            if isBatchSelecting {
                                togglePortSelection(result.port)
                            } else {
                                viewModel.fillPortAndCheck(result.port)
                            }
                        } label: {
                            HStack {
                                if isBatchSelecting {
                                    Image(systemName: viewModel.selectedPortsForKill.contains(result.port) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(viewModel.selectedPortsForKill.contains(result.port) ? .blue : .secondary)
                                }
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

                    if isBatchSelecting && !viewModel.selectedPortsForKill.isEmpty {
                        Button {
                            Task { await viewModel.killSelectedPorts() }
                            isBatchSelecting = false
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text(t(.killSelected, String(viewModel.selectedPortsForKill.count)))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.small)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    }

                    if filtered.count > 5 {
                        Button {
                            withAnimation { isPortListExpanded.toggle() }
                        } label: {
                            HStack {
                                Text(isPortListExpanded ? t(.collapse) : t(.showAll, languageSettings.plainNumber(filtered.count)))
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

                Divider()

                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.secondary)
                    Picker(t(.autoRefresh), selection: Binding(
                        get: { viewModel.autoRefreshInterval },
                        set: { viewModel.setAutoRefreshInterval($0) }
                    )) {
                        Text(t(.off)).tag(0.0)
                        Text("2s").tag(2.0)
                        Text("3s").tag(3.0)
                        Text("5s").tag(5.0)
                        Text("10s").tag(10.0)
                        Text("30s").tag(30.0)
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: viewModel.cliInstalled ? "terminal.fill" : "terminal")
                            .foregroundStyle(viewModel.cliInstalled ? .green : .secondary)
                        Text(viewModel.cliInstalled ? t(.cliInstalled) : t(.cliNotInstalled))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(t(.cliDescription))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Button(viewModel.cliInstalled ? t(.uninstallCLI) : t(.installCLI)) {
                        if viewModel.cliInstalled {
                            viewModel.uninstallCLI()
                        } else {
                            viewModel.installCLI()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("PortFree")
        .listStyle(.sidebar)
        .task {
            await viewModel.scanAllPorts()
            viewModel.restartAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
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
                    .focused($isPortInputFocused)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(t(.quickPorts))
                .font(.caption)
                .foregroundStyle(.secondary)
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
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                        detailCard(title: t(.process), value: result.processName, icon: "app.dashed")
                        detailCard(title: t(.pid), value: String(result.pid), icon: "number")
                        detailCard(title: t(.user), value: result.user, icon: "person")
                        detailCard(title: t(.protocol), value: result.protocolName, icon: "network")
                        detailCard(title: t(.endpoint), value: result.endpoint, icon: "point.topleft.down.to.point.bottomright.curvepath")
                        detailCard(title: t(.command), value: result.command, icon: "terminal")
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await viewModel.killCurrentProcess(force: false)
                            }
                        } label: {
                            Label(t(.endProcess), systemImage: "stop.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading)

                        Button {
                            viewModel.showingForceKillConfirmation = true
                        } label: {
                            Label(t(.forceEnd), systemImage: "xmark.octagon")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(viewModel.isLoading)

                        Spacer()

                        Button {
                            viewModel.copyProcessInfo()
                            withAnimation(.spring(duration: 0.3)) {
                                showCopiedToast = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showCopiedToast = false
                                }
                            }
                        } label: {
                            Label(t(.copyInfo), systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }

                    if showCopiedToast {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(t(.copiedToClipboard))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.green.opacity(0.1), in: Capsule())
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t(.noProcessDetected))
                                .font(.headline)
                                .foregroundStyle(.green)
                            Text(t(.portWithNumber, languageSettings.plainNumber(result.port)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .modifier(HoverCardEffect())
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity
            ))
        } else {
            VStack(spacing: 16) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 48))
                    .foregroundStyle(.quaternary)
                Text(t(.notCheckedYet))
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(t(.notCheckedYetDescription))
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                Button {
                    isPortInputFocused = true
                } label: {
                    Label(t(.inspectPort), systemImage: "magnifyingglass")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity, minHeight: 280)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .modifier(HoverCardEffect())
        }
    }

    private func detailCard(title: String, value: String, icon: String = "") -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.callout.weight(.medium))
                .textSelection(.enabled)
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .modifier(HoverCardEffect(cornerRadius: 10, baseOpacity: 0.04, hoverOpacity: 0.08, yOffset: -1))
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

    private func togglePortSelection(_ port: Int) {
        if viewModel.selectedPortsForKill.contains(port) {
            viewModel.selectedPortsForKill.remove(port)
        } else {
            viewModel.selectedPortsForKill.insert(port)
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
