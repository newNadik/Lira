import SwiftUI


struct JournalPopup: View {
    let events: [String]
    let dayIndex: Int
    var onClose: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image("log_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Journal")
                            .font(.headline)
                            .foregroundColor(Color("brown"))
                    }
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color("brown"))
                            .padding(6)
                    }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityLabel("Close journal")
                }
                Text("Day \(dayIndex)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color("brown"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 2)

                if events.isEmpty {
                    Text("No events yet. The Liri are settling in…")
                        .font(.callout)
                        .foregroundColor(Color("brown").opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(events.enumerated().reversed().prefix(200)), id: \.offset) { item in
                                Text(item.element)
                                    .font(.callout)
                                    .foregroundColor(Color("brown"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 6)
                                    .overlay(
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundColor(Color("brown").opacity(0.2)),
                                        alignment: .bottom
                                    )
                            }
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: 480)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color("beige"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color("brown"), lineWidth: 2.5)
            )
            .shadow(color: Color("brown").opacity(0.18), radius: 12, x: 0, y: 6)
        }
    }
}
