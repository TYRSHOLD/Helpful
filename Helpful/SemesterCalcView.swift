import SwiftUI

struct SemesterCalcView: View {

    @State private var selectedCalc = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Calculator", selection: $selectedCalc) {
                Text("GPA").tag(0)
                Text("Costs").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedCalc == 0 {
                GPACalculatorView()
            } else {
                CostCalculatorView()
            }
        }
        .navigationTitle("Semester Tools")
    }
}
