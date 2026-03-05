import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct DonutChart: View {
    let stats: [ShiftType: Double]; let total: Double
    var body: some View {
        ZStack {
            if total == 0 { Circle().stroke(Color.gray.opacity(0.3), lineWidth: 6); Text("0%").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5)) }
            else {
                Circle().stroke(Color.gray.opacity(0.3), lineWidth: 6)
                ForEach(ShiftType.allCases) { type in if let value = stats[type], value > 0 { Circle().trim(from: startTrim(for: type), to: endTrim(for: type)).stroke(type.color, lineWidth: 6).rotationEffect(.degrees(-90)) } }
                Text("STAT").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
            }
        }
    }
    func startTrim(for type: ShiftType) -> CGFloat { var start: CGFloat = 0.0; for t in ShiftType.allCases { if t == type { break }; start += CGFloat((stats[t] ?? 0) / total) }; return start }
    func endTrim(for type: ShiftType) -> CGFloat { return startTrim(for: type) + CGFloat((stats[type] ?? 0) / total) }
}

struct ShiftRow: View {
    let shift: WorkShift
    var shiftColor: Color { if shift.type.contains("1.") || shift.type.contains("Dzień") { return .orange }; if shift.type.contains("2.") { return .purple }; return .blue }
    var body: some View {
        HStack {
            ZStack { Circle().fill(shiftColor.opacity(0.2)).frame(width: 40, height: 40); Image(systemName: shiftColor == .blue ? "moon.fill" : (shiftColor == .purple ? "sunset.fill" : "sun.max.fill")).foregroundColor(shiftColor) }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(shift.taskName).font(.headline).foregroundColor(.primary)
                    Text("(\(shift.role))").font(.caption2).foregroundColor(.gray).textCase(.uppercase)
                }
                HStack {
                    Text(shift.date, style: .date)
                    Text("•")
               
                    Text("\(String(format: "%g", shift.hoursCount))h").bold().foregroundColor(.orange)
                }.font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Text("+\(shift.earnings, specifier: "%.2f") zł").bold().foregroundColor(.green)
        }.listRowBackground(Color(UIColor.secondarySystemBackground))
    }
}

struct DetailBox: View {
    let icon: String; let title: String; let color: Color
    var body: some View { VStack { Image(systemName: icon).font(.title2).foregroundColor(color).padding(.bottom, 5); Text(title).font(.headline).foregroundColor(.primary) }.frame(maxWidth: .infinity).padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(15) }
}
