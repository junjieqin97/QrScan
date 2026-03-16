import SwiftUI

struct ScanHistorySection: View {
    let title: String
    let clearButtonTitle: String
    let copyButtonTitle: String
    let items: [String]
    @Binding var visibleCopyIndex: Int?
    let onClear: () -> Void
    let onCopy: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(role: .destructive, action: onClear) {
                    Label(clearButtonTitle, systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)

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
                            onCopy(items[index])
                        }
                    )
                }
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
