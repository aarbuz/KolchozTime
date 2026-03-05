import SwiftUI

struct SelectedDate: Identifiable {
    let id = UUID()
    let date: Date
}

struct CalendarGridView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedShift: WorkShift?
    @State private var selectedDateForNewShift: SelectedDate?
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
    let daysOfWeek = ["Pn", "Wt", "Śr", "Cz", "Pt", "Sb", "Nd"]
    
    var body: some View {
        ScrollView {
            VStack {
                LazyVGrid(columns: columns) { ForEach(daysOfWeek, id: \.self) { day in Text(day).font(.caption).bold().foregroundColor(.gray) } }
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            let shift = viewModel.getShift(for: date)
                            let isToday = Calendar.current.isDateInToday(date)
                            VStack {
                                Text("\(Calendar.current.component(.day, from: date))").font(.system(size: 14, weight: isToday ? .black : .bold, design: .rounded)).foregroundColor(isToday ? .blue : (shift != nil ? .white : .gray))
                                if let shift = shift { Circle().fill(shift.type.contains("3.") || shift.type.contains("Noc") ? .blue : (shift.type.contains("2.") ? .purple : .orange)).frame(width: 8, height: 8) }
                                else { Circle().fill(Color.clear).frame(width: 8, height: 8) }
                            }
                            .frame(maxWidth: .infinity, minHeight: 50).background(RoundedRectangle(cornerRadius: 8).fill(shift != nil ? Color.white.opacity(0.1) : Color.clear)).overlay(isToday ? RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.5), lineWidth: 1) : nil)
                            .onTapGesture {
                                if let s = shift { selectedShift = s }
                                else { selectedDateForNewShift = SelectedDate(date: date) }
                            }
                        } else { Text("") }
                    }
                }
                Color.clear.frame(height: 150)
            }.padding()
        }
        .sheet(item: $selectedShift) { shift in ShiftDetailView(shift: shift, viewModel: viewModel) }
        .sheet(item: $selectedDateForNewShift) { sd in AddShiftView(viewModel: viewModel, initialDate: sd.date) }
    }
    func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: viewModel.currentMonthDate)!
        let firstDay = interval.start; let firstWeekday = calendar.component(.weekday, from: firstDay); let offset = (firstWeekday + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: offset)
        let range = calendar.range(of: .day, in: .month, for: viewModel.currentMonthDate)!
        for day in range { if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) { days.append(date) } }
        return days
    }
}
