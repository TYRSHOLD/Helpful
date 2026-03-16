import Foundation

struct ForecastPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ForecastResult {
    let points: [ForecastPoint]
}

enum ForecastEngine {
    static func makeSavingsForecast(
        startingBalance: Double,
        monthlyNet: Double,
        months: Int,
        startDate: Date = Date()
    ) -> ForecastResult {
        var points: [ForecastPoint] = []
        var balance = startingBalance
        let calendar = Calendar.current

        for offset in 0..<max(months, 0) {
            guard let date = calendar.date(byAdding: .month, value: offset, to: startDate) else { continue }
            // For month 0 we just show current balance; subsequent months apply net change.
            if offset > 0 {
                balance += monthlyNet
            }
            points.append(ForecastPoint(date: date, value: balance))
        }

        return ForecastResult(points: points)
    }
}

