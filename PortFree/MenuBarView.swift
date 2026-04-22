import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var viewModel: PortManagerViewModel
    @EnvironmentObject private var languageSettings: AppLanguageSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            Divider().padding(.horizontal, 12)

            portInput
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            quickPorts
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            currentStatus
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            Divider().padding(.horizontal, 12)

            listeningPortsSummary
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            Divider().padding(.horizontal, 12)

            recentSection
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            Divider().padding(.horizontal, 12)

            footerActions
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .frame(width: 340)
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text("PortFree")
                    .font(.headline)
            }

            Spacer()

            LanguageMenuButton(showsTitle: false)
        }
    }

    private var portInput: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField(t(.portPlaceholder), text: $viewModel.portInput)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await viewModel.inspectCurrentPort() }
                    }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                Task { await viewModel.inspectCurrentPort() }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(viewModel.portInput.isEmpty ? Color.secondary : Color.accentColor)
            .disabled(viewModel.isLoading || viewModel.portInput.isEmpty)
            .modifier(MenuHoverLiftEffect())

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var quickPorts: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(viewModel.quickPorts, id: \.self) { port in
                    Button {
                        viewModel.inspect(port: port)
                    } label: {
                        Text("\(port)")
                            .font(.caption.weight(.medium).monospacedDigit())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                portIsActive(port) ? Color.orange.opacity(0.15) : Color.primary.opacity(0.06),
                                in: Capsule()
                            )
                            .foregroundStyle(portIsActive(port) ? .orange : .primary)
                    }
                    .buttonStyle(.plain)
                    .modifier(MenuHoverLiftEffect())
                }
            }
        }
    }

    @ViewBuilder
    private var currentStatus: some View {
        if let result = viewModel.currentResult {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(result.isOccupied ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: result.isOccupied ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(result.isOccupied ? .orange : .green)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(t(.portWithNumber, languageSettings.plainNumber(result.port)))
                            .font(.subheadline.weight(.semibold))
                        if result.isOccupied {
                            Text("\(result.processName) · PID \(result.pid)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(t(.available))
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Spacer()

                    Text(result.isOccupied ? t(.occupied) : t(.available))
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            (result.isOccupied ? Color.orange : Color.green).opacity(0.12),
                            in: Capsule()
                        )
                        .foregroundStyle(result.isOccupied ? .orange : .green)
                }

                if result.isOccupied {
                    HStack(spacing: 8) {
                        Button {
                            Task { await viewModel.killCurrentProcess(force: false) }
                        } label: {
                            Label(t(.endProcess), systemImage: "stop.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button {
                            Task { await viewModel.killCurrentProcess(force: true) }
                        } label: {
                            Label(t(.forceEnd), systemImage: "xmark.octagon")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.red)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .modifier(MenuHoverCardEffect())
        } else if let errorMessage = viewModel.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var listeningPortsSummary: some View {
        HStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.caption)
                .foregroundStyle(.secondary)
            if viewModel.allListeningPorts.isEmpty {
                Text(t(.noListeningPorts))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(t(.portCount, languageSettings.plainNumber(viewModel.allListeningPorts.count)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if viewModel.isScanningAll {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Button {
                    Task { await viewModel.scanAllPorts() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(t(.recentHistory))
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.recentItems(limit: 3).isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                    Text(t(.noRecentRecords))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            } else {
                ForEach(viewModel.recentItems(limit: 3)) { item in
                    Button {
                        viewModel.inspect(port: item.port)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: historyIcon(for: item))
                                .font(.caption)
                                .foregroundStyle(historyColor(for: item))
                                .frame(width: 16)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(t(.portWithNumber, languageSettings.plainNumber(item.port)))
                                    .font(.caption.weight(.medium))
                                Text("\(viewModel.historyActionTitle(for: item)) · \(item.processName)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(languageSettings.formattedDate(item.timestamp))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .background(Color.primary.opacity(0.0001), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .modifier(MenuHoverCardEffect(cornerRadius: 8, baseOpacity: 0.02, hoverOpacity: 0.07, scale: 1.008))
                }
            }
        }
    }

    private var footerActions: some View {
        HStack(spacing: 0) {
            Button {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "macwindow")
                    Text(t(.openMainWindow))
                }
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .contentShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .modifier(MenuHoverCardEffect(cornerRadius: 6, baseOpacity: 0.03, hoverOpacity: 0.08, scale: 1.01))

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                    Text(t(.quitApp))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .contentShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .modifier(MenuHoverCardEffect(cornerRadius: 6, baseOpacity: 0.02, hoverOpacity: 0.06, scale: 1.01))
        }
    }

    private func t(_ key: AppTextKey, _ arguments: CVarArg...) -> String {
        languageSettings.text(key, arguments)
    }

    private func portIsActive(_ port: Int) -> Bool {
        viewModel.currentResult?.port == port && viewModel.currentResult?.isOccupied == true
    }

    private func historyIcon(for item: Item) -> String {
        switch item.actionType {
        case "terminate", "forceTerminate":
            return item.resultStatus == "success" ? "checkmark.circle" : "xmark.circle"
        default:
            return item.resultStatus == "occupied" ? "circle.fill" : "circle"
        }
    }

    private func historyColor(for item: Item) -> Color {
        switch item.resultStatus {
        case "success": return .green
        case "failed": return .red
        case "occupied": return .orange
        default: return .secondary
        }
    }
}

private struct MenuHoverCardEffect: ViewModifier {
    let cornerRadius: CGFloat
    let baseOpacity: Double
    let hoverOpacity: Double
    let scale: CGFloat

    @State private var isHovering = false

    init(cornerRadius: CGFloat = 12, baseOpacity: Double = 0.04, hoverOpacity: Double = 0.09, scale: CGFloat = 1.015) {
        self.cornerRadius = cornerRadius
        self.baseOpacity = baseOpacity
        self.hoverOpacity = hoverOpacity
        self.scale = scale
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(isHovering ? hoverOpacity : baseOpacity), lineWidth: 1)
            }
            .scaleEffect(isHovering ? scale : 1)
            .animation(.easeOut(duration: 0.14), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

private struct MenuHoverLiftEffect: ViewModifier {
    let scale: CGFloat

    @State private var isHovering = false

    init(scale: CGFloat = 1.03) {
        self.scale = scale
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? scale : 1)
            .animation(.easeOut(duration: 0.12), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}
