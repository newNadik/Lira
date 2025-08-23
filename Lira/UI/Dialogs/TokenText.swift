import SwiftUI

struct TokenText: View {
    enum Part: Equatable { case text(String), icon(String) }
    let parts: [Part]

    init(_ raw: String) { parts = Self.parse(raw) }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                switch part {
                case .text(let s):
                    Text(s)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundColor(Color("brown"))
                case .icon(let name):
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 16)
                        .accessibilityLabel(Text(name.replacingOccurrences(of: "_", with: " ")))
                }
            }
            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private static func parse(_ s: String) -> [Part] {
        var result: [Part] = [], buf = ""; var i = s.startIndex
        func flush() { if !buf.isEmpty { result.append(.text(buf)); buf.removeAll() } }
        while i < s.endIndex {
            if s[i] == "[", let j = s[i...].firstIndex(of: "]") {
                let token = String(s[s.index(after: i)..<j])
                flush(); result.append(.icon(token)); i = s.index(after: j)
            } else { buf.append(s[i]); i = s.index(after: i) }
        }
        flush(); return result
    }
}
