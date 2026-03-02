import SwiftUI

struct GPACalculatorView: View {

    @State private var courses: [CourseEntry] = [CourseEntry()]

    private var gpa: Double {
        let validCourses = courses.filter { $0.credits > 0 }
        guard !validCourses.isEmpty else { return 0 }
        let totalPoints = validCourses.reduce(0.0) { $0 + $1.gradePoints * Double($1.credits) }
        let totalCredits = validCourses.reduce(0) { $0 + $1.credits }
        return totalCredits > 0 ? totalPoints / Double(totalCredits) : 0
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                gpaHeader

                List {
                    ForEach($courses) { $course in
                        CourseRow(course: $course)
                    }
                    .onDelete { courses.remove(atOffsets: $0) }
                }
                .listStyle(.insetGrouped)
            }

            Button {
                courses.append(CourseEntry())
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(AppGradients.primary)
                    .clipShape(Circle())
                    .shadow(color: AppColors.coral.opacity(0.4), radius: 8, y: 4)
            }
            .padding(20)
        }
    }

    private var gpaHeader: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.2f", gpa))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(gpaColor)
            Text("Semester GPA")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppColors.secondaryBackground)
    }

    private var gpaColor: Color {
        if gpa >= 3.5 { return AppColors.green }
        if gpa >= 3.0 { return AppColors.teal }
        if gpa >= 2.0 { return AppColors.orange }
        return AppColors.coral
    }
}

// MARK: - Course Entry

private struct CourseEntry: Identifiable {
    let id = UUID()
    var name = ""
    var credits = 3
    var grade = "A"

    var gradePoints: Double {
        switch grade {
        case "A": return 4.0
        case "A-": return 3.7
        case "B+": return 3.3
        case "B": return 3.0
        case "B-": return 2.7
        case "C+": return 2.3
        case "C": return 2.0
        case "C-": return 1.7
        case "D+": return 1.3
        case "D": return 1.0
        case "F": return 0.0
        default: return 0.0
        }
    }

    static let allGrades = ["A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "F"]
}

private struct CourseRow: View {
    @Binding var course: CourseEntry

    var body: some View {
        VStack(spacing: 10) {
            TextField("Course Name", text: $course.name)
                .font(.subheadline)

            HStack {
                HStack {
                    Text("Credits")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Stepper("\(course.credits)", value: $course.credits, in: 1...6)
                        .font(.subheadline.bold())
                }

                Spacer()

                Picker("Grade", selection: $course.grade) {
                    ForEach(CourseEntry.allGrades, id: \.self) { grade in
                        Text(grade).tag(grade)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppColors.coral)
            }
        }
        .padding(.vertical, 4)
    }
}
