import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .indigo]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kolor Motywu")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(colors, id: \.self) { color in
                                Circle().fill(color).frame(width: 35, height: 35)
                                    .overlay(Circle().stroke(Color.white, lineWidth: viewModel.accentColor == color ? 3 : 0))
                                    .onTapGesture { viewModel.accentColor = color }
                            }
                        }.padding(.vertical, 10)
                    }
                }
                Section(header: Text("Stawki - POMOCNIK")) {
                    HStack { Text("Podstawowa").bold(); Spacer(); TextField("0.00", text: $viewModel.helperBaseString).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Nocna").bold(); Spacer(); TextField("0.00", text: $viewModel.helperNightString).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                }
                Section(header: Text("Stawki - OPERATOR")) {
                    HStack { Text("Podstawowa").bold(); Spacer(); TextField("0.00", text: $viewModel.operatorBaseString).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Nocna").bold(); Spacer(); TextField("0.00", text: $viewModel.operatorNightString).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                }
                Button(action: { viewModel.saveShifts(); presentationMode.wrappedValue.dismiss() }) {
                    HStack { Spacer(); Text("Zapisz i Zamknij").bold(); Spacer() }
                }.foregroundColor(.green)
            }
            .navigationTitle("Ustawienia")
            .preferredColorScheme(.dark)
        }
    }
}
