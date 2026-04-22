import Combine
import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case german = "de"
    case french = "fr"
    case spanish = "es"

    var id: String { rawValue }

    var localeIdentifier: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁體中文"
        case .japanese:
            return "日本語"
        case .german:
            return "Deutsch"
        case .french:
            return "Français"
        case .spanish:
            return "Español"
        }
    }
}

enum AppLanguagePreference: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case german = "de"
    case french = "fr"
    case spanish = "es"

    var id: String { rawValue }

    var language: AppLanguage? {
        switch self {
        case .system:
            return nil
        case .english:
            return .english
        case .simplifiedChinese:
            return .simplifiedChinese
        case .traditionalChinese:
            return .traditionalChinese
        case .japanese:
            return .japanese
        case .german:
            return .german
        case .french:
            return .french
        case .spanish:
            return .spanish
        }
    }
}

enum AppTextKey: String {
    case language
    case languageSettings
    case followSystem
    case quickMenuTitle
    case appDescription
    case commonPorts
    case recentHistory
    case noHistory
    case noRecentRecords
    case portWithNumber
    case portManagement
    case releaseOccupiedPort
    case releaseOccupiedPortSubtitle
    case inspectPort
    case inspectPortButton
    case portPlaceholder
    case quickPorts
    case occupied
    case available
    case currentlyOccupied
    case currentlyFree
    case process
    case pid
    case user
    case `protocol`
    case endpoint
    case command
    case endProcess
    case forceEnd
    case processEnded
    case noProcessDetected
    case notCheckedYet
    case notCheckedYetDescription
    case openMainWindow
    case quitApp
    case enterPortFirst
    case invalidPortRange
    case foundProcess
    case portFreeStatus
    case inspectFailed
    case processEndedSuccess
    case processForceEndedSuccess
    case processEndedFailed
    case processForceEndedFailed
    case forceKillConfirmTitle
    case forceKillConfirmButton
    case cancel
    case forceKillMessageDefault
    case forceKillMessageDetail
    case noProcessInfo
    case unknownError
    case invalidPortInfo
    case commandFailed
    case historyStatusFree
    case historyStatusOccupied
    case historyStatusSuccess
    case historyStatusFailed
    case historyActionInspect
    case historyActionTerminate
    case historyActionForceTerminate
    case allListeningPorts
    case scanAllPorts
    case scanning
    case noListeningPorts
    case portCount
    case launchAtLogin
    case copyInfo
    case copiedToClipboard
    case globalHotkeyHint
    case adminRequired
    case settings
}

@MainActor
final class AppLanguageSettings: ObservableObject {
    @Published var languagePreference: AppLanguagePreference {
        didSet {
            UserDefaults.standard.set(languagePreference.rawValue, forKey: storageKey)
        }
    }

    private let storageKey = "portfree.appLanguage"

    init() {
        let storedCode = UserDefaults.standard.string(forKey: storageKey)
        languagePreference = AppLanguagePreference(rawValue: storedCode ?? "") ?? .system
    }

    var currentLanguage: AppLanguage {
        languagePreference.language ?? Self.systemPreferredLanguage()
    }

    private static func systemPreferredLanguage() -> AppLanguage {
        for identifier in Locale.preferredLanguages {
            let locale = Locale(identifier: identifier)
            let normalizedIdentifier = locale.identifier.lowercased()
            let languageCode = locale.language.languageCode?.identifier.lowercased() ?? ""
            let scriptCode = locale.language.script?.identifier.lowercased() ?? ""

            if normalizedIdentifier.contains("hant") || scriptCode == "hant" {
                return .traditionalChinese
            }

            if normalizedIdentifier.contains("hans") || scriptCode == "hans" {
                return .simplifiedChinese
            }

            switch languageCode {
            case "en":
                return .english
            case "zh":
                return .simplifiedChinese
            case "ja":
                return .japanese
            case "de":
                return .german
            case "fr":
                return .french
            case "es":
                return .spanish
            default:
                continue
            }
        }

        return .english
    }

