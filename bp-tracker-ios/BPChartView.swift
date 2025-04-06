import SwiftUI
import Charts // Import the framework

struct BPChartView: View {
    // Input: Array of readings to plot
    let readings: [Reading]

    // Find the min/max dates for sensible axis range, handling empty array
    private var dateRange: ClosedRange<Date> {
        guard !readings.isEmpty else {
            // Default range if no readings (e.g., today +/- a few days)
            let today = Calendar.current.startOfDay(for: Date())
            return today.addingTimeInterval(-86400*3)...today.addingTimeInterval(86400*3)
        }
        let sortedReadings = readings.sorted { $0.timestamp < $1.timestamp }
        let minDate = sortedReadings.first!.timestamp
        let maxDate = sortedReadings.last!.timestamp
        // Add a little padding to the date range
        return minDate.addingTimeInterval(-86400)...maxDate.addingTimeInterval(86400)
    }

    // Find min/max BP values for sensible Y-axis range
     private var bpRange: ClosedRange<Int> {
        guard !readings.isEmpty else {
            return 50...200 // Default range if empty
        }
        let allSys = readings.map { $0.systolic }
        let allDia = readings.map { $0.diastolic }
        let minVal = min(allSys.min() ?? 60, allDia.min() ?? 40) // Sensible floor
        let maxVal = max(allSys.max() ?? 180, allDia.max() ?? 120) // Sensible ceiling

        // Add padding to the range
        let lowerBound = max(0, minVal - 10) // Ensure non-negative
        let upperBound = maxVal + 10
        return lowerBound...upperBound
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Trend")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.bottom, 5)

            if readings.isEmpty {
                Text("Not enough data to show trend.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
            } else {
                Chart {
                    ForEach(readings) { reading in
                        // -- Systolic --
                        LineMark(
                            x: .value("Date", reading.timestamp),
                            y: .value("Systolic", reading.systolic)
                        )
                        .foregroundStyle(by: .value("Measurement", "Systolic"))
                        .symbol(Circle().strokeBorder(lineWidth: 1.5))

                        PointMark(
                             x: .value("Date", reading.timestamp),
                             y: .value("Systolic", reading.systolic)
                        )
                        .foregroundStyle(by: .value("Measurement", "Systolic"))
                        .symbolSize(CGSize(width: 5, height: 5))

                        // -- Diastolic --
                        LineMark(
                            x: .value("Date", reading.timestamp),
                            y: .value("Diastolic", reading.diastolic)
                        )
                        .foregroundStyle(by: .value("Measurement", "Diastolic"))
                        .symbol(BasicChartSymbolShape.square.strokeBorder(lineWidth: 1.5))

                        PointMark(
                            x: .value("Date", reading.timestamp),
                            y: .value("Diastolic", reading.diastolic)
                        )
                        .foregroundStyle(by: .value("Measurement", "Diastolic"))
                        .symbol(BasicChartSymbolShape.square)
                        .symbolSize(CGSize(width: 5, height: 5))
                    }
                }
                // Explicitly define colors for the series
                .chartForegroundStyleScale(
                    domain: ["Systolic", "Diastolic"],
                    range: [.blue, .green]
                )
                // Apply scale domains for consistent axis ranges
                .chartXScale(domain: dateRange)
                .chartYScale(domain: bpRange)
                // Add Axis Labels
                .chartYAxis { AxisMarks(preset: .automatic, values: .automatic(desiredCount: 5)) }
                .chartXAxis {
                    // Explicitly provide position parameter for AxisMarks initializer
                    AxisMarks(position: .bottom, values: .automatic(desiredCount: 5)) { value in
                         AxisGridLine()
                         AxisTick()
                         // Use AxisValueLabel for the text part
                         AxisValueLabel {
                             if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .font(.caption)
                             }
                         }
                     }
                 }
                .frame(height: 200) // Give the chart a defined height
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Preview
struct BPChartView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data for preview
        let previewReadings = [
            Reading(id: 1, timestamp: Date().addingTimeInterval(-86400 * 6), systolic: 120, diastolic: 80, pulse: 70, classification: "Normal"),
            Reading(id: 2, timestamp: Date().addingTimeInterval(-86400 * 5), systolic: 125, diastolic: 82, pulse: 72, classification: "Elevated"),
            Reading(id: 3, timestamp: Date().addingTimeInterval(-86400 * 4), systolic: 130, diastolic: 85, pulse: 75, classification: "Hypertension Stage 1"),
            Reading(id: 4, timestamp: Date().addingTimeInterval(-86400 * 3), systolic: 128, diastolic: 84, pulse: 71, classification: "Hypertension Stage 1"),
            Reading(id: 5, timestamp: Date().addingTimeInterval(-86400 * 2), systolic: 135, diastolic: 88, pulse: 78, classification: "Hypertension Stage 1"),
             Reading(id: 6, timestamp: Date().addingTimeInterval(-86400 * 1), systolic: 142, diastolic: 91, pulse: 80, classification: "Hypertension Stage 2"),
             Reading(id: 7, timestamp: Date(), systolic: 140, diastolic: 90, pulse: 77, classification: "Hypertension Stage 2"),
        ]

        BPChartView(readings: previewReadings)
            .padding()

        BPChartView(readings: []) // Empty state preview
             .padding()
    }
}
