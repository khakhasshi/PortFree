import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var viewModel: PortManagerViewModel
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
        VStack(alignment: .leading, spacing: 4) {
            Text("PortFree 快捷菜单")
                .font(.headline)
            Text(viewModel.errorMessage ?? viewModel.statusMessage)
                .font(.caption)
                .foregroundStyle(viewModel.errorMessage == nil ? Color.secondary : Color.orange)
                .lineLimit(2)
        }
    }

    private var portInput: some View {
        HStack(spacing: 8) {
            TextField("端口号", text: $viewModel.portInput)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    Task {
                        await viewModel.inspectCurrentPort()
                    }
                }

            Button("检查") {
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
            Text("快捷端口")
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
                        Text("端口 \(result.port)")
                            .font(.subheadline.weight(.semibold))
                        Text(result.isOccupied ? "占用中" : "空闲")
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
                        Button("结束") {
                            Task {
                                await viewModel.killCurrentProcess(force: false)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("强制结束") {
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
            Text("最近操作")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.recentItems(limit: 3).isEmpty {
                Text("暂无记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.recentItems(limit: 3)) { item in
                    Button {
                        viewModel.inspect(port: item.port)
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(item.actionType) · \(item.port)")
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
            Button("打开主窗口") {
                openWindow(id: "main")
            }
            .buttonStyle(.plain)
            .modifier(MenuHoverLiftEffect(scale: 1.015))

            Button("退出 PortFree") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .modifier(MenuHoverLiftEffect(scale: 1.015))
        }
        .font(.subheadline)
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
