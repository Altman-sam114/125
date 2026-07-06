import SwiftUI

struct InfoPanelToggle<Summary: View, Content: View>: View {
    @State private var isExpanded = false
    @ViewBuilder let summary: Summary
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    isExpanded.toggle()
                } label: {
                    Text("详情")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("详情")

                Spacer(minLength: 8)
            }

            if isExpanded {
                content
            } else {
                summary
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
