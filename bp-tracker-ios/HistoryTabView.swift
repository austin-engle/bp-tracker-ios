import SwiftUI

struct HistoryTabView: View {
    @EnvironmentObject var viewModel: ReadingViewModel // Access the shared ViewModel

    var body: some View {
        // MARK: - Readings List
        List {
            if viewModel.isLoadingReadings && viewModel.readings.isEmpty {
                ProgressView("Loading readings...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.readings.isEmpty {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.readings.isEmpty {
                Text("No readings recorded yet.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                // Note: Grouping by date would require additional logic here
                ForEach(viewModel.readings) { reading in
                    ReadingRow(reading: reading)
                        .listRowInsets(EdgeInsets()) // Remove default padding
                        .padding(.vertical, 4)
                        .padding(.horizontal)
                }
                .onDelete(perform: viewModel.deleteReading) // Add swipe-to-delete
            }
        }
        .listStyle(.plain)
        .refreshable {
            // Refresh both readings and stats when pulling history
            await viewModel.fetchAllData()
        }
    }
}

// MARK: - Reading Row (Moved Here)
struct ReadingRow: View {
    let reading: Reading

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack {
             VStack(alignment: .leading) {
                 Text("\(reading.systolic) / \(reading.diastolic)")
                     .font(.headline)
                  Text(reading.timestamp, formatter: Self.dateFormatter)
                      .font(.subheadline)
                      .foregroundColor(.secondary)
                 Text("Pulse: \(reading.pulse) bpm")
                     .font(.callout)
                     .foregroundColor(.gray)
             }
             Spacer()
             Text(reading.classification)
                 .font(.caption).bold()
                 .padding(.horizontal, 8)
                 .padding(.vertical, 4)
                 .background(classificationColor(reading.classification))
                 .foregroundColor(.white)
                 .clipShape(Capsule())
         }
         .cardStyle() // Apply card style if View+Card.swift exists
         .padding(.bottom, 8) // Add space between cards
    }
}

// MARK: - Preview Provider
struct HistoryTabView_Previews: PreviewProvider {

    // Helper static property for mock ViewModel
    static var mockViewModel: ReadingViewModel {
        let viewModel = ReadingViewModel()
        viewModel.readings = [
            Reading(id: 1, timestamp: Date(), systolic: 125, diastolic: 82, pulse: 70, classification: "Hypertension Stage 1"),
            Reading(id: 2, timestamp: Date().addingTimeInterval(-86400), systolic: 140, diastolic: 91, pulse: 75, classification: "Hypertension Stage 2"),
            Reading(id: 3, timestamp: Date().addingTimeInterval(-172800), systolic: 118, diastolic: 78, pulse: 68, classification: "Normal")
        ]
        return viewModel
    }

    static var previews: some View {
        // Use the helper property
        HistoryTabView()
            .environmentObject(mockViewModel)
    }
}
