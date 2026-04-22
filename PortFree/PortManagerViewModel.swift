import Combine
import Foundation
import SwiftUI

@MainActor
final class PortManagerViewModel: ObservableObject {
    @Published var portInput = ""
    @Published var items: [Item] = []
    @Published var currentResult: PortInspectionResult?
    @Published var statusMessage = "输入端口号后开始检查"
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var showingForceKillConfirmation = false

    let quickPorts = [3000, 5173, 8000, 8080, 8081, 9000]

    func fillPortAndCheck(_ port: Int) {
        portInput = String(port)
        Task {
            await inspectCurrentPort()
        }
    }

    func inspectCurrentPort() async {
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

    func inspect(port: Int) {
        fillPortAndCheck(port)
    }

    func killCurrentProcess(force: Bool) async {
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

    func deleteRecentItems(offsets: IndexSet, limit: Int = 12) {
        let visibleItems = Array(items.prefix(limit))
        withAnimation {
            for index in offsets {
                guard visibleItems.indices.contains(index) else { continue }
                let itemID = visibleItems[index].id
                items.removeAll { $0.id == itemID }
            }
        }
    }

    func recentItems(limit: Int) -> [Item] {
        Array(items.prefix(limit))
    }

    var forceKillMessage: String {
        guard let result = currentResult else {
            return "将执行 kill -9。"
        }
        return "将对 \(result.processName) (PID \(result.pid)) 执行 kill -9。"
    }

    func historySubtitle(for item: Item) -> String {
        let processPart = item.processName == "-" ? "无进程信息" : item.processName
        let pidPart = item.pid.map { "PID \($0)" } ?? "PID -"
        return "\(processPart) · \(pidPart) · \(item.resultStatus)"
    }

    func readableError(_ error: Error) -> String {
        if let inspectorError = error as? PortInspector.PortInspectorError {
            return inspectorError.errorDescription ?? "未知错误"
        }

        return error.localizedDescription
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
}

struct PortInspectionResult: Sendable {
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

enum PortInspector {
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
