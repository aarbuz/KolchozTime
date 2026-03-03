# 🏭 KołchozTime - Shift Work Manager

**KołchozTime** is a modern iOS application developed in **SwiftUI**, designed to streamline shift management and salary forecasting for shift workers. The application addresses the complexity of calculating earnings with variable rates (day/night, operator/helper roles) and shift durations (8h/12h).

<p align="center">
  <img src="preview.png" width="250" alt="Ekran Główny">
</p>


## 🚀 Key Features

* **Smart Contextual Calendar:** Rapid shift entry via direct interaction with the calendar grid. The app intelligently detects whether to edit an existing shift or add a new one based on the selected date.
* **Dynamic Role & Rate System:** Full support for distinct hourly rates based on job roles (**Operator / Helper**) and time of day (**Base Rate / Night Shift**).
* **Real-time Analytics:** Visual breakdown of shift types using interactive charts and instant salary calculation updated in real-time.
* **Flexible Reporting:** Generation of detailed text reports with customizable granularity (option to include or hide specific job roles) and seamless integration with the iOS Share Sheet.
* **Motivation Engine:** A humorous "Manager" quote system to improve user engagement.

## 🛠 Technology Stack

* **Language:** Swift 5
* **UI Framework:** SwiftUI
* **Architecture:** MVVM (Model-View-ViewModel)
* **Data Persistence:** UserDefaults
* **Version Control:** Git & GitHub

## 📂 Project Structure

The project follows a clean **MVVM** architecture for better maintainability and separation of concerns:

* `Models/`: Contains data structures (`WorkShift`, `JobRole`, `ShiftType`).
* `ViewModels/`: Handles business logic, salary calculations, and data transformation (`AppViewModel`).
* `Views/`: SwiftUI views divided into components (`CalendarView`, `AddShiftView`, `SettingsView`, `Components`).

## 📲 Installation

### Option 1: Install via `.ipa` (For users without a Mac or Developer Account)
You can install this app directly on your iPhone for free using a sideloading tool like **Sideloadly** or **AltStore**.

1. Download the latest `KolchozTime.ipa` file from the **Releases** tab (or request the file directly).
2. Install the app on your iPhone using your computer.
3. If you don't know how to sideload `.ipa` files wirelessly, watch this step-by-step tutorial: 
   📺 **[Sideload IPA with Sideloadly Wireless: Guide (YouTube)](https://www.youtube.com/watch?v=vqTsavQc3lQ)**
4. **Important:** After installation, go to your iPhone's **Settings > General > VPN & Device Management**, tap on your Apple ID, and select **Trust**. 
*(Note: If you are on iOS 16 or newer, you must also enable "Developer Mode" in Settings > Privacy & Security).*

### Option 2: Build from Source (For developers)
1. Clone this repository.
2. Open `KolchozTime.xcodeproj` in **Xcode 16+**.
3. Select your target simulator or physical device.
4. Press **Cmd + R** to build and run.

## 🔮 Future Roadmap

* [ ] Data export/import (Backup system).
* [ ] Monthly earnings target visualization.
* [ ] Intelligent task suggestion based on user history.
* [ ] Push notifications for shift logging reminders.

---

**Author:** aarbuz
