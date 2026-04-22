//
//  ContentView.swift
//  PortFree
//
//  Created by JIANGJINGZHE on 22/4/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: PortManagerViewModel

    private let timestampFormatter = Item.timestampFormatter

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
            .navigationTitle("端口管理")
        }
        .frame(minWidth: 960, minHeight: 620)
        .confirmationDialog("确认强制结束该进程？", isPresented: $viewModel.showingForceKillConfirmation, titleVisibility: .visible) {
            Button("强制结束", role: .destructive) {
                Task {
                    await viewModel.killCurrentProcess(force: true)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text(viewModel.forceKillMessage)
        }
    }

    private var sidebar: some View {
        List {
            Section(header: Text("常用端口")) {
                ForEach(viewModel.quickPorts, id: \.self) { port in
                    Button {
                        viewModel.fillPortAndCheck(port)
                    } label: {
                        HStack {
                            Text("端口 \(port)")
                            Spacer()
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section(header: Text("最近记录")) {
                if viewModel.items.isEmpty {
                    Text("还没有操作记录")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.recentItems(limit: 12)) { item in
                        Button {
                            viewModel.fillPortAndCheck(item.port)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(item.actionType) · 端口 \(item.port)")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(viewModel.historySubtitle(for: item))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(timestampFormatter.string(from: item.timestamp))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        viewModel.deleteRecentItems(offsets: offsets)
                    }
                }
            }
        }
        .navigationTitle("PortFree")
        .listStyle(.sidebar)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快速释放被占用端口")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("输入端口号后检查占用进程，并可执行普通结束或强制结束。")
                .foregroundStyle(.secondary)
        }
    }

    private var portInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("检查端口")
                    .font(.headline)
                Spacer()
                if let currentResult = viewModel.currentResult {
                    statusBadge(for: currentResult)
                }
            }

            HStack(spacing: 12) {
                TextField("例如 3000、8080、5173", text: $viewModel.portInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 240)
                    .onSubmit {
                        Task {
                            await viewModel.inspectCurrentPort()
                        }
                    }

                Button("检查端口") {
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
                }
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if let result = viewModel.currentResult {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("端口 \(result.port)")
                            .font(.title2)
                            .fontWeight(.medium)
                        Text(result.isOccupied ? "当前已被占用" : "当前空闲")
                            .foregroundStyle(result.isOccupied ? .orange : .green)
                    }

                    Spacer()

                    Label(result.protocolName, systemImage: result.isOccupied ? "network" : "checkmark.circle")
                        .foregroundStyle(.secondary)
                }

                Divider()

                if result.isOccupied {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                        detailCard(title: "进程", value: result.processName)
                        detailCard(title: "PID", value: String(result.pid))
                        detailCard(title: "用户", value: result.user)
                        detailCard(title: "协议", value: result.protocolName)
                        detailCard(title: "端口描述", value: result.endpoint)
                        detailCard(title: "命令", value: result.command)
                    }

                    HStack(spacing: 12) {
                        Button("结束进程") {
                            Task {
                                await viewModel.killCurrentProcess(force: false)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading)

                        Button("强制结束") {
                            viewModel.showingForceKillConfirmation = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(viewModel.isLoading)
                    }
                } else {
                    Label("该端口当前未发现占用进程", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            ContentUnavailableView(
                "尚未检查端口",
                systemImage: "point.3.connected.trianglepath.dotted",
                description: Text("输入端口号，或点击上方快捷端口快速开始。")
            )
            .frame(maxWidth: .infinity, minHeight: 280)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
    }

    private func statusBadge(for result: PortInspectionResult) -> some View {
        Text(result.isOccupied ? "Occupied" : "Available")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((result.isOccupied ? Color.orange : Color.green).opacity(0.14), in: Capsule())
            .foregroundStyle(result.isOccupied ? .orange : .green)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PortManagerViewModel())
    }
}
