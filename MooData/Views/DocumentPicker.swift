import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: NSViewRepresentable {
    let types: [UTType]
    let mode: Mode
    let onSelect: (URL) -> Void
    
    enum Mode {
        case open
        case save
    }
    
    init(types: [UTType], mode: Mode = .open, onSelect: @escaping (URL) -> Void) {
        self.types = types
        self.mode = mode
        self.onSelect = onSelect
    }
    
    func makeNSView(context: Context) -> NSView {
        switch mode {
        case .open:
            let openPanel = NSOpenPanel()
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseDirectories = false
            openPanel.canCreateDirectories = false
            openPanel.allowedContentTypes = types
            openPanel.begin { result in
                if result == .OK, let url = openPanel.url {
                    onSelect(url)
                }
            }
        case .save:
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = types
            savePanel.canCreateDirectories = true
            savePanel.begin { result in
                if result == .OK, let url = savePanel.url {
                    onSelect(url)
                }
            }
        }
        
        return NSView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
} 