    func text(_ key: AppTextKey, _ arguments: [CVarArg] = []) -> String {
        let format = AppTranslations.table[currentLanguage]?[key.rawValue]
            ?? AppTranslations.table[.english]?[key.rawValue]
            ?? key.rawValue

        guard !arguments.isEmpty else {
            return format
        }

        return String(format: format, locale: Locale(identifier: currentLanguage.localeIdentifier), arguments: arguments)
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguage.localeIdentifier)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func plainNumber(_ value: Int) -> String {
        String(value)
    }

    func historyActionTitle(_ code: String) -> String {
        switch code {
        case "inspect":
            return text(.historyActionInspect)
        case "terminate":
            return text(.historyActionTerminate)
        case "forceTerminate":
            return text(.historyActionForceTerminate)
        default:
            return code
        }
    }

    func historyStatusTitle(_ code: String) -> String {
        switch code {
        case "free":
            return text(.historyStatusFree)
        case "occupied":
            return text(.historyStatusOccupied)
        case "success":
            return text(.historyStatusSuccess)
        case "failed":
            return text(.historyStatusFailed)
        default:
            return code
        }
    }
}

struct LanguageMenuButton: View {
    @EnvironmentObject private var languageSettings: AppLanguageSettings

    let showsTitle: Bool

    init(showsTitle: Bool = true) {
        self.showsTitle = showsTitle
    }

