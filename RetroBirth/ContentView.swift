import SwiftUI
import UniformTypeIdentifiers

// Structure to track dragged files
struct StagedFile: Identifiable {
    let id = UUID()
    let url: URL
    var name: String { url.lastPathComponent }
    var path: String { url.deletingLastPathComponent().path }
}

struct ContentView: View {
    // File Staging States
    @State private var stagedFiles: [StagedFile] = []
    @State private var isTargeted = false
    @State private var statusMessage = "Ready to tweak timestamps"
    @State private var isSuccess = false
    
    // Date Selection States
    @State private var changeCreationDate = false
    @State private var creationDate = Date()
    
    @State private var changeModificationDate = false
    @State private var modificationDate = Date()
    
    var body: some View {
        HStack(spacing: 0) {
            
            // LEFT COLUMN: Drop Zone & Staged Files Sidebar
            VStack(alignment: .leading, spacing: 12) {
                Text("Staged Files")
                    .font(.system(.subheadline, design: .rounded))
                    .bold()
                    .foregroundColor(.secondary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isTargeted ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 1.5)
                        .background(isTargeted ? Color.accentColor.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                    
                    if stagedFiles.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary)
                            Text("Drag & Drop Files Here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(spacing: 0) {
                            List(stagedFiles) { file in
                                HStack {
                                    Image(systemName: "doc.plaintext")
                                        .foregroundColor(.secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.name)
                                            .font(.system(.body, design: .monospaced))
                                            .lineLimit(1)
                                        Text(file.path)
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .listStyle(.inset)
                            
                            Divider()
                            
                            Button(action: {
                                stagedFiles.removeAll()
                                statusMessage = "Ready to tweak timestamps"
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear All Files")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.red)
                            .background(Color.red.opacity(0.08))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(16)
            .frame(width: 260)
            
            Divider()
            
            // RIGHT COLUMN: Configuration Panel & Action Buttons
            VStack(alignment: .leading, spacing: 20) {
                Text("Timestamp Settings")
                    .font(.system(.title3, design: .rounded))
                    .bold()
                
                // Config Section
                VStack(spacing: 14) {
                    timestampRow(title: "Creation Date (Birth)", isOn: $changeCreationDate, date: $creationDate)
                    
                    timestampRow(title: "Modification Date", isOn: $changeModificationDate, date: $modificationDate)
                }
                .padding(14)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(10)
                
                Spacer()
                
                // Status Box
                HStack(spacing: 8) {
                    if statusMessage.contains("✅") {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    } else if statusMessage.contains("⚠️") {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    } else {
                        Image(systemName: "info.circle").foregroundColor(.secondary)
                    }
                    
                    Text(statusMessage.replacingOccurrences(of: "✅ ", with: "").replacingOccurrences(of: "⚠️ ", with: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                
                // Apply Button
                Button(action: applyChanges) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Apply New Timestamps")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(stagedFiles.isEmpty || (!changeCreationDate && !changeModificationDate))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .frame(width: 680, height: 420)
        // Main drop registration target
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            let group = DispatchGroup()
            var loadedURLs: [URL] = []
            
            for provider in providers {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let fileURL = url { loadedURLs.append(fileURL) }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                for url in loadedURLs {
                    if !stagedFiles.contains(where: { $0.url == url }) {
                        stagedFiles.append(StagedFile(url: url))
                    }
                }
                readMetadataFromStagedFiles()
            }
            return true
        }
    }
    
    // Extracted Helper View component for rows to keep main body exceptionally clean
    @ViewBuilder
    func timestampRow(title: String, isOn: Binding<Bool>, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Toggle(isOn: isOn) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.body)
                    }
                }
                .toggleStyle(.checkbox)
                
                Spacer()
                
                DatePicker("", selection: date)
                    .disabled(!isOn.wrappedValue)
            }
        }
    }
    
    func readMetadataFromStagedFiles() {
        guard let firstFile = stagedFiles.first else { return }
        
        if stagedFiles.count == 1 {
            do {
                let values = try firstFile.url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
                if let cDate = values.creationDate { creationDate = cDate }
                if let mDate = values.contentModificationDate { modificationDate = mDate }
                statusMessage = "Loaded attributes for \(firstFile.name)"
            } catch {
                statusMessage = "Dropped file, but system properties are locked."
            }
        } else {
            statusMessage = "Batch Mode: Modifying timestamps for \(stagedFiles.count) items."
        }
    }
    
    func applyChanges() {
        var successCount = 0
        var failCount = 0
        
        for file in stagedFiles {
            do {
                var resourceValues = URLResourceValues()
                if changeCreationDate { resourceValues.creationDate = creationDate }
                if changeModificationDate { resourceValues.contentModificationDate = modificationDate }
                
                var mutableURL = file.url
                try mutableURL.setResourceValues(resourceValues)
                successCount += 1
            } catch {
                failCount += 1
            }
        }
        
        if failCount == 0 {
            statusMessage = "✅ Successfully updated \(successCount) file(s)!"
            stagedFiles.removeAll()
        } else {
            statusMessage = "⚠️ Updated \(successCount) file(s). \(failCount) failed."
        }
    }
}
