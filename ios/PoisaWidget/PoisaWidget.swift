import SwiftUI
import WidgetKit

// iOS counterpart of android/.../PoisaWidgetProvider.kt. Reads the snapshot
// HomeWidgetService writes into the shared App Group; every string arrives
// already formatted in the user's language, currency and numerals.

private let appGroupId = "group.com.kori.moneytracker"

struct PoisaEntry: TimelineEntry {
  let date: Date
  let todayLabel: String
  let todayAmount: String
  let monthLine: String
  let expenseLabel: String
  let incomeLabel: String
}

struct PoisaProvider: TimelineProvider {
  func placeholder(in context: Context) -> PoisaEntry {
    PoisaEntry(
      date: Date(), todayLabel: "Spent today", todayAmount: "৳0",
      monthLine: "This month  ৳0", expenseLabel: "Expense", incomeLabel: "Income")
  }

  func getSnapshot(in context: Context, completion: @escaping (PoisaEntry) -> Void) {
    completion(entry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PoisaEntry>) -> Void) {
    // Refresh just after midnight so "today" resets even if the app stays closed.
    let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
    completion(Timeline(entries: [entry()], policy: .after(midnight)))
  }

  private func entry() -> PoisaEntry {
    let data = UserDefaults(suiteName: appGroupId)
    func s(_ key: String, _ fallback: String) -> String { data?.string(forKey: key) ?? fallback }

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    let zero = s("zero_amount", "0")
    let sameDay = s("snapshot_day", "") == formatter.string(from: Date())
    let monthEndMs = Double(s("month_end_ms", "0")) ?? 0
    let sameMonth = Date().timeIntervalSince1970 * 1000 < monthEndMs

    return PoisaEntry(
      date: Date(),
      todayLabel: s("today_label", "Spent today"),
      todayAmount: sameDay ? s("today_amount", zero) : zero,
      monthLine: s("month_label", "This month") + "  " + (sameMonth ? s("month_amount", zero) : zero),
      expenseLabel: s("expense_label", "Expense"),
      incomeLabel: s("income_label", "Income"))
  }
}

struct PoisaWidgetView: View {
  let entry: PoisaEntry
  private let brand = Color(red: 1 / 255, green: 79 / 255, blue: 62 / 255)

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(entry.todayLabel).font(.footnote).foregroundColor(.white.opacity(0.8))
      Text(entry.todayAmount).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
        .lineLimit(1).minimumScaleFactor(0.6)
      Text(entry.monthLine).font(.caption).foregroundColor(.white.opacity(0.8)).lineLimit(1)
      Spacer(minLength: 6)
      HStack(spacing: 8) {
        Link(destination: URL(string: "poisa://add/expense?homeWidget")!) {
          label("+ " + entry.expenseLabel, filled: true)
        }
        Link(destination: URL(string: "poisa://add/income?homeWidget")!) {
          label("+ " + entry.incomeLabel, filled: false)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .widgetURL(URL(string: "poisa://open?homeWidget"))
    .poisaBackground(brand)
  }

  private func label(_ text: String, filled: Bool) -> some View {
    Text(text)
      .font(.subheadline.bold())
      .lineLimit(1)
      .frame(maxWidth: .infinity, minHeight: 34)
      .foregroundColor(filled ? brand : .white)
      .background(filled ? Color.white : Color.white.opacity(0.2))
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

extension View {
  @ViewBuilder
  fileprivate func poisaBackground(_ color: Color) -> some View {
    if #available(iOS 17.0, *) {
      self.containerBackground(color, for: .widget)
    } else {
      self.padding().background(color)
    }
  }
}

@main
struct PoisaWidget: Widget {
  // Must match HomeWidgetService._iosKind.
  let kind = "PoisaWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PoisaProvider()) { entry in
      PoisaWidgetView(entry: entry)
    }
    .configurationDisplayName("Poisa")
    .description("Today's spending at a glance, with one-tap add.")
    .supportedFamilies([.systemMedium])
  }
}
