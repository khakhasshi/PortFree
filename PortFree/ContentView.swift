//
//  ContentView.swift
//  PortFree
//
//  Created by JIANGJINGZHE on 22/4/2026.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @State private var portInput = ""
    @State private var items: [Item] = []
    @State private var currentResult: PortInspectionResult?
    @State private var statusMessage = "输入端口号后开始检查"
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showingForceKillConfirmation = false

    private let quickPorts = [3000, 5173, 8000, 8080, 8081, 9000]
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
        .confirmationDialog("确认强制结束该进程？", isPresented: $showingForceKillConfirmation, titleVisibility: .visible) {
            Button("强制结束", role: .destructive) {
                Task {
                    await killCurrentProcess(force: true)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text(forceKillMessage)
        }
    }

    private var sidebar: some View {
        List {
            Section(header: Text("常用端口")) {
                ForEach(quickPorts, id: \.self) { port in
                    Button(action: {
                        fillPortAndCheck(port)
                    }) {
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
                if items.isEmpty {
                    Text("还没有操作记录")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(items.prefix(12))) { item in
                        Button(action: {
                            fillPortAndCheck(item.port)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(item.actionType) · 端口 \(item.port)")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(historySubtitle(for: item))
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
                    .onDelete(perform: deleteItems)
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
                if let currentResult {
                    statusBadge(for: currentResult)
                }
            }

            HStack(spacing: 12) {
                TextField("例如 3000、8080、5173", text: $portInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 240)
                    .onSubmit {
                        Task {
                            await inspectCurrentPort()
                        }
                    }

                Button("检查端口") {
                    Task {
                        await inspectCurrentPort()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isLoading)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline)
            } else {
                Text(statusMessage)
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
                ForEach(quickPorts, id: \.self) { port in
                    Button {
                        fillPortAndCheck(port)
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
        if let result = currentResult {
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
                                await killCurrentProcess(force: false)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading)

                        Button("强制结束") {
                            showingForceKillConfirmation = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(isLoading)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func deleteItems(offsets: IndexSet) {
        let visibleItems = Array(items.prefix(12))
        withAnimation {
            for index in offsets {
                guard visibleItems.indices.contains(index) else { continue }
                let itemID = visibleItems[index].id
                items.removeAll { $0.id == itemID }
            }
        }
    }

    private func fillPortAndCheck(_ port: Int) {
        portInput = String(port)
        Task {
            await inspectCurrentPort()
        }
    }

    private func inspectCurrentPort() async {
        errorMessage = nil

        guard let port = validatedPort() else {
            currentResult = nil
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Task.detached(priority: .userInitiated) {
                try PortInspector.inspect(port: port)
            }.value

            currentResult = result
            statusMessage = result.isOccupied ? "发现占用进程：\(result.processName) (PID \(result.pid))" : "端口 \(port) 当前空闲"
            insertHistory(port: port, result: result, actionType: "查询", status: result.isOccupied ? "occupied" : "free")
        } catch {
            currentResult = nil
            errorMessage = readableError(error)
            statusMessage = "检查失败"
            insertHistory(port: port, result: nil, actionType: "查询", status: "failed")
        }
    }

    private func killCurrentProcess(force: Bool) async {
        guard let result = currentResult, result.isOccupied else { return }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await Task.detached(priority: .userInitiated) {
                try PortInspector.killProcess(pid: result.pid, force: force)
            }.value

            let actionTitle = force ? "强制结束" : "结束"
            statusMessage = "已成功\(actionTitle)进程并释放端口 \(result.port)"
            insertHistory(port: result.port, result: result, actionType: force ? "强制结束" : "结束", status: "success")

            do {
                let refreshed = try await Task.detached(priority: .userInitiated) {
                    try PortInspector.inspect(port: result.port)
                }.value
                currentResult = refreshed
            } catch {
                currentResult = nil
            }
        } catch {
            errorMessage = readableError(error)
            statusMessage = force ? "强制结束失败" : "结束失败"
            insertHistory(port: result.port, result: result, actionType: force ? "强制结束" : "结束", status: "failed")
        }
    }

    private func validatedPort() -> Int? {
        guard !portInput.isEmpty else {
            errorMessage = "请输入端口号"
            return nil
        }

        guard let port = Int(portInput), (1...65535).contains(port) else {
            errorMessage = "端口号必须是 1 到 65535 之间的数字"
            return nil
        }

        return port
    }

    private func insertHistory(port: Int, result: PortInspectionResult?, actionType: String, status: String) {
        let item = Item(
            port: port,
            processName: result?.processName ?? "-",
            pid: result?.pid,
            actionType: actionType,
            resultStatus: status
        )
        items.insert(item, at: 0)
    }

    private func historySubtitle(for item: Item) -> String {
        let processPart = item.processName == "-" ? "无进程信息" : item.processName
        let pidPart = item.pid.map { "PID \($0)" } ?? "PID -"
        return "\(processPart) · \(pidPart) · \(item.resultStatus)"
    }

    private func readableError(_ error: Error) -> String {
        if let inspectorError = error as? PortInspector.PortInspectorError {
            return inspectorError.errorDescription ?? "未知错误"
        }

        return error.localizedDescription
    }

    private var forceKillMessage: String {
        guard let result = currentResult else {
            return "将执行 kill -9。"
        }
        return "将对 \(result.processName) (PID \(result.pid)) 执行 kill -9。"
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
    }
}

private struct PortInspectionResult: Sendable {
    let port: Int
    let isOccupied: Bool
    let processName: String
    let pid: Int
    let user: String
    let protocolName: String
    let command: String
    let endpoint: String

    static func free(port: Int) -> PortInspectionResult {
        PortInspectionResult(
            port: port,
            isOccupied: false,
            processName: "-",
            pid: 0,
            user: "-",
            protocolName: "N/A",
            command: "-",
            endpoint: "-"
        )
    }
}

private enum PortInspector {
    enum PortInspectorError: LocalizedError {
        case commandFailed(String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case let .commandFailed(message):
                return message.isEmpty ? "命令执行失败" : message
            case .invalidResponse:
                return "系统返回了无法解析的端口信息"
            }
        }
    }

    static func inspect(port: Int) throws -> PortInspectionResult {
        let output = try runCommand(
            launchPath: "/usr/sbin/lsof",
            arguments: ["-nP", "-iTCP:\(port)", "-sTCP:LISTEN"]
        )

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .free(port: port)
        }

        let lines = trimmed.split(whereSeparator: \.isNewline).map(String.init)
        guard lines.count >= 2 else {
            throw PortInspectorError.invalidResponse
        }

        let fields = lines[1].split(whereSeparator: \.isWhitespace).map(String.init)
        guard fields.count >= 9 else {
            throw PortInspectorError.invalidResponse
        }

        let processName = fields[0]
        let pid = Int(fields[1]) ?? 0
        let user = fields[2]
        let protocolName = fields.first(where: { $0 == "TCP" || $0 == "UDP" }) ?? "TCP"
        let endpoint = fields.suffix(2).joined(separator: " ")

        return PortInspectionResult(
            port: port,
            isOccupied: true,
            processName: processName,
            pid: pid,
            user: user,
            protocolName: protocolName,
            command: lines[1],
            endpoint: endpoint
        )
    }

    static func killProcess(pid: Int, force: Bool) throws {
        var arguments = [String]()
        if force {
            arguments.append("-9")
        }
        arguments.append(String(pid))

        _ = try runCommand(launchPath: "/bin/kill", arguments: arguments)
    }

    @discardableResult
    private static func runCommand(launchPath: String, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        let errorOutput = String(decoding: errorData, as: UTF8.self)

        if launchPath.hasSuffix("lsof") {
            if process.terminationStatus == 0 {
                return output
            }
            if process.terminationStatus == 1 {
                return ""
            }
            throw PortInspectorError.commandFailed(errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        guard process.terminationStatus == 0 else {
            throw PortInspectorError.commandFailed(errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return output
    }
}
