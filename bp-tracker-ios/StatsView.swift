import SwiftUI

struct StatsView: View {
    let stats: Stats? // Receive stats from ContentView

    // State for the selected average tab
    @State private var selectedAveragePeriod: AveragePeriod = .sevenDay

    enum AveragePeriod: String, CaseIterable, Identifiable {
        case sevenDay = "7 Day Avg"
        case thirtyDay = "30 Day Avg"
        case allTime = "All Time Avg"
        var id: String { self.rawValue }
    }

    // Date formatter for the last reading timestamp
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading) {
            Text("Summary")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)

            // Display Last Reading
             if let last = stats?.lastReading {
                  HStack {
                     VStack(alignment: .leading) {
                         Text("Last Reading")
                             .font(.caption)
                             .foregroundColor(.secondary)
                         HStack(alignment: .firstTextBaseline) {
                              Text("\(last.systolic)/\(last.diastolic)")
                                 .font(.title).fontWeight(.semibold) // Larger font for BP
                              Text("Pulse: \(last.pulse)") // Shortened Pulse label
                                 .font(.subheadline)
                                 .foregroundColor(.gray)
                                 .padding(.leading, 5)
                         }
                         Text(last.timestamp, formatter: Self.dateFormatter)
                              .font(.caption)
                              .foregroundColor(.gray)
                     }
                     Spacer()
                     // Classification Badge (softened color, maybe icon)
                      Text(last.classification)
                           .font(.caption).bold()
                           .padding(.horizontal, 6).padding(.vertical, 3)
                           .background(classificationColor(last.classification).opacity(0.8)) // Soften color slightly
                           .foregroundColor(.white)
                           .clipShape(Capsule())
                  }
             } else if stats != nil { // Only show if stats loaded but no last reading
                 Text("Last Reading: N/A")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
             }

            Divider().padding(.vertical, 4)

            // Display Averages in a Grid
            // Averages Section with Tabs
            VStack(alignment: .leading) {
                Picker("Average Period", selection: $selectedAveragePeriod) {
                    ForEach(AveragePeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 5)

                // Display content based on selected tab
                selectedAverageView()
                    .frame(maxWidth: .infinity, alignment: .center) // Center content
            }
        }
         // Apply the reusable card style modifier
        .cardStyle() // Uses default values from the modifier
        .padding(.horizontal)
    }

    // View builder to show the correct average based on selection
    @ViewBuilder
    private func selectedAverageView() -> some View {
        switch selectedAveragePeriod {
        case .sevenDay:
            averageDisplay(average: stats?.sevenDayAvg, count: stats?.sevenDayCount)
        case .thirtyDay:
            averageDisplay(average: stats?.thirtyDayAvg, count: stats?.thirtyDayCount)
        case .allTime:
            averageDisplay(average: stats?.allTimeAvg, count: stats?.allTimeCount)
        }
    }

    // Reusable view for displaying the selected average details
    @ViewBuilder
    private func averageDisplay(average: Reading?, count: Int?) -> some View {
        let statCount = count ?? 0
        VStack {
            if let avg = average {
                Text("\(avg.systolic)/\(avg.diastolic)")
                    .font(.title2).fontWeight(.medium)
                    .fontWeight(.bold)
                Text("Pulse: \(avg.pulse) bpm")
                    .font(.subheadline).foregroundColor(.gray)
                 Text("(\(statCount) readings)")
                     .font(.caption).foregroundColor(.gray)
                 Text(avg.classification)
                     .font(.caption).bold()
                     .padding(.horizontal, 6).padding(.vertical, 3)
                     .background(classificationColor(avg.classification).opacity(0.8))
                     .foregroundColor(.white)
                     .clipShape(Capsule())
                     .padding(.top, 2)

            } else if stats != nil { // Stats loaded but no average
                Text("N/A")
                    .font(.title2).fontWeight(.medium)
                     .foregroundColor(.secondary)
                 Text("(\(statCount) readings)")
                     .font(.caption).foregroundColor(.gray)
            } else {
                // Placeholder while stats are loading
                 Text("--/--")
                    .font(.title2).fontWeight(.medium)
                     .foregroundColor(.secondary)
                 ProgressView() // Show loading indicator within the tab content area
            }
        }
        .padding(.top, 5)
    }
}

// Preview Provider (Optional)
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        // Example with some data
        let previewStats = Stats(
            lastReading: Reading(id: 1, timestamp: Date().addingTimeInterval(-3600), systolic: 118, diastolic: 75, pulse: 65, classification: "Normal"),
            sevenDayAvg: Reading(id: 0, timestamp: Date(), systolic: 122, diastolic: 81, pulse: 68, classification: "Elevated"),
            sevenDayCount: 15,
            thirtyDayAvg: Reading(id: 0, timestamp: Date(), systolic: 125, diastolic: 83, pulse: 70, classification: "Hypertension Stage 1"),
            thirtyDayCount: 60,
            allTimeAvg: Reading(id: 0, timestamp: Date(), systolic: 124, diastolic: 82, pulse: 69, classification: "Elevated"),
            allTimeCount: 150
        )

        // Example with no data (after initial load)
         let emptyStats = Stats.empty

        VStack {
            StatsView(stats: previewStats)
            StatsView(stats: emptyStats)
            StatsView(stats: nil) // Simulates loading state
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
