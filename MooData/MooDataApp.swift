//
//  MooDataApp.swift
//  MooData
//
//  Created by 徐化军 on 2025/3/24.
//

import SwiftUI

extension Notification.Name {
    static let showSettings = Notification.Name("showSettings")
}

@main
struct MooDataApp: App {
    var body: some Scene {
        WindowGroup {
            AuthenticationView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 300, height: 600)
        .commands {
            CommandGroup(after: .appSettings) {
                Button("设置") {
                    NotificationCenter.default.post(name: .showSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            
            CommandGroup(replacing: .newItem) {
                Button("新建项目") {
                    NotificationCenter.default.post(name: .showNewProjectSheet, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(replacing: .saveItem) {
                Button("保存") {
                    NotificationCenter.default.post(name: .saveFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("另存为") {
                    NotificationCenter.default.post(name: .saveAsFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            
            CommandGroup(replacing: .importExport) {
                Button("打开") {
                    NotificationCenter.default.post(name: .openFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("关闭") {
                    NotificationCenter.default.post(name: .closeFile, object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)
            }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
