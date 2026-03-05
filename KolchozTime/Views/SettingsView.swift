import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingBackupAlert = false
    @State private var backupAlertMessage = ""
    @State private var showingEnableWarning = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kolor Motywu")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.themeColors, id: \.self) { color in
                                Circle().fill(color).frame(width: 40, height: 40)
                                    .overlay(Circle().stroke(Color.white, lineWidth: viewModel.accentColor == color ? 4 : 0))
                                    .onTapGesture { viewModel.accentColor = color }
                            }
                        }.padding(.vertical, 10).padding(.horizontal, 5)
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
                
                Section(header: Text("Zarządzanie Danymi"), footer: Text("Plik 'KolchozBackup.json' znajduje się w aplikacji 'Pliki' -> 'Na moim iPhonie' -> 'KolchozTime'.\n\n⚠️ WAŻNE: System iOS zawsze usuwa folder aplikacji przy jej odinstalowaniu. Aby zachować kopię przed usunięciem apki, ręcznie przenieś ten plik do innego folderu (np. 'Pobrane').")) {
                    
                    Button(action: {
                        let success = viewModel.restoreFromVisibleBackup()
                        backupAlertMessage = success ? "Pomyślnie przywrócono dane z pliku!" : "Nie znaleziono pliku KolchozBackup.json. Upewnij się, że jest w folderze aplikacji."
                        showingBackupAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Przywróć dane z pliku")
                        }
                    }
                    
                    Toggle("Automatyczna kopia zapasowa", isOn: Binding(
                        get: { viewModel.isBackupEnabled },
                        set: { newValue in
                            if newValue {
                                showingEnableWarning = true
                            } else {
                                viewModel.isBackupEnabled = false
                            }
                        }
                    ))
                    .tint(viewModel.accentColor)
                    
                    Button(action: {
                        let success = viewModel.deleteVisibleBackup()
                        backupAlertMessage = success ? "Plik z kopią zapasową został trwale usunięty." : "Nie znaleziono pliku do usunięcia."
                        showingBackupAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Usuń plik z kopią")
                        }
                    }.foregroundColor(.red)
                }
                
                Section {
                    Button(action: {
                        viewModel.saveShifts()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack { Spacer(); Text("Zapisz i Zamknij").bold(); Spacer() }
                    }
                    .foregroundColor(.green)
                    .listRowBackground(Color.green.opacity(0.1))
                }
            }
            .navigationTitle("Ustawienia")
            .preferredColorScheme(.dark)
            .alert(isPresented: $showingBackupAlert) {
                Alert(title: Text("Kopia Zapasowa"), message: Text(backupAlertMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showingEnableWarning) {
                Alert(
                    title: Text("Uwaga na nadpisanie!"),
                    message: Text("Jeśli masz już w folderze stary plik z kopią zapasową, włączenie tej opcji NADPISZE GO obecnymi danymi z aplikacji.\n\nZanim to zrobisz, upewnij się, że użyłeś opcji 'Przywróć dane'."),
                    primaryButton: .cancel(Text("Anuluj")),
                    secondaryButton: .destructive(Text("Włącz zapisywanie")) {
                        viewModel.isBackupEnabled = true
                    }
                )
            }
        }
    }
}
