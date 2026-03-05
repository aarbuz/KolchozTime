import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController { return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities) }
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
    @ObservedObject var viewModel: AppViewModel
    var shiftColor: Color { if shift.type.contains("1.") || shift.type.contains("Dzień") { return .orange }; if shift.type.contains("2.") { return .purple }; return .blue }
    
    var body: some View {
        HStack {
            ZStack { Circle().fill(shiftColor.opacity(0.2)).frame(width: 45, height: 45); Image(systemName: shiftColor == .blue ? "moon.fill" : (shiftColor == .purple ? "sunset.fill" : "sun.max.fill")).foregroundColor(shiftColor).font(.title3) }
            VStack(alignment: .leading, spacing: 5) {
                Text(shift.taskName).font(.headline).foregroundColor(.white).lineLimit(1)
                HStack(spacing: 5) {
                    Text(shift.date, style: .date)
                    Text("•")
                    Text("\(String(format: "%g", shift.hoursCount))h").bold().foregroundColor(viewModel.accentColor)
                    Text("•")
                    Text(shift.role)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(4)
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .fixedSize()
                }.font(.caption).foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text("+\(shift.earnings, specifier: "%.2f") zł").bold().foregroundColor(.green)
                Button(action: { viewModel.deleteShift(id: shift.id) }) { Image(systemName: "trash.fill").foregroundColor(.red.opacity(0.8)).font(.caption) }.padding(6).background(Color.red.opacity(0.15)).clipShape(Circle())
            }
        }
        .padding(15)
        .background(Color.white.opacity(0.08))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
    }
}

struct DetailBox: View {
    let icon: String; let title: String; let color: Color
    var body: some View { VStack { Image(systemName: icon).font(.title2).foregroundColor(color).padding(.bottom, 5); Text(title).font(.headline).foregroundColor(.white) }.frame(maxWidth: .infinity).padding().background(Color.white.opacity(0.1)).cornerRadius(15) }
}
