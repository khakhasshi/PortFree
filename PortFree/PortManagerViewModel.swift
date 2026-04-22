import Combine
import Foundation
import SwiftUI

@MainActor
final class PortManagerViewModel: ObservableObject {
    private let languageSettings: AppLanguageSettings

    @Published var portInput = ""
    @Published var items: [Item] = []
    @Published var currentResult: PortInspectionResult?
    @Published var isLoading = false
    @Published var showingForceKillConfirmation = false

    @Published private var statusState: StatusState = .prompt
    @Published private var errorState: ErrorState?

    let quickPorts = [3000, 5173, 8000, 8080, 8081, 9000]

    init(languageSettings: AppLanguageSettings) {
        self.languageSettings = languageSettings
    }

    var statusMessage: String {
        switch statusState {
        case .prompt:
            return languageSettings.text(.appDescription)
        case let .foundProcess(processName, pid):
            return languageSettings.text(.foundProcess, [processName, pid])
        case let .portFree(port):
            return languageSettings.text(.portFreeStatus, [languageSettings.plainNumber(port)])
        case .inspectFailed:
            return languageSettings.text(.inspectFailed)
        case let .ended(port):
            return languageSettings.text(.processEndedSuccess, [languageSettings.plainNumber(port)])
        case let .forceEnded(port):
            return languageSettings.text(.processForceEndedSuccess, [languageSettings.plainNumber(port)])
        case .endFailed:
            return languageSettings.text(.processEndedFailed)
        case .forceEndFailed:
            return languageSettings.text(.processForceEndedFailed)
        }
    }

    var errorMessage: String? {
        guard let errorState else {
            return nil
        }

        switch errorState {
        case .enterPortFirst:
            return languageSettings.text(.enterPortFirst)
        case .invalidPortRange:
            return languageSettings.text(.invalidPortRange)
        case let .inspectorError(inspectorError):
            switch inspectorError {
            case let .commandFailed(message):
                return message.isEmpty ? languageSettings.text(.commandFailed) : message
            case .invalidResponse:
                return languageSettings.text(.invalidPortInfo)
            }
        case let .generic(message):
            return message
        }
    }

    func fillPortAndCheck(_ port: Int) {
        portInput = String(port)
        Task {
            await inspectCurrentPort()
        }
    }

    func inspectCurrentPort() async {
        errorState = nil

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
            statusState = result.isOccupied ? .foundProcess(processName: result.processName, pid: result.pid) : .portFree(port: port)
            insertHistory(port: port, result: result, actionType: "inspect", status: result.isOccupied ? "occupied" : "free")
        } catch {
            currentResult = nil
            errorState = readableErrorState(error)
            statusState = .inspectFailed
            insertHistory(port: port, result: nil, actionType: "inspect", status: "failed")
        }
    }

    func inspect(port: Int) {
        fillPortAndCheck(port)
    }

    func killCurrentProcess(force: Bool) async {
        guard let result = currentResult, result.isOccupied else { return }

        errorState = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await Task.detached(priority: .userInitiated) {
                try PortInspector.killProcess(pid: result.pid, force: force)
            }.value

            statusState = force ? .forceEnded(port: result.port) : .ended(port: result.port)
            insertHistory(port: result.port, result: result, actionType: force ? "forceTerminate" : "terminate", status: "success")

            do {
                let refreshed = try await Task.detached(priority: .userInitiated) {
                    try PortInspector.inspect(port: result.port)
                }.value
                currentResult = refreshed
            } catch {
                currentResult = nil
            }
        } catch {
            errorState = readableErrorState(error)
            statusState = force ? .forceEndFailed : .endFailed
            insertHistory(port: result.port, result: result, actionType: force ? "forceTerminate" : "terminate", status: "failed")
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
            return languageSettings.text(.forceKillMessageDefault)
        }
        return languageSettings.text(.forceKillMessageDetail, [result.processName, result.pid])
    }

    func historySubtitle(for item: Item) -> String {
        let processPart = item.processName == "-" ? languageSettings.text(.noProcessInfo) : item.processName
        let pidPart = item.pid.map { "PID \($0)" } ?? "PID -"
        return "\(processPart) · \(pidPart) · \(languageSettings.historyStatusTitle(item.resultStatus))"
    }

    func historyActionTitle(for item: Item) -> String {
        languageSettings.historyActionTitle(item.actionType)
    }

    private func validatedPort() -> Int? {
        let normalizedInput = normalizedPortInput(from: portInput)

        guard !normalizedInput.isEmpty else {
            errorState = .enterPortFirst
            return nil
        }

        if normalizedInput != portInput {
            portInput = normalizedInput
        }

        guard let port = Int(normalizedInput), (1...65535).contains(port) else {
            errorState = .invalidPortRange
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

    private func readableErrorState(_ error: Error) -> ErrorState {
        if let inspectorError = error as? PortInspector.PortInspectorError {
            return .inspectorError(inspectorError)
        }

        let description = error.localizedDescription
        return description.isEmpty ? .generic(languageSettings.text(.unknownError)) : .generic(description)
    }

    private func normalizedPortInput(from value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "，", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

private extension PortManagerViewModel {
    enum StatusState {
        case prompt
        case foundProcess(processName: String, pid: Int)
        case portFree(port: Int)
        case inspectFailed
        case ended(port: Int)
        case forceEnded(port: Int)
        case endFailed
        case forceEndFailed
    }

    enum ErrorState {
        case enterPortFirst
        case invalidPortRange
        case inspectorError(PortInspector.PortInspectorError)
        case generic(String)
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

    nonisolated static func free(port: Int) -> PortInspectionResult {
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

        nonisolated var errorDescription: String? {
            switch self {
            case let .commandFailed(message):
                return message.isEmpty ? "命令执行失败" : message
            case .invalidResponse:
                return "系统返回了无法解析的端口信息"
            }
        }
    }

    nonisolated static func inspect(port: Int) throws -> PortInspectionResult {
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

    nonisolated static func killProcess(pid: Int, force: Bool) throws {
        var arguments = [String]()
        if force {
            arguments.append("-9")
        }
        arguments.append(String(pid))

        _ = try runCommand(launchPath: "/bin/kill", arguments: arguments)
    }

    @discardableResult
    nonisolated private static func runCommand(launchPath: String, arguments: [String]) throws -> String {
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
