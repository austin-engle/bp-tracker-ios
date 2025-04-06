import SwiftUI

struct SummaryTabView: View {
    @EnvironmentObject var viewModel: ReadingViewModel // Access the shared ViewModel
    @State private var selectedAveragePeriod: StatsView.AveragePeriod = .sevenDay // Own the state here

    // Computed property to filter readings based on selected period
    private var filteredReadings: [Reading] {
        let now = Date()
        let calendar = Calendar.current

        switch selectedAveragePeriod {
        case .sevenDay:
            guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return viewModel.readings } // Should handle error better
            return viewModel.readings.filter { $0.timestamp >= sevenDaysAgo && $0.timestamp <= now }
        case .thirtyDay:
             guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return viewModel.readings }
            return viewModel.readings.filter { $0.timestamp >= thirtyDaysAgo && $0.timestamp <= now }
        case .allTime:
            return viewModel.readings // Return all readings
        }
    }

    var body: some View {
        // Use a ScrollView or just a VStack depending on content complexity
        // ScrollView might be better for future additions
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Conditional Content based on Loading/Error State
                if viewModel.isLoadingStats && viewModel.stats == nil { // Initial loading state
                    // Show centered progress view for initial load
                    ProgressView("Loading Summary...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 50) // Add padding to center it vertically somewhat
                } else if let errorMessage = viewModel.errorMessage { // Error state
                    // Display error prominently
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error Loading Summary")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await viewModel.fetchStatsOnly() } // Or fetchAllData()
                        }
                        .padding(.top)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)

                } else { // Loaded state (or loading update)
                    // Display the StatsView normally, passing the binding
                    StatsView(stats: viewModel.stats, selectedAveragePeriod: $selectedAveragePeriod)

                    // --- Add the Chart View Here ---
                    BPChartView(readings: filteredReadings) // Pass filtered readings from ViewModel

                    // Optionally show subtle progress if just updating
                    // if viewModel.isLoadingReadings || viewModel.isLoadingStats { // Temporarily disabled refresh indicator
                    //     ProgressView()
                    //         .controlSize(.small)
                    //         .frame(maxWidth: .infinity, alignment: .center)
                    //         .padding(.top, 5)
                    // }
                }

                // Add other summary elements here later if needed
                // e.g., Insights, Charts, etc.

                // Removed Spacer to allow content to determine height
                // Spacer()
            }
            .padding(.top) // Add some padding at the top of the scroll view content
        }
        // Apply refreshable here if desired
         .refreshable { await viewModel.fetchStatsOnly() }
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
