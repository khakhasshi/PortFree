import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var viewModel: PortManagerViewModel
    @EnvironmentObject private var languageSettings: AppLanguageSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            portInput
            quickPorts
            currentStatus
            recentSection
            Divider()
            footerActions
        }
        .padding(16)
        .frame(width: 320)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(t(.quickMenuTitle))
                    .font(.headline)
                Text(viewModel.errorMessage ?? viewModel.statusMessage)
                    .font(.caption)
                    .foregroundStyle(viewModel.errorMessage == nil ? Color.secondary : Color.orange)
                    .lineLimit(2)
            }

            Spacer()

            LanguageMenuButton(showsTitle: false)
        }
    }

    private var portInput: some View {
        HStack(spacing: 8) {
            TextField(t(.inspectPort), text: $viewModel.portInput)
                .textFieldStyle(.roundedBorder)
                .frame(width: 170)
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
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
            .modifier(MenuHoverLiftEffect())
        }
    }

    private var quickPorts: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t(.quickPorts))
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 8) {
                ForEach(viewModel.quickPorts, id: \.self) { port in
                    Button("\(port)") {
                        viewModel.inspect(port: port)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .modifier(MenuHoverLiftEffect())
                }
            }
        }
    }

    @ViewBuilder
    private var currentStatus: some View {
        if let result = viewModel.currentResult {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t(.portWithNumber, languageSettings.plainNumber(result.port)))
                            .font(.subheadline.weight(.semibold))
                        Text(result.isOccupied ? t(.occupied) : t(.available))
                            .font(.caption)
                            .foregroundStyle(result.isOccupied ? .orange : .green)
                    }
                    Spacer()
                    Image(systemName: result.isOccupied ? "bolt.fill" : "checkmark.circle.fill")
                        .foregroundStyle(result.isOccupied ? .orange : .green)
                }

                if result.isOccupied {
                    Text("\(result.processName) · PID \(result.pid)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Button(t(.endProcess)) {
                            Task {
                                await viewModel.killCurrentProcess(force: false)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button(t(.forceEnd)) {
                            Task {
                                await viewModel.killCurrentProcess(force: true)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.red)
                    }
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .modifier(MenuHoverCardEffect())
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t(.recentHistory))
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.recentItems(limit: 3).isEmpty {
                Text(t(.noRecentRecords))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.recentItems(limit: 3)) { item in
                    Button {
                        viewModel.inspect(port: item.port)
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(viewModel.historyActionTitle(for: item)) · \(t(.portWithNumber, languageSettings.plainNumber(item.port)))")
                                    .font(.caption.weight(.semibold))
                                Text(viewModel.historySubtitle(for: item))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .background(Color.primary.opacity(0.0001), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .modifier(MenuHoverCardEffect(cornerRadius: 10, baseOpacity: 0.03, hoverOpacity: 0.08, scale: 1.01))
                }
            }
        }
    }

    private var footerActions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(t(.openMainWindow)) {
                openWindow(id: "main")
            }
            .buttonStyle(.plain)
            .modifier(MenuHoverLiftEffect(scale: 1.015))

            Button(t(.quitApp)) {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .modifier(MenuHoverLiftEffect(scale: 1.015))
        }
        .font(.subheadline)
    }

    private func t(_ key: AppTextKey, _ arguments: CVarArg...) -> String {
        languageSettings.text(key, arguments)
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
