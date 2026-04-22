//
//  ContentView.swift
//  PortFree
//
//  Created by JIANGJINGZHE on 22/4/2026.
//

import AppKit
import Foundation
import SwiftUI

struct ContentView: View {
    @State private var portInput = ""
    @State private var items: [Item] = []
    @State private var currentResult: PortInspectionResult?
    @State private var statusMessage = "输入端口号后开始检查"
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showingForceKillAlert = false

    private let quickPorts = [3000, 5173, 8000, 8080, 8081, 9000]
    private let timestampFormatter = Item.timestampFormatter

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 260)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    portInputSection
                    resultSection
                }
                .padding(24)
                .frame(maxWidth: 760, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 960, minHeight: 620)
        .background(Color.white.opacity(0.001))
        .alert(isPresented: $showingForceKillAlert) {
            Alert(
                title: Text("确认强制结束该进程？"),
                message: Text(forceKillMessage),
                primaryButton: .destructive(Text("强制结束")) {
                    killCurrentProcess(force: true)
                },
                secondaryButton: .cancel(Text("取消"))
            )
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
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Section(header: Text("最近记录")) {
                if items.isEmpty {
                    Text("还没有操作记录")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(items.prefix(12))) { item in
                        Button(action: {
                            fillPortAndCheck(item.port)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(item.actionType) · 端口 \(item.port)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(historySubtitle(for: item))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(timestampFormatter.string(from: item.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete(perform: deleteItems)
                }
            }
        }
        .listStyle(SidebarListStyle())
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快速释放被占用端口")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("输入端口号后检查占用进程，并可执行普通结束或强制结束。")
                .foregroundColor(.secondary)
        }
    }

    private var portInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("检查端口")
                .font(.headline)

            HStack(spacing: 12) {
                TextField("例如 3000、8080、5173", text: $portInput, onCommit: inspectCurrentPort)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 240)

                Button("检查端口") {
                    inspectCurrentPort()
                }
                .disabled(isLoading)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.subheadline)
            } else {
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
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
                            .foregroundColor(result.isOccupied ? .orange : .green)
                    }

                    Spacer()

                    Label(result.protocolName, systemImage: result.isOccupied ? "network" : "checkmark.circle")
                        .foregroundColor(.secondary)
                }

                Divider()

                if result.isOccupied {
                    detailRow(title: "进程", value: result.processName)
                    detailRow(title: "PID", value: String(result.pid))
                    detailRow(title: "用户", value: result.user)
                    detailRow(title: "命令", value: result.command)
                    detailRow(title: "端口描述", value: result.endpoint)

                    HStack(spacing: 12) {
                        Button("结束进程") {
                            killCurrentProcess(force: false)
                        }
                        .disabled(isLoading)

                        Button("强制结束") {
                            showingForceKillAlert = true
                        }
                        .foregroundColor(.red)
                        .disabled(isLoading)
                    }
                } else {
                    Label("该端口当前未发现占用进程", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Label("尚未检查端口", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.title3)
                Text("输入端口号，或点击左侧常用端口快速开始。")
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
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
        inspectCurrentPort()
    }

    private func inspectCurrentPort() {
        errorMessage = nil

        guard let port = validatedPort() else {
            currentResult = nil
            return
        }

        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try PortInspector.inspect(port: port)
                DispatchQueue.main.async {
                    currentResult = result
                    statusMessage = result.isOccupied ? "发现占用进程：\(result.processName) (PID \(result.pid))" : "端口 \(port) 当前空闲"
                    insertHistory(port: port, result: result, actionType: "查询", status: result.isOccupied ? "occupied" : "free")
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    currentResult = nil
                    errorMessage = readableError(error)
                    statusMessage = "检查失败"
                    insertHistory(port: port, result: nil, actionType: "查询", status: "failed")
                    isLoading = false
                }
            }
        }
    }

    private func killCurrentProcess(force: Bool) {
        guard let result = currentResult, result.isOccupied else { return }

        errorMessage = nil
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try PortInspector.killProcess(pid: result.pid, force: force)
                let refreshed = try? PortInspector.inspect(port: result.port)
                DispatchQueue.main.async {
                    let actionTitle = force ? "强制结束" : "结束"
                    statusMessage = "已成功\(actionTitle)进程并释放端口 \(result.port)"
                    insertHistory(port: result.port, result: result, actionType: force ? "强制结束" : "结束", status: "success")
                    currentResult = refreshed
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = readableError(error)
                    statusMessage = force ? "强制结束失败" : "结束失败"
                    insertHistory(port: result.port, result: result, actionType: force ? "强制结束" : "结束", status: "failed")
                    isLoading = false
                }
            }
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
