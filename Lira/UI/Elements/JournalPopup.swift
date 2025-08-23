import SwiftUI


struct JournalPopup: View {
    let events: [String]
    let dayIndex: Int
    var onClose: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 10) {
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
                .padding(.horizontal, 14)
                .padding(.top, 14)

                if events.isEmpty {
                    Text("No events yet. The Liri are settling in…")
                        .font(.callout)
                        .foregroundColor(Color("brown").opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
                else {
                    
//                    Rectangle()
//                        .frame(height: 1)
//                        .foregroundColor(Color("brown").opacity(0.1))
                    
                    let grouped = groupEventsByDay(Array(events.suffix(500))) // cap to recent 500 entries for perf
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            ForEach(grouped, id: \.day) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    // Section header: Day N (skip if unknown day)
                                    if group.day >= 0 {
                                        Text("Day \(group.day)")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundColor(Color("brown"))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }

                                    // Items (deduped, day prefix stripped)
                                    ForEach(Array(group.items.enumerated()), id: \.offset) { idx, line in
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text(line)
                                                .font(.callout)
                                                .foregroundColor(Color("brown"))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.vertical, 6)
                                            if idx < group.items.count - 1 {
                                                Rectangle()
                                                    .frame(height: 1)
                                                    .foregroundColor(Color("brown").opacity(0.1))
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 14)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(Color("brown").opacity(0.15)),
                                    alignment: .bottom
                                )
                            }
                        }
                        .padding(.top, 2)
                    }
                }
            }
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

private struct DayGroup {
    let day: Int
    let items: [String]
}

/// Groups events by their leading "Day N:" prefix, strips the prefix from each line, and removes consecutive duplicates per day while preserving order.
private func groupEventsByDay(_ events: [String]) -> [DayGroup] {
    // We expect input in chronological order. We'll read from the end so newest day appears first.
    var buckets: [Int: [String]] = [:]
    var order: [Int] = []

    func splitDayPrefix(_ s: String) -> (Int?, String) {
        // Accept formats like "Day 1: ...", "day 1 - ...", "DAY 1 – ..."
        let sTrim = s.trimmingCharacters(in: .whitespaces)
        guard sTrim.count >= 6 else { return (nil, s) }
        let lower = sTrim.lowercased()
        guard lower.hasPrefix("day ") else { return (nil, s) }
        // Find the delimiter after the number
        let afterDay = sTrim.index(sTrim.startIndex, offsetBy: 4)
        // Scan digits
        var i = afterDay
        var digits = ""
        while i < sTrim.endIndex, sTrim[i].isNumber {
            digits.append(sTrim[i])
            i = sTrim.index(after: i)
        }
        guard let d = Int(digits) else { return (nil, s) }
        // Skip optional spaces and one delimiter (:, -, –)
        while i < sTrim.endIndex, sTrim[i].isWhitespace { i = sTrim.index(after: i) }
        if i < sTrim.endIndex, [":", "-", "–"].contains(String(sTrim[i])) {
            i = sTrim.index(after: i)
        }
        let rest = sTrim[i...].trimmingCharacters(in: .whitespaces)
        return (d, String(rest))
    }

    for line in events.reversed() { // iterate from newest to oldest
        let (maybeDay, text) = splitDayPrefix(line)
        let day = maybeDay ?? -1
        if buckets[day] == nil { buckets[day] = []; order.append(day) }
        // De-dupe consecutive identical lines within the same day
        if buckets[day]?.last != text { buckets[day]?.append(text) }
    }

    // Build groups in newest-first order
    return order.map { DayGroup(day: $0, items: buckets[$0] ?? []) }
}
