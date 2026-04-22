import Combine
import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class PortManagerViewModel: ObservableObject {
    private let languageSettings: AppLanguageSettings

    @Published var portInput = ""
    @Published var items: [Item] = []
    @Published var currentResult: PortInspectionResult?
    @Published var isLoading = false
    @Published var showingForceKillConfirmation = false
    @Published var allListeningPorts: [PortInspectionResult] = []
    @Published var isScanningAll = false
    @Published var selectedPortsForKill: Set<Int> = []
    @Published var portSearchText = ""
    @Published var autoRefreshInterval: TimeInterval = 2  // default 2s
    @Published var launchAtLogin: Bool {
        didSet {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Revert to actual system state on failure
                let actual = (SMAppService.mainApp.status == .enabled)
                if launchAtLogin != actual {
                    launchAtLogin = actual
                }
            }
        }
    }

    @Published private var statusState: StatusState = .prompt
    @Published private var errorState: ErrorState?
    @Published var cliInstalled: Bool = false

    @Published var customQuickPorts: [Int] {
        didSet {
            UserDefaults.standard.set(customQuickPorts, forKey: "portfree.customQuickPorts")
        }
    }

    let defaultQuickPorts = [3000, 5173, 8000, 8080, 8081, 9000]

    var filteredListeningPorts: [PortInspectionResult] {
        guard !portSearchText.isEmpty else { return allListeningPorts }
        let query = portSearchText.lowercased()
        return allListeningPorts.filter {
            String($0.port).contains(query) ||
            $0.processName.lowercased().contains(query)
        }
    }

    private var autoRefreshTask: Task<Void, Never>?
    private var lastPortSnapshot: Set<Int> = []

    var quickPorts: [Int] {
        let merged = defaultQuickPorts + customQuickPorts.filter { !defaultQuickPorts.contains($0) }
        return merged.sorted()
    }

    init(languageSettings: AppLanguageSettings) {
        self.languageSettings = languageSettings
        self.launchAtLogin = (SMAppService.mainApp.status == .enabled)
        self.customQuickPorts = (UserDefaults.standard.array(forKey: "portfree.customQuickPorts") as? [Int]) ?? []
        self.cliInstalled = FileManager.default.fileExists(atPath: "/usr/local/bin/fp")
        let savedInterval = UserDefaults.standard.object(forKey: "portfree.autoRefreshInterval")
        self.autoRefreshInterval = (savedInterval as? TimeInterval) ?? 2
        restartAutoRefresh()
    }

    var statusMessage: String {
        switch statusState {
        case .prompt:
            return languageSettings.text(.appDescription)
        case let .foundProcess(processName, pid):
            return languageSettings.text(.foundProcess, [processName, String(pid)])
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
        let targetPort = result.port

        errorState = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await Task.detached(priority: .userInitiated) {
                try PortInspector.killProcess(pid: result.pid, force: force)
            }.value

            statusState = force ? .forceEnded(port: targetPort) : .ended(port: targetPort)
            insertHistory(port: targetPort, result: result, actionType: force ? "forceTerminate" : "terminate", status: "success")

            // Only refresh if user hasn't switched to a different port
            if portInput == String(targetPort) {
                do {
                    let refreshed = try await Task.detached(priority: .userInitiated) {
                        try PortInspector.inspect(port: targetPort)
                    }.value
                    currentResult = refreshed
                } catch {
                    currentResult = nil
                }
            }
        } catch {
            // If normal kill fails (e.g. Permission Denied), try with admin privileges on main thread
            do {
                try PortInspector.killProcessWithAdmin(pid: result.pid, force: force)

                statusState = force ? .forceEnded(port: targetPort) : .ended(port: targetPort)
                insertHistory(port: targetPort, result: result, actionType: force ? "forceTerminate" : "terminate", status: "success")

                if portInput == String(targetPort) {
                    do {
                        let refreshed = try await Task.detached(priority: .userInitiated) {
                            try PortInspector.inspect(port: targetPort)
                        }.value
                        currentResult = refreshed
                    } catch {
                        currentResult = nil
                    }
                }
            } catch {
                errorState = readableErrorState(error)
                statusState = force ? .forceEndFailed : .endFailed
                insertHistory(port: targetPort, result: result, actionType: force ? "forceTerminate" : "terminate", status: "failed")
            }
        }
    }

    func scanAllPorts() async {
        isScanningAll = true
        defer { isScanningAll = false }

        do {
            let results = try await Task.detached(priority: .utility) {
                try PortInspector.scanAllListening()
            }.value
            let sorted = results.sorted { $0.port < $1.port }

            // Diff check: skip UI & widget update if ports unchanged
            let newSnapshot = Set(sorted.map(\.port))
            if newSnapshot == lastPortSnapshot && sorted.count == allListeningPorts.count {
                return
            }
            lastPortSnapshot = newSnapshot

            allListeningPorts = sorted
            // Share data with widget
            let entries = sorted.map {
                PortFreeShared.PortEntry(port: $0.port, processName: $0.processName, pid: $0.pid, user: $0.user)
            }
            PortFreeShared.savePorts(entries)
        } catch {
            allListeningPorts = []
        }
    }

    func copyProcessInfo() {
        guard let result = currentResult, result.isOccupied else { return }
        let info = """
        Port: \(result.port)
        Process: \(result.processName)
        PID: \(result.pid)
        User: \(result.user)
        Protocol: \(result.protocolName)
        Endpoint: \(result.endpoint)
        Command: \(result.command)
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(info, forType: .string)
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

    func clearAllHistory() {
        withAnimation {
            items.removeAll()
        }
    }

    func addCustomPort(_ port: Int) {
        guard (1...65535).contains(port), !customQuickPorts.contains(port) else { return }
        customQuickPorts.append(port)
    }

    func removeCustomPort(_ port: Int) {
        customQuickPorts.removeAll { $0 == port }
    }

    func installCLI() {
        guard let scriptURL = Bundle.main.url(forResource: "fp", withExtension: nil) else { return }
        let src = scriptURL.path.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let dest = "/usr/local/bin/fp"
        let mkdir = "/bin/mkdir -p /usr/local/bin"
        let appleScript = "do shell script \"\(mkdir) && /bin/cp \\\"\(src)\\\" \\\"\(dest)\\\" && /bin/chmod +x \\\"\(dest)\\\"\" with administrator privileges"
        var errorInfo: NSDictionary?
        NSAppleScript(source: appleScript)?.executeAndReturnError(&errorInfo)
        cliInstalled = FileManager.default.fileExists(atPath: dest)
    }

    func uninstallCLI() {
        let appleScript = "do shell script \"/bin/rm -f /usr/local/bin/fp\" with administrator privileges"
        var errorInfo: NSDictionary?
        NSAppleScript(source: appleScript)?.executeAndReturnError(&errorInfo)
        cliInstalled = FileManager.default.fileExists(atPath: "/usr/local/bin/fp")
    }

    func killSelectedPorts() async {
        let pidsToKill = allListeningPorts
            .filter { selectedPortsForKill.contains($0.port) && $0.isOccupied }
            .map { (pid: $0.pid, port: $0.port, processName: $0.processName) }

        guard !pidsToKill.isEmpty else { return }

        let uniquePids = Set(pidsToKill.map(\.pid))

        for pid in uniquePids {
            do {
                try await Task.detached(priority: .userInitiated) {
                    try PortInspector.killProcess(pid: pid, force: false)
                }.value
            } catch {
                try? PortInspector.killProcessWithAdmin(pid: pid, force: false)
            }
        }

        selectedPortsForKill.removeAll()
        await scanAllPorts()
    }

    func setAutoRefreshInterval(_ interval: TimeInterval) {
        autoRefreshInterval = interval
        UserDefaults.standard.set(interval, forKey: "portfree.autoRefreshInterval")
        restartAutoRefresh()
    }

    func restartAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil

        guard autoRefreshInterval > 0 else { return }

        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64((self?.autoRefreshInterval ?? 5) * 1_000_000_000))
                guard !Task.isCancelled else { break }
                // Skip if app is not active (saves CPU when minimized/hidden)
                guard NSApplication.shared.isActive else { continue }
                await self?.scanAllPorts()
            }
        }
    }

    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    func recentItems(limit: Int) -> [Item] {
        Array(items.prefix(limit))
    }

    var forceKillMessage: String {
        guard let result = currentResult else {
            return languageSettings.text(.forceKillMessageDefault)
        }
        return languageSettings.text(.forceKillMessageDetail, [result.processName, String(result.pid)])
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
        if items.count > 100 {
            items = Array(items.prefix(100))
        }
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
                return message.isEmpty ? "Command execution failed" : message
            case .invalidResponse:
                return "System returned unparseable port information"
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

    nonisolated static func killProcessWithAdmin(pid: Int, force: Bool) throws {
        // pid is already validated as Int, safe from injection
        guard pid > 0 else {
            throw PortInspectorError.commandFailed("Invalid PID")
        }
        let killCmd = force ? "kill -9 \(pid)" : "kill \(pid)"
        let script = "do shell script \"\(killCmd)\" with administrator privileges"
        var errorInfo: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let msg = errorInfo[NSAppleScript.errorMessage] as? String ?? "Authorization failed"
            throw PortInspectorError.commandFailed(msg)
        }
    }

    nonisolated static func scanAllListening() throws -> [PortInspectionResult] {
        let output = try runCommand(
            launchPath: "/usr/sbin/lsof",
            arguments: ["-nP", "-iTCP", "-sTCP:LISTEN"]
        )

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return []
        }

        let lines = trimmed.split(whereSeparator: \.isNewline).map(String.init)
        guard lines.count >= 2 else {
            return []
        }

        var results: [PortInspectionResult] = []
        var seenPorts: Set<Int> = []

        for line in lines.dropFirst() {
            let fields = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard fields.count >= 9 else { continue }

            let processName = fields[0]
            let pid = Int(fields[1]) ?? 0
            let user = fields[2]
            let protocolName = fields.first(where: { $0 == "TCP" || $0 == "UDP" }) ?? "TCP"

            // lsof NAME column is the last field (contains "(LISTEN)").
            // The second-to-last field is the endpoint like "*:8080" or "[::1]:5173".
            // Extract port from the endpoint field by finding the last colon.
            let nameField: String
            if fields.count >= 2 {
                // The state "(LISTEN)" is the last field; endpoint is second-to-last
                let candidateEndpoint = fields[fields.count - 2]
                // Also handle cases where "(LISTEN)" is merged: e.g. "*:8080(LISTEN)"
                let lastField = fields[fields.count - 1]
                if lastField.contains("LISTEN") {
                    nameField = candidateEndpoint
                } else if candidateEndpoint.contains("LISTEN") {
                    // State merged with endpoint in the same field
                    nameField = candidateEndpoint.replacingOccurrences(of: "(LISTEN)", with: "")
                } else {
                    nameField = ""
                }
            } else {
                nameField = ""
            }
            let endpoint = nameField.isEmpty ? "-" : nameField

            let portString: String
            if let colonIndex = nameField.lastIndex(of: ":") {
                portString = String(nameField[nameField.index(after: colonIndex)...])
            } else {
                portString = ""
            }
            guard let port = Int(portString), port > 0 else { continue }

            // Deduplicate by port number (keep first occurrence)
            guard !seenPorts.contains(port) else { continue }
            seenPorts.insert(port)

            results.append(PortInspectionResult(
                port: port,
                isOccupied: true,
                processName: processName,
                pid: pid,
                user: user,
                protocolName: protocolName,
                command: line,
                endpoint: endpoint
            ))
        }

        return results
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

        // Read pipe data asynchronously to prevent deadlock when the pipe
        // buffer fills before the process exits.
        var outputData = Data()
        var errorData = Data()
        let outputHandle = outputPipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading

        let group = DispatchGroup()

        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            outputData = outputHandle.readDataToEndOfFile()
            group.leave()
        }

        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            errorData = errorHandle.readDataToEndOfFile()
            group.leave()
        }

        try process.run()
        process.waitUntilExit()
        group.wait()

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
