import SwiftUI

struct RemindersView: View {

    @AppStorage("reminders.weeklySummaryEnabled") private var weeklySummaryEnabled = true
    @AppStorage("reminders.dailySpendingEnabled") private var dailySpendingEnabled = false

    @State private var permissionGranted: Bool?

    var body: some View {
        Form {
            if let permissionGranted, !permissionGranted {
                Section {
                    Text("Notifications are currently off. Turn them on in iOS Settings to use reminders.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Reminders") {
                Toggle("Weekly summary (Sunday 6pm)", isOn: $weeklySummaryEnabled)
                    .onChange(of: weeklySummaryEnabled) { _, _ in
                        Task { await apply() }
                    }

                Toggle("Daily spending check‑in (8pm)", isOn: $dailySpendingEnabled)
                    .onChange(of: dailySpendingEnabled) { _, _ in
                        Task { await apply() }
                    }
            }

            Section {
                Text("These reminders are optional and can be changed any time.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await apply()
        }
    }

    private func apply() async {
        let granted = await NotificationService.shared.requestPermission()
        permissionGranted = granted

        guard granted else {
            NotificationService.shared.cancel(ids: ["weekly-summary", "daily-spending-reminder"])
            return
        }

        if weeklySummaryEnabled {
            NotificationService.shared.scheduleWeeklySummary()
        } else {
            NotificationService.shared.cancel(ids: ["weekly-summary"])
        }

        if dailySpendingEnabled {
            NotificationService.shared.scheduleDailySpendingReminder()
        } else {
            NotificationService.shared.cancel(ids: ["daily-spending-reminder"])
        }
    }
}

