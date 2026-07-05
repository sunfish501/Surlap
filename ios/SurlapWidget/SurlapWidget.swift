import WidgetKit
import SwiftUI

// MARK: - 색·그라데이션 (목업 `Surlap 위젯.dc.html` 1:1)
extension Color {
    init(hexString: String) {
        let h = hexString.replacingOccurrences(of: "#", with: "")
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        if h.count == 6 {
            self = Color(
                .sRGB,
                red: Double((v >> 16) & 0xff) / 255,
                green: Double((v >> 8) & 0xff) / 255,
                blue: Double(v & 0xff) / 255,
                opacity: 1
            )
        } else {
            self = Color(red: 0.55, green: 0.5, blue: 0.96)
        }
    }

    // Backward-compat (구 Color(hex:) 호출 살아있을 가능성).
    init(hex: String) { self.init(hexString: hex) }

    static let surlapAccent  = Color(hexString: "#A98BFF")
    static let surlapMuted   = Color(hexString: "#8E8C97")
    static let surlapCaption = Color(hexString: "#A4A2AD")
}

var surlapSurface: LinearGradient {
    LinearGradient(
        colors: [Color(hexString: "#1E1638"), Color(hexString: "#150F29")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - 모델
struct WPeriod: Identifiable {
    let id = UUID()
    let name: String
    let start: String
    let end: String
    let color: Color
}

struct SurlapEntry: TimelineEntry {
    let date: Date
    let today: String
    let schoolClass: String
    let periods: [WPeriod]
    let currentIndex: Int
    let minutesRemaining: Int
    let nowName: String
    let nowStart: String
    let nowEnd: String
    let nextName: String
    let nextStart: String

    static let placeholder = SurlapEntry(
        date: Date(),
        today: "6월 26일 (월)",
        schoolClass: "3학년 2반",
        periods: [
            WPeriod(name: "국어", start: "09:00", end: "09:50", color: Color(hexString: "#3A3A78")),
            WPeriod(name: "수학", start: "10:00", end: "10:50", color: Color.surlapAccent),
            WPeriod(name: "영어", start: "11:00", end: "11:50", color: Color(hexString: "#1F5A5A")),
            WPeriod(name: "과학", start: "12:00", end: "12:50", color: Color(hexString: "#243A6E"))
        ],
        currentIndex: 1,
        minutesRemaining: 28,
        nowName: "수학",
        nowStart: "10:00",
        nowEnd: "10:50",
        nextName: "영어",
        nextStart: "11:00"
    )
}

// MARK: - App Group UserDefaults 에서 데이터 읽기
enum SurlapStore {
    static let appGroup = "group.com.kev208dev.Surlap"

    static func load() -> SurlapEntry {
        let d = UserDefaults(suiteName: appGroup)
        func s(_ k: String) -> String { d?.string(forKey: k) ?? "" }
        func i(_ k: String) -> Int { d?.integer(forKey: k) ?? 0 }

        var periods: [WPeriod] = []
        if let raw = d?.string(forKey: "periods"),
           let data = raw.data(using: .utf8),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            periods = arr.map {
                WPeriod(
                    name: $0["name"] as? String ?? "",
                    start: $0["start"] as? String ?? "",
                    end: $0["end"] as? String ?? "",
                    color: Color(hexString: $0["color"] as? String ?? "#3A3A78")
                )
            }
        }
        // currentIndex 가 저장돼 있지 않으면 -1 로 (위젯이 진행 중 표시 안 함).
        let current: Int = {
            guard let v = d?.object(forKey: "currentIndex") as? Int else { return -1 }
            return v
        }()

        return SurlapEntry(
            date: Date(),
            today: s("today"),
            schoolClass: s("schoolClass"),
            periods: periods,
            currentIndex: current,
            minutesRemaining: i("minutesRemaining"),
            nowName: s("nowName"),
            nowStart: s("nowStart"),
            nowEnd: s("nowEnd"),
            nextName: s("nextName"),
            nextStart: s("nextStart")
        )
    }
}

// MARK: - 교시 세그먼트 바 (활성 라벤더 + 흰 플레이헤드)
struct PeriodBar: View {
    let periods: [WPeriod]
    let current: Int
    var height: CGFloat = 18

    var body: some View {
        HStack(spacing: 4) {
            if periods.isEmpty {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                }
            } else {
                ForEach(Array(periods.enumerated()), id: \.offset) { i, p in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(i == current
                              ? Color.surlapAccent
                              : p.color.opacity(i < current ? 0.45 : 1))
                        .layoutPriority(i == current ? 1.7 : 1)
                        .overlay(
                            i == current
                            ? RoundedRectangle(cornerRadius: 1.5).fill(.white).frame(width: 3)
                            : nil
                        )
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - "지금/다음" 카드 (Medium)
struct NowNextCard: View {
    let d: SurlapEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("지금").foregroundColor(.surlapMuted)
                Spacer()
                Text("다음").foregroundColor(.surlapMuted)
            }
            .font(.system(size: 13.5, weight: .semibold))

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(d.nowName.isEmpty ? "수업 없음" : d.nowName)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(d.nowStart.isEmpty ? "—" : d.nowStart)
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundColor(.surlapAccent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(d.nextName.isEmpty ? "—" : d.nextName)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(d.nextStart.isEmpty ? "—" : d.nextStart)
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundColor(.surlapAccent)
                }
            }
            .padding(.top, 4)

            PeriodBar(periods: d.periods, current: d.currentIndex)
                .padding(.top, 14)

            Text("종료까지 \(d.minutesRemaining)분 남음")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.surlapCaption)
                .frame(maxWidth: .infinity)
                .padding(.top, 11)
        }
    }
}

// MARK: - Small
struct SmallView: View {
    let d: SurlapEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "graduationcap.fill").foregroundColor(.surlapAccent).font(.system(size: 12))
                Text(d.currentIndex >= 0
                     ? "지금 · \(d.currentIndex + 1)교시"
                     : "오늘 시간표")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.surlapMuted)
            }
            Text(d.nowName.isEmpty ? "수업 없음" : d.nowName)
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.white)
                .padding(.top, 10)
                .lineLimit(1)
            Text(d.nowStart.isEmpty ? "—" : "\(d.nowStart) – \(d.nowEnd)")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.surlapAccent)
            Spacer()
            PeriodBar(periods: d.periods, current: d.currentIndex, height: 8)
            if d.currentIndex >= 0 {
                Text("\(d.minutesRemaining)분 남음")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.surlapCaption)
                    .padding(.top, 5)
            }
        }
    }
}

