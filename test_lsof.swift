import Foundation
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
task.arguments = ["-nP", "-iTCP:5173", "-sTCP:LISTEN"]
let outObj = Pipe()
task.standardOutput = outObj
try! task.run()
task.waitUntilExit()
let d = outObj.fileHandleForReading.readDataToEndOfFile()
print(String(data: d, encoding: .utf8) ?? "null")
