import Foundation
import SwiftUI

enum ScanHistoryStorage {
    static let storageKey = "devtools_scan_history"
    static let emptyRawValue = "[]"
    static let maxItemCount = 200

    static func history(from rawValue: String) -> [String] {
        (try? JSONDecoder().decode([String].self, from: Data(rawValue.utf8))) ?? []
    }

    static func reversedHistory(from rawValue: String) -> [String] {
        Array(history(from: rawValue).reversed())
    }

    static func append(_ text: String, userDefaults: UserDefaults = .standard) {
        guard !text.isEmpty else { return }

        let rawValue = userDefaults.string(forKey: storageKey) ?? emptyRawValue
        var history = history(from: rawValue)
        history.append(text)

        if history.count > maxItemCount {
            history = Array(history.suffix(maxItemCount))
        }

        guard let data = try? JSONEncoder().encode(history) else {
            userDefaults.set(emptyRawValue, forKey: storageKey)
            return
        }

        userDefaults.set(String(data: data, encoding: .utf8) ?? emptyRawValue, forKey: storageKey)
    }
}

struct ScanHistorySection: View {
    let title: String
    let clearButtonTitle: String
    let copyButtonTitle: String
    let copySuccessMessage: String
    @Binding var visibleCopyIndex: Int?
    let onCopy: (String) -> Void
    @AppStorage(ScanHistoryStorage.storageKey) private var scanHistoryRaw: String =
        ScanHistoryStorage.emptyRawValue
    @State private var isCopyConfirmationVisible = false
    @State private var copyConfirmationTask: Task<Void, Never>?

    private var items: [String] {
        ScanHistoryStorage.reversedHistory(from: scanHistoryRaw)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .accessibilityIdentifier("home.history.title")
                Spacer()
                Button(role: .destructive) {
                    clearHistory()
                } label: {
                    Label(clearButtonTitle, systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("home.history.clear")
            }
            .padding(.top, 8)

            if isCopyConfirmationVisible {
                Text(copySuccessMessage)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items.indices, id: \.self) { index in
                    ScanHistoryRow(
                        text: items[index],
                        copyButtonTitle: copyButtonTitle,
                        isCopyVisible: visibleCopyIndex == index,
                        onTap: {
                            withAnimation {
                                if visibleCopyIndex == index {
                                    visibleCopyIndex = nil
                                } else {
                                    visibleCopyIndex = index
                                }
                            }
                        },
                        onCopy: {
                            copyItem(items[index])
                        }
                    )
                }
            }
        }
        .onDisappear {
            copyConfirmationTask?.cancel()
            isCopyConfirmationVisible = false
        }
    }

    private func clearHistory() {
        copyConfirmationTask?.cancel()
        isCopyConfirmationVisible = false
        scanHistoryRaw = ScanHistoryStorage.emptyRawValue
        visibleCopyIndex = nil
    }

    private func copyItem(_ item: String) {
        onCopy(item)
        visibleCopyIndex = nil
        copyConfirmationTask?.cancel()
        withAnimation {
            isCopyConfirmationVisible = true
        }
        copyConfirmationTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }

            withAnimation {
                isCopyConfirmationVisible = false
            }
        }
    }
}

private struct ScanHistoryRow: View {
    let text: String
    let copyButtonTitle: String
    let isCopyVisible: Bool
    let onTap: () -> Void
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(text)
                .lineLimit(2)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isCopyVisible {
                Button(copyButtonTitle, action: onCopy)
                    .buttonStyle(.bordered)
            }
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(6)
        .onTapGesture(perform: onTap)
    }
}