    var body: some View {
        Menu {
            ForEach(AppLanguagePreference.allCases) { preference in
                Button {
                    languageSettings.languagePreference = preference
                } label: {
                    HStack {
                        Text(title(for: preference))
                        if preference == languageSettings.languagePreference {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            if showsTitle {
                Label(languageSettings.text(.language), systemImage: "globe")
            } else {
                Image(systemName: "globe")
                    .accessibilityLabel(languageSettings.text(.languageSettings))
            }
        }
        .help(languageSettings.text(.languageSettings))
    }

    private func title(for preference: AppLanguagePreference) -> String {
        switch preference {
        case .system:
            return languageSettings.text(.followSystem)
        default:
            return preference.language?.displayName ?? languageSettings.text(.followSystem)
        }
    }
}

enum AppTranslations {
    static let table: [AppLanguage: [String: String]] = [
        .english: [
            "language": "Language",
            "languageSettings": "Language settings",
            "followSystem": "Follow System",
            "quickMenuTitle": "PortFree Quick Menu",
            "appDescription": "Check a port and stop the occupying process if needed.",
            "commonPorts": "Common Ports",
            "recentHistory": "Recent History",
            "noHistory": "No history yet",
            "noRecentRecords": "No recent records",
            "portWithNumber": "Port %@",
            "portManagement": "Port Manager",
            "releaseOccupiedPort": "Free Occupied Ports Fast",
            "releaseOccupiedPortSubtitle": "Enter a port number to inspect the process and end it normally or forcefully.",
            "inspectPort": "Inspect Port",
            "inspectPortButton": "Inspect",
            "portPlaceholder": "e.g. 3000, 8080, 5173",
            "quickPorts": "Quick Ports",
            "occupied": "Occupied",
            "available": "Available",
            "currentlyOccupied": "Currently occupied",
            "currentlyFree": "Currently free",
            "process": "Process",
            "pid": "PID",
            "user": "User",
            "protocol": "Protocol",
            "endpoint": "Endpoint",
            "command": "Command",
            "endProcess": "End Process",
            "forceEnd": "Force End",
            "processEnded": "Process ended",
            "noProcessDetected": "No process is using this port right now",
            "notCheckedYet": "No port checked yet",
            "notCheckedYetDescription": "Enter a port number or use a quick port to begin.",
            "openMainWindow": "Open Main Window",
            "quitApp": "Quit PortFree",
            "enterPortFirst": "Please enter a port number",
            "invalidPortRange": "Port must be a number between 1 and 65535",
            "foundProcess": "Found process: %@ (PID %d)",
            "portFreeStatus": "Port %@ is currently free",
            "inspectFailed": "Inspection failed",
            "processEndedSuccess": "Successfully ended the process and freed port %@",
            "processForceEndedSuccess": "Successfully force-ended the process and freed port %@",
            "processEndedFailed": "Failed to end process",
            "processForceEndedFailed": "Failed to force-end process",
            "forceKillConfirmTitle": "Force end this process?",
            "forceKillConfirmButton": "Force End",
            "cancel": "Cancel",
            "forceKillMessageDefault": "This will run kill -9.",
            "forceKillMessageDetail": "This will run kill -9 on %@ (PID %d).",
            "noProcessInfo": "No process info",
            "unknownError": "Unknown error",
            "invalidPortInfo": "The system returned port information that could not be parsed",
            "commandFailed": "Command execution failed",
            "historyStatusFree": "free",
            "historyStatusOccupied": "occupied",
            "historyStatusSuccess": "success",
            "historyStatusFailed": "failed",
            "historyActionInspect": "Inspect",
            "historyActionTerminate": "End",
            "historyActionForceTerminate": "Force End",
            "allListeningPorts": "All Listening Ports",
            "scanAllPorts": "Scan All Ports",
            "scanning": "Scanning…",
            "noListeningPorts": "No listening ports detected",
            "portCount": "%@ ports listening",
            "launchAtLogin": "Launch at Login",
            "copyInfo": "Copy Info",
            "copiedToClipboard": "Copied to clipboard",
            "globalHotkeyHint": "Press ⌘⇧P anywhere to open PortFree",
            "adminRequired": "Admin privileges required",
            "settings": "Settings"
        ],
        .simplifiedChinese: [
            "language": "语言",
            "languageSettings": "语言设置",
            "followSystem": "跟随系统",
            "quickMenuTitle": "PortFree 快捷菜单",
            "appDescription": "检查端口占用并按需结束对应进程。",
            "commonPorts": "常用端口",
            "recentHistory": "最近记录",
            "noHistory": "还没有操作记录",
            "noRecentRecords": "暂无记录",
            "portWithNumber": "端口 %@",
            "portManagement": "端口管理",
            "releaseOccupiedPort": "快速释放被占用端口",
            "releaseOccupiedPortSubtitle": "输入端口号后检查占用进程，并可执行普通结束或强制结束。",
            "inspectPort": "检查端口",
            "inspectPortButton": "检查",
            "portPlaceholder": "例如 3000、8080、5173",
            "quickPorts": "快捷端口",
            "occupied": "已占用",
            "available": "可用",
            "currentlyOccupied": "当前已被占用",
            "currentlyFree": "当前空闲",
            "process": "进程",
            "pid": "PID",
            "user": "用户",
            "protocol": "协议",
            "endpoint": "端口描述",
            "command": "命令",
            "endProcess": "结束进程",
            "forceEnd": "强制结束",
            "processEnded": "已结束",
            "noProcessDetected": "该端口当前未发现占用进程",
            "notCheckedYet": "尚未检查端口",
            "notCheckedYetDescription": "输入端口号，或点击上方快捷端口快速开始。",
            "openMainWindow": "打开主窗口",
            "quitApp": "退出 PortFree",
            "enterPortFirst": "请输入端口号",
            "invalidPortRange": "端口号必须是 1 到 65535 之间的数字",
            "foundProcess": "发现占用进程：%@ (PID %d)",
            "portFreeStatus": "端口 %@ 当前空闲",
            "inspectFailed": "检查失败",
            "processEndedSuccess": "已成功结束进程并释放端口 %@",
            "processForceEndedSuccess": "已成功强制结束进程并释放端口 %@",
            "processEndedFailed": "结束失败",
            "processForceEndedFailed": "强制结束失败",
            "forceKillConfirmTitle": "确认强制结束该进程？",
            "forceKillConfirmButton": "强制结束",
            "cancel": "取消",
            "forceKillMessageDefault": "将执行 kill -9。",
            "forceKillMessageDetail": "将对 %@ (PID %d) 执行 kill -9。",
            "noProcessInfo": "无进程信息",
            "unknownError": "未知错误",
            "invalidPortInfo": "系统返回了无法解析的端口信息",
            "commandFailed": "命令执行失败",
            "historyStatusFree": "free",
            "historyStatusOccupied": "occupied",
            "historyStatusSuccess": "success",
            "historyStatusFailed": "failed",
            "historyActionInspect": "查询",
            "historyActionTerminate": "结束",
            "historyActionForceTerminate": "强制结束",
            "allListeningPorts": "全部监听端口",
            "scanAllPorts": "扫描全部端口",
            "scanning": "扫描中…",
            "noListeningPorts": "未检测到监听中的端口",
            "portCount": "%@ 个端口正在监听",
            "launchAtLogin": "开机自启动",
            "copyInfo": "复制信息",
            "copiedToClipboard": "已复制到剪贴板",
            "globalHotkeyHint": "在任意位置按 ⌘⇧P 唤出 PortFree",
            "adminRequired": "需要管理员权限",
            "settings": "设置"
        ],
        .traditionalChinese: [
            "language": "語言",
            "languageSettings": "語言設定",
            "followSystem": "跟隨系統",
            "quickMenuTitle": "PortFree 快捷選單",
            "appDescription": "檢查連接埠占用並依需要結束對應程序。",
            "commonPorts": "常用連接埠",
            "recentHistory": "最近記錄",
            "noHistory": "尚無操作記錄",
            "noRecentRecords": "暫無記錄",
            "portWithNumber": "連接埠 %@",
            "portManagement": "連接埠管理",
            "releaseOccupiedPort": "快速釋放被占用連接埠",
            "releaseOccupiedPortSubtitle": "輸入連接埠號後檢查占用程序，並可執行一般結束或強制結束。",
            "inspectPort": "檢查連接埠",
            "inspectPortButton": "檢查",
            "portPlaceholder": "例如 3000、8080、5173",
            "quickPorts": "快捷連接埠",
            "occupied": "已占用",
            "available": "可用",
            "currentlyOccupied": "目前已被占用",
            "currentlyFree": "目前空閒",
            "process": "程序",
            "pid": "PID",
            "user": "使用者",
            "protocol": "協定",
            "endpoint": "連接埠描述",
            "command": "命令",
            "endProcess": "結束程序",
            "forceEnd": "強制結束",
            "processEnded": "已結束",
            "noProcessDetected": "目前未發現此連接埠有占用程序",
            "notCheckedYet": "尚未檢查連接埠",
            "notCheckedYetDescription": "輸入連接埠號，或點選上方快捷連接埠快速開始。",
            "openMainWindow": "打開主視窗",
            "quitApp": "退出 PortFree",
            "enterPortFirst": "請輸入連接埠號",
            "invalidPortRange": "連接埠號必須是 1 到 65535 之間的數字",
            "foundProcess": "發現占用程序：%@ (PID %d)",
            "portFreeStatus": "連接埠 %@ 目前空閒",
            "inspectFailed": "檢查失敗",
            "processEndedSuccess": "已成功結束程序並釋放連接埠 %@",
            "processForceEndedSuccess": "已成功強制結束程序並釋放連接埠 %@",
            "processEndedFailed": "結束失敗",
            "processForceEndedFailed": "強制結束失敗",
            "forceKillConfirmTitle": "確認強制結束此程序？",
            "forceKillConfirmButton": "強制結束",
            "cancel": "取消",
            "forceKillMessageDefault": "將執行 kill -9。",
            "forceKillMessageDetail": "將對 %@ (PID %d) 執行 kill -9。",
            "noProcessInfo": "無程序資訊",
            "unknownError": "未知錯誤",
            "invalidPortInfo": "系統回傳了無法解析的連接埠資訊",
            "commandFailed": "命令執行失敗",
            "historyStatusFree": "free",
            "historyStatusOccupied": "occupied",
            "historyStatusSuccess": "success",
            "historyStatusFailed": "failed",
            "historyActionInspect": "查詢",
            "historyActionTerminate": "結束",
            "historyActionForceTerminate": "強制結束",
            "allListeningPorts": "全部監聽連接埠",
            "scanAllPorts": "掃描全部連接埠",
            "scanning": "掃描中…",
            "noListeningPorts": "未偵測到監聽中的連接埠",
            "portCount": "%@ 個連接埠正在監聽",
            "launchAtLogin": "開機自啟動",
            "copyInfo": "複製資訊",
            "copiedToClipboard": "已複製到剪貼簿",
            "globalHotkeyHint": "在任意位置按 ⌘⇧P 呼出 PortFree",
            "adminRequired": "需要管理員權限",
            "settings": "設定"
        ],
        .japanese: [
            "language": "言語",
            "languageSettings": "言語設定",
            "followSystem": "システムに従う",
            "quickMenuTitle": "PortFree クイックメニュー",
            "appDescription": "ポート使用状況を確認し、必要に応じてプロセスを終了します。",
            "commonPorts": "よく使うポート",
            "recentHistory": "最近の履歴",
            "noHistory": "まだ履歴がありません",
            "noRecentRecords": "履歴はありません",
            "portWithNumber": "ポート %@",
            "portManagement": "ポート管理",
            "releaseOccupiedPort": "使用中ポートをすばやく解放",
            "releaseOccupiedPortSubtitle": "ポート番号を入力してプロセスを確認し、通常終了または強制終了できます。",
            "inspectPort": "ポート確認",
            "inspectPortButton": "確認",
            "portPlaceholder": "例: 3000, 8080, 5173",
            "quickPorts": "クイックポート",
            "occupied": "使用中",
            "available": "利用可能",
            "currentlyOccupied": "現在使用中",
            "currentlyFree": "現在空き",
            "process": "プロセス",
            "pid": "PID",
            "user": "ユーザー",
            "protocol": "プロトコル",
            "endpoint": "ポート情報",
            "command": "コマンド",
            "endProcess": "終了",
            "forceEnd": "強制終了",
            "processEnded": "終了済み",
            "noProcessDetected": "このポートを使用しているプロセスは見つかりませんでした",
            "notCheckedYet": "まだポートを確認していません",
            "notCheckedYetDescription": "ポート番号を入力するか、上のクイックポートを使って開始してください。",
            "openMainWindow": "メインウィンドウを開く",
            "quitApp": "PortFree を終了",
            "enterPortFirst": "ポート番号を入力してください",
            "invalidPortRange": "ポート番号は 1 から 65535 の数字である必要があります",
            "foundProcess": "使用中プロセス: %@ (PID %d)",
            "portFreeStatus": "ポート %@ は現在空いています",
            "inspectFailed": "確認に失敗しました",
            "processEndedSuccess": "プロセスを終了し、ポート %@ を解放しました",
            "processForceEndedSuccess": "プロセスを強制終了し、ポート %@ を解放しました",
            "processEndedFailed": "終了に失敗しました",
            "processForceEndedFailed": "強制終了に失敗しました",
            "forceKillConfirmTitle": "このプロセスを強制終了しますか？",
            "forceKillConfirmButton": "強制終了",
            "cancel": "キャンセル",
            "forceKillMessageDefault": "kill -9 を実行します。",
            "forceKillMessageDetail": "%@ (PID %d) に kill -9 を実行します。",
            "noProcessInfo": "プロセス情報なし",
            "unknownError": "不明なエラー",
            "invalidPortInfo": "解析できないポート情報が返されました",
            "commandFailed": "コマンドの実行に失敗しました",
            "historyStatusFree": "free",
            "historyStatusOccupied": "occupied",
            "historyStatusSuccess": "success",
            "historyStatusFailed": "failed",
            "historyActionInspect": "確認",
            "historyActionTerminate": "終了",
            "historyActionForceTerminate": "強制終了",
            "allListeningPorts": "すべての待ち受けポート",
            "scanAllPorts": "全ポートをスキャン",
            "scanning": "スキャン中…",
            "noListeningPorts": "待ち受け中のポートは見つかりませんでした",
            "portCount": "%@ ポートが待ち受け中",
            "launchAtLogin": "ログイン時に起動",
            "copyInfo": "コピー",
            "copiedToClipboard": "クリップボードにコピーしました",
            "globalHotkeyHint": "どこからでも ⌘⇧P で PortFree を呼び出せます",
            "adminRequired": "管理者権限が必要です",
            "settings": "設定"
        ],
        .german: [
            "language": "Sprache",
            "languageSettings": "Spracheinstellungen",
            "followSystem": "Systemsprache verwenden",
            "quickMenuTitle": "PortFree-Schnellmenü",
            "appDescription": "Portbelegung prüfen und den zugehörigen Prozess bei Bedarf beenden.",
            "commonPorts": "Häufige Ports",
            "recentHistory": "Letzte Vorgänge",
            "noHistory": "Noch keine Einträge",
            "noRecentRecords": "Keine Einträge",
            "portWithNumber": "Port %@",
            "portManagement": "Portverwaltung",
            "releaseOccupiedPort": "Belegte Ports schnell freigeben",
            "releaseOccupiedPortSubtitle": "Portnummer eingeben, Prozess prüfen und normal oder erzwungen beenden.",
            "inspectPort": "Port prüfen",
            "inspectPortButton": "Prüfen",
            "portPlaceholder": "z. B. 3000, 8080, 5173",
            "quickPorts": "Schnellports",
            "occupied": "Belegt",
            "available": "Verfügbar",
            "currentlyOccupied": "Derzeit belegt",
            "currentlyFree": "Derzeit frei",
            "process": "Prozess",
            "pid": "PID",
            "user": "Benutzer",
            "protocol": "Protokoll",
            "endpoint": "Portdetails",
            "command": "Befehl",
            "endProcess": "Prozess beenden",
            "forceEnd": "Erzwungen beenden",
            "processEnded": "Beendet",
            "noProcessDetected": "Für diesen Port wurde kein Prozess gefunden",
            "notCheckedYet": "Noch kein Port geprüft",
            "notCheckedYetDescription": "Portnummer eingeben oder oben einen Schnellport wählen.",
            "openMainWindow": "Hauptfenster öffnen",
            "quitApp": "PortFree beenden",
            "enterPortFirst": "Bitte eine Portnummer eingeben",
            "invalidPortRange": "Port muss eine Zahl zwischen 1 und 65535 sein",
            "foundProcess": "Gefundener Prozess: %@ (PID %d)",
            "portFreeStatus": "Port %@ ist derzeit frei",
            "inspectFailed": "Prüfung fehlgeschlagen",
            "processEndedSuccess": "Prozess erfolgreich beendet und Port %@ freigegeben",
            "processForceEndedSuccess": "Prozess erfolgreich erzwungen beendet und Port %@ freigegeben",
            "processEndedFailed": "Beenden fehlgeschlagen",
            "processForceEndedFailed": "Erzwungenes Beenden fehlgeschlagen",
            "forceKillConfirmTitle": "Diesen Prozess erzwungen beenden?",
            "forceKillConfirmButton": "Erzwungen beenden",
            "cancel": "Abbrechen",
            "forceKillMessageDefault": "kill -9 wird ausgeführt.",
            "forceKillMessageDetail": "kill -9 wird für %@ (PID %d) ausgeführt.",
            "noProcessInfo": "Keine Prozessinfo",
            "unknownError": "Unbekannter Fehler",
            "invalidPortInfo": "Das System hat nicht auswertbare Portinformationen zurückgegeben",
            "commandFailed": "Befehlsausführung fehlgeschlagen",
            "historyStatusFree": "free",
            "historyStatusOccupied": "occupied",
            "historyStatusSuccess": "success",
            "historyStatusFailed": "failed",
            "historyActionInspect": "Prüfen",
            "historyActionTerminate": "Beenden",
            "historyActionForceTerminate": "Erzwungen beenden",
            "allListeningPorts": "Alle lauschenden Ports",
            "scanAllPorts": "Alle Ports scannen",
            "scanning": "Wird gescannt…",
            "noListeningPorts": "Keine lauschenden Ports gefunden",
            "portCount": "%@ Ports lauschen",
            "launchAtLogin": "Beim Anmelden starten",
            "copyInfo": "Kopieren",
            "copiedToClipboard": "In Zwischenablage kopiert",
            "globalHotkeyHint": "⌘⇧P drücken, um PortFree von überall zu öffnen",
            "adminRequired": "Administratorrechte erforderlich",
            "settings": "Einstellungen"
        ],
        .french: [
            "language": "Langue",
            "languageSettings": "Paramètres de langue",
            "followSystem": "Suivre le système",
            "quickMenuTitle": "Menu rapide PortFree",
            "appDescription": "Vérifiez un port et arrêtez le processus associé si nécessaire.",
            "commonPorts": "Ports courants",
            "recentHistory": "Historique récent",
            "noHistory": "Aucun historique",
            "noRecentRecords": "Aucun enregistrement",
            "portWithNumber": "Port %@",
            "portManagement": "Gestion des ports",
            "releaseOccupiedPort": "Libérer rapidement les ports occupés",
            "releaseOccupiedPortSubtitle": "Entrez un numéro de port pour inspecter le processus et l'arrêter normalement ou de force.",
            "inspectPort": "Vérifier le port",
            "inspectPortButton": "Vérifier",
            "portPlaceholder": "ex. 3000, 8080, 5173",
            "quickPorts": "Ports rapides",
            "occupied": "Occupé",
            "available": "Disponible",
            "currentlyOccupied": "Actuellement occupé",
            "currentlyFree": "Actuellement libre",
            "process": "Processus",
            "pid": "PID",
            "user": "Utilisateur",
            "protocol": "Protocole",
            "endpoint": "Détails du port",
            "command": "Commande",
            "endProcess": "Arrêter le processus",
            "forceEnd": "Forcer l'arrêt",
            "processEnded": "Arrêté",
            "noProcessDetected": "Aucun processus n'utilise actuellement ce port",
            "notCheckedYet": "Aucun port vérifié",
            "notCheckedYetDescription": "Entrez un numéro de port ou utilisez un port rapide pour commencer.",
            "openMainWindow": "Ouvrir la fenêtre principale",
            "quitApp": "Quitter PortFree",
            "enterPortFirst": "Veuillez saisir un numéro de port",
            "invalidPortRange": "Le port doit être un nombre entre 1 et 65535",
            "foundProcess": "Processus trouvé : %@ (PID %d)",
            "portFreeStatus": "Le port %@ est actuellement libre",
            "inspectFailed": "Échec de la vérification",
            "processEndedSuccess": "Le processus a été arrêté et le port %@ libéré",
            "processForceEndedSuccess": "Le processus a été forcé à s'arrêter et le port %@ libéré",
            "processEndedFailed": "Échec de l'arrêt",
            "processForceEndedFailed": "Échec de l'arrêt forcé",
            "forceKillConfirmTitle": "Forcer l'arrêt de ce processus ?",
            "forceKillConfirmButton": "Forcer l'arrêt",
            "cancel": "Annuler",
            "forceKillMessageDefault": "Ceci exécutera kill -9.",
            "forceKillMessageDetail": "Ceci exécutera kill -9 sur %@ (PID %d).",
            "noProcessInfo": "Aucune info processus",
            "unknownError": "Erreur inconnue",
            "invalidPortInfo": "Le système a renvoyé des informations de port impossibles à analyser",
            "commandFailed": "Échec de l'exécution de la commande",
            "historyStatusFree": "free",
            "historyStatusOccupied": "occupied",
            "historyStatusSuccess": "success",
            "historyStatusFailed": "failed",
            "historyActionInspect": "Vérifier",
            "historyActionTerminate": "Arrêter",
            "historyActionForceTerminate": "Forcer l'arrêt",
            "allListeningPorts": "Tous les ports en écoute",
            "scanAllPorts": "Scanner tous les ports",
            "scanning": "Scan en cours…",
            "noListeningPorts": "Aucun port en écoute détecté",
            "portCount": "%@ ports en écoute",
            "launchAtLogin": "Lancer au démarrage",
            "copyInfo": "Copier",
            "copiedToClipboard": "Copié dans le presse-papiers",
            "globalHotkeyHint": "Appuyez sur ⌘⇧P depuis n'importe où pour ouvrir PortFree",
            "adminRequired": "Privilèges administrateur requis",
            "settings": "Réglages"
        ],
        .spanish: [
            "language": "Idioma",
            "languageSettings": "Configuración de idioma",
            "followSystem": "Seguir el sistema",
            "quickMenuTitle": "Menú rápido de PortFree",
            "appDescription": "Comprueba un puerto y detén el proceso asociado si hace falta.",
            "commonPorts": "Puertos comunes",
            "recentHistory": "Actividad reciente",
            "noHistory": "Aún no hay historial",
            "noRecentRecords": "Sin registros",
            "portWithNumber": "Puerto %@",
            "portManagement": "Gestión de puertos",
            "releaseOccupiedPort": "Libera puertos ocupados rápidamente",
            "releaseOccupiedPortSubtitle": "Introduce un puerto para inspeccionar el proceso y finalizarlo normal o forzosamente.",
            "inspectPort": "Inspeccionar puerto",
            "inspectPortButton": "Inspeccionar",
            "portPlaceholder": "p. ej. 3000, 8080, 5173",
            "quickPorts": "Puertos rápidos",
            "occupied": "Ocupado",
            "available": "Disponible",
            "currentlyOccupied": "Actualmente ocupado",
            "currentlyFree": "Actualmente libre",
            "process": "Proceso",
            "pid": "PID",
            "user": "Usuario",
            "protocol": "Protocolo",
            "endpoint": "Detalles del puerto",
            "command": "Comando",
            "endProcess": "Finalizar proceso",
            "forceEnd": "Forzar cierre",
            "processEnded": "Finalizado",
            "noProcessDetected": "No se detectó ningún proceso usando este puerto",
            "notCheckedYet": "Aún no se ha inspeccionado ningún puerto",
            "notCheckedYetDescription": "Introduce un puerto o usa un puerto rápido para empezar.",
            "openMainWindow": "Abrir ventana principal",
            "quitApp": "Salir de PortFree",
            "enterPortFirst": "Introduce un número de puerto",
            "invalidPortRange": "El puerto debe ser un número entre 1 y 65535",
            "foundProcess": "Proceso encontrado: %@ (PID %d)",
            "portFreeStatus": "El puerto %@ está libre actualmente",
            "inspectFailed": "La inspección falló",
            "processEndedSuccess": "El proceso se cerró correctamente y se liberó el puerto %@",
            "processForceEndedSuccess": "El proceso se forzó a cerrarse y se liberó el puerto %@",
            "processEndedFailed": "No se pudo finalizar el proceso",
            "processForceEndedFailed": "No se pudo forzar el cierre del proceso",
            "forceKillConfirmTitle": "¿Forzar el cierre de este proceso?",
            "forceKillConfirmButton": "Forzar cierre",
            "cancel": "Cancelar",
            "forceKillMessageDefault": "Esto ejecutará kill -9.",
            "forceKillMessageDetail": "Esto ejecutará kill -9 sobre %@ (PID %d).",
            "noProcessInfo": "Sin información del proceso",
            "unknownError": "Error desconocido",
            "invalidPortInfo": "El sistema devolvió información de puerto que no se pudo analizar",
            "commandFailed": "La ejecución del comando falló",
            "historyStatusFree": "free",
            "historyStatusOccupied": "occupied",
            "historyStatusSuccess": "success",
            "historyStatusFailed": "failed",
            "historyActionInspect": "Inspección",
            "historyActionTerminate": "Finalizar",
            "historyActionForceTerminate": "Forzar cierre",
            "allListeningPorts": "Todos los puertos en escucha",
            "scanAllPorts": "Escanear todos los puertos",
            "scanning": "Escaneando…",
            "noListeningPorts": "No se detectaron puertos en escucha",
            "portCount": "%@ puertos en escucha",
            "launchAtLogin": "Iniciar al arrancar",
            "copyInfo": "Copiar",
            "copiedToClipboard": "Copiado al portapapeles",
            "globalHotkeyHint": "Pulsa ⌘⇧P en cualquier lugar para abrir PortFree",
            "adminRequired": "Se requieren privilegios de administrador",
            "settings": "Ajustes"
        ]
    ]
}
