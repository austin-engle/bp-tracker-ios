import SwiftUI

struct SummaryTabView: View {
    @EnvironmentObject var viewModel: ReadingViewModel // Access the shared ViewModel

    var body: some View {
        // Use a ScrollView in case content grows
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Display the StatsView, passing the stats from the ViewModel
                StatsView(stats: viewModel.stats)

                // Show loading indicator for stats specifically
                if viewModel.isLoadingStats {
                    HStack {
                        Spacer()
                        ProgressView("Loading Summary...")
                        Spacer()
                    }
                }

                // Display error message if relevant to this tab
                // Consider filtering errors or having specific error properties
                if let errorMessage = viewModel.errorMessage, !viewModel.isLoadingStats {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }

                // Add other summary elements here later if needed
                // e.g., Insights, Charts, etc.

                Spacer() // Pushes content to the top
            }
            .padding(.top) // Add some padding at the top of the scroll view
        }
        // Potentially add a refreshable modifier here too if needed
        // .refreshable { await viewModel.fetchStatsOnly() }
        // Consider if pull-to-refresh makes sense on the summary page
    }
}

// MARK: - Preview Provider for SummaryTabView
struct SummaryTabView_Previews: PreviewProvider {

    // Helper function/property to create a loaded view model
    static var loadedViewModel: ReadingViewModel {
        let viewModel = ReadingViewModel()
        viewModel.stats = Stats(
            lastReading: Reading(id: 1, timestamp: Date().addingTimeInterval(-3600), systolic: 118, diastolic: 75, pulse: 65, classification: "Normal"),
            sevenDayAvg: Reading(id: 0, timestamp: Date(), systolic: 122, diastolic: 81, pulse: 68, classification: "Elevated"),
            sevenDayCount: 15,
            thirtyDayAvg: Reading(id: 0, timestamp: Date(), systolic: 125, diastolic: 83, pulse: 70, classification: "Hypertension Stage 1"),
            thirtyDayCount: 60,
            allTimeAvg: Reading(id: 0, timestamp: Date(), systolic: 124, diastolic: 82, pulse: 69, classification: "Elevated"),
            allTimeCount: 150
        )
        return viewModel
    }

    // Helper function/property to create a loading view model
    static var loadingViewModel: ReadingViewModel {
        let viewModel = ReadingViewModel()
        viewModel.isLoadingStats = true
        return viewModel
    }

    // Helper function/property to create an empty view model
    static var emptyViewModel: ReadingViewModel {
        let viewModel = ReadingViewModel()
        viewModel.stats = Stats(lastReading: nil, sevenDayAvg: nil, sevenDayCount: 0, thirtyDayAvg: nil, thirtyDayCount: 0, allTimeAvg: nil, allTimeCount: 0)
        return viewModel
    }

    static var previews: some View {
        Group { // Use Group to provide multiple previews
            // --- Use Helper Properties ---
            SummaryTabView()
                .environmentObject(loadedViewModel) // Use helper
                .previewDisplayName("Loaded State")

            SummaryTabView()
                .environmentObject(loadingViewModel) // Use helper
                .previewDisplayName("Loading State")

            SummaryTabView()
                .environmentObject(emptyViewModel) // Use helper
                .previewDisplayName("Empty State")
        }
    }
}