// MARK: - Large
struct LargeView: View {
    let d: SurlapEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "graduationcap.fill").foregroundColor(.surlapAccent)
                Text("오늘 시간표")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.white)
                Spacer()
                if !d.schoolClass.isEmpty {
                    Text(d.schoolClass)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.surlapMuted)
                }
            }
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
            if d.periods.isEmpty {
                Spacer()
                Text("오늘 등록된 수업이 없어요")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.surlapMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(Array(d.periods.enumerated()), id: \.offset) { i, p in
                    HStack(spacing: 12) {
                        Text(i == d.currentIndex ? "지금" : "\(i + 1)교시")
                            .font(.system(size: i == d.currentIndex ? 11 : 12,
                                          weight: i == d.currentIndex ? .heavy : .bold))
                            .foregroundColor(i == d.currentIndex ? .surlapAccent : .surlapMuted)
                            .frame(width: 36, alignment: .leading)
                        Circle()
                            .fill(i == d.currentIndex ? Color.surlapAccent : p.color)
                            .frame(width: i == d.currentIndex ? 9 : 8,
                                   height: i == d.currentIndex ? 9 : 8)
                        Text(p.name)
                            .font(.system(size: i == d.currentIndex ? 16 : 15,
                                          weight: i == d.currentIndex ? .heavy : .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                        Text(p.start)
                            .font(.system(size: 12.5,
                                          weight: i == d.currentIndex ? .heavy : .semibold))
                            .foregroundColor(i == d.currentIndex ? .surlapAccent : .surlapMuted)
                    }
                    .padding(.vertical, i == d.currentIndex ? 8 : 4)
                    .padding(.horizontal, i == d.currentIndex ? 12 : 4)
                    .background(i == d.currentIndex
                                ? Color.surlapAccent.opacity(0.14)
                                : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
}

// MARK: - Provider (분 단위 timeline)
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SurlapEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (SurlapEntry) -> Void) {
        completion(context.isPreview ? .placeholder : SurlapStore.load())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SurlapEntry>) -> Void) {
        let entry = SurlapStore.load()
        let next = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date().addingTimeInterval(60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Entry view
struct SurlapWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: SurlapEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall: SmallView(d: entry)
            case .systemLarge: LargeView(d: entry)
            default: NowNextCard(d: entry)
            }
        }
        .padding(family == .systemSmall ? 15 : 18)
        .containerBackground(for: .widget) { surlapSurface }
        .widgetURL(URL(string: "surlap://widget"))
    }
}

// MARK: - Widget
// pbxproj 에 박혀있는 kind/struct 명을 바꾸면 위젯이 사라지므로 그대로 유지.
struct SurlapWidget: Widget {
    let kind = "SurlapWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SurlapWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Surlap")
        .description("오늘 시간표와 지금 수업을 한눈에.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct SurlapWidgetBundle: WidgetBundle {
    var body: some Widget {
        SurlapWidget()
    }
}
