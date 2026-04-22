//
//  Item.swift
//  PortFree
//
//  Created by JIANGJINGZHE on 22/4/2026.
//

import Foundation

struct Item: Identifiable {
    let id = UUID()
    let timestamp: Date
    let port: Int
    let processName: String
    let pid: Int?
    let actionType: String
    let resultStatus: String

    init(
        timestamp: Date = Date(),
        port: Int,
        processName: String,
        pid: Int? = nil,
        actionType: String,
        resultStatus: String
    ) {
        self.timestamp = timestamp
        self.port = port
        self.processName = processName
        self.pid = pid
        self.actionType = actionType
        self.resultStatus = resultStatus
    }

    static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
