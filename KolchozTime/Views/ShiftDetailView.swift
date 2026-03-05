import SwiftUI

struct ShiftDetailView: View {
    let shift: WorkShift
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            VStack(spacing: 25) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top)
                Text(shift.taskName.uppercased()).font(.system(size: 28, weight: .black)).foregroundColor(.primary)
                Text(shift.role.uppercased()).font(.caption).bold().padding(6).background(Color.gray.opacity(0.3)).cornerRadius(5).foregroundColor(.primary)
                HStack(spacing: 15) {
            
                    DetailBox(icon: "clock.fill", title: "\(String(format: "%g", shift.hoursCount))h", color: .blue)
                    DetailBox(icon: "banknote.fill", title: String(format: "%.2f zł", shift.earnings), color: .green)
                    DetailBox(icon: "calendar", title: formatDate(shift.date), color: .orange)
                }
                Divider().background(Color.gray)
                HStack { Text("Dokładne godziny:").foregroundColor(.gray); Spacer(); Text("\(shift.startTime, style: .time) - \(shift.endTime, style: .time)").bold().foregroundColor(.primary) }.padding(.horizontal)
                Spacer()
                Button(action: { viewModel.deleteShift(id: shift.id); presentationMode.wrappedValue.dismiss() }) { Text("Usuń tę zmianę").bold().frame(maxWidth: .infinity).padding().background(Color.red.opacity(0.2)).foregroundColor(.red).cornerRadius(15) }.padding(.horizontal).padding(.bottom)
            }.padding()
        }
    }
    func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "dd.MM"; return f.string(from: date) }
}
