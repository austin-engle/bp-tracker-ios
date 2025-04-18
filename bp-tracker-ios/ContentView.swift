//
//  ContentView.swift
//  bp-tracker-ios
//
//  Created by Austin Engle on 4/5/25.
//

import SwiftUI

// ViewModel to manage state and interact with the NetworkService
@MainActor // Ensure UI updates happen on the main thread
class ReadingViewModel: ObservableObject {
    @Published var readings: [Reading] = []
    @Published var stats: Stats? = nil // Add stats property
    @Published var isLoadingReadings = false // Separate loading states
    @Published var isLoadingStats = false
    @Published var isSubmitting = false
    @Published var errorMessage: String? = nil

    // Remove input fields, they will live in AddReadingView's @State
    // @Published var systolic1: String = ""
    // ... remove other input fields ...

    private let networkService = NetworkService()

    // Combined fetch function
    func fetchAllData() async {
        // Run fetches concurrently
        isLoadingReadings = true
        isLoadingStats = true
        errorMessage = nil

        async let readingsTask = networkService.fetchReadings()
        async let statsTask = networkService.fetchStats()

        do {
            let fetchedReadings = try await readingsTask
            let fetchedStats = try await statsTask

            // Update published properties on the main actor
            self.readings = fetchedReadings
            self.stats = fetchedStats

        } catch {
            if let networkError = error as? NetworkService.NetworkError {
                errorMessage = "Failed to fetch data: \(networkError)" // Generic error for combined fetch
            } else {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            }
            print(errorMessage ?? "Unknown error") // Log error
        }

        isLoadingReadings = false
        isLoadingStats = false
    }

    // Keep separate fetch functions if needed for specific refresh actions
    func fetchReadingsOnly() async {
        isLoadingReadings = true
        errorMessage = nil
        do {
            readings = try await networkService.fetchReadings()
        } catch {
             if let networkError = error as? NetworkService.NetworkError {
                 errorMessage = "Failed to refresh readings: \(networkError)"
             } else {
                 errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
             }
            print(errorMessage ?? "Unknown error")
        }
        isLoadingReadings = false
    }

     func fetchStatsOnly() async {
         errorMessage = nil // Clear error before trying
         do {
             // Assign directly - this seemed okay before
             stats = try await networkService.fetchStats()
         } catch {
             print("Error during fetchStatsOnly: \(error.localizedDescription)")
         }
     }

    // Submit function now takes input from the AddReadingView
    func submitReading(input: ReadingInput) async throws { // Make it throw so sheet can handle error/dismiss
        isSubmitting = true
        errorMessage = nil // Clear previous errors
        do {
            try await networkService.submitReading(input: input)
            // Refresh data after successful submission
            await fetchAllData()
            isSubmitting = false
        } catch {
             isSubmitting = false // Ensure loading state is reset on error
             // Re-throw the error so the calling view (AddReadingView via ContentView) knows about it
            if let networkError = error as? NetworkService.NetworkError {
                 print("Submit failed: \(networkError)")
                 errorMessage = "Failed to submit reading: \(networkError)"
            } else {
                 print("Submit failed: \(error.localizedDescription)")
                 errorMessage = "An unexpected error occurred during submission."
            }
            throw error // Re-throw the original error
        }
    }

    /// Deletes a reading locally and via the network service.
    func deleteReading(at offsets: IndexSet) {
        // Get the readings to delete from the current array based on offsets
        let readingsToDelete = offsets.map { readings[$0] }

        // Remove from local array immediately for UI responsiveness
        readings.remove(atOffsets: offsets)

        // Call network service for each reading to delete
        Task {
            for reading in readingsToDelete {
                do {
                    try await networkService.deleteReading(id: reading.id)
                    // Optionally refresh stats after successful delete
                    // await fetchStatsOnly()
                } catch {
                    // Handle error - e.g., show alert, add reading back to list?
                    errorMessage = "Failed to delete reading (ID: \(reading.id)): \(error.localizedDescription)"
                    print(errorMessage ?? "Unknown delete error")
                }
            }
        }
    }
}

// MARK: - Classification Color Helper (Global Scope for now)
func classificationColor(_ classification: String) -> Color {
    switch classification.lowercased() {
    case "normal": return .green
    case "elevated": return .yellow.opacity(0.9)
    case "hypertension stage 1": return .orange.opacity(0.9)
    case "hypertension stage 2": return .red.opacity(0.85)
    case "hypertensive crisis": return .purple
    default: return .gray
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ReadingViewModel()
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            // TabView is now the main content
            TabView {
                // Summary Tab (References new SummaryTabView)
                SummaryTabView()
                    .tabItem {
                        Label("Summary", systemImage: "heart.text.square.fill")
                    }

                // History Tab (References new HistoryTabView)
                HistoryTabView()
                    .tabItem {
                        Label("History", systemImage: "list.bullet")
                    }
            }
            // Attach the FAB as an overlay to the TabView
            .overlay(alignment: .bottomTrailing) {
                 Button {
                     showingAddSheet = true
                 } label: {
                     HStack {
                         Image(systemName: "plus")
                         Text("Add Reading")
                     }
                     .padding(.horizontal, 16)
                     .padding(.vertical, 10)
                     .foregroundColor(.white)
                     .background(Color.blue)
                     .clipShape(Capsule())
                     // Apply shadow directly to the button visual
                     .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                 }
                 // Apply padding *here* to position the button within the overlay area
                 .padding(.trailing, 20)
                 .padding(.bottom, 75) // Keep increased bottom padding
             }
             // Add the .task modifier back to fetch initial data
             .task {
                 // Fetch data once when the main TabView appears
                if viewModel.readings.isEmpty && viewModel.stats == nil {
                   await viewModel.fetchAllData()
                }
             }
             // Sheet for adding new readings
             .sheet(isPresented: $showingAddSheet) {
                 // Pass the ViewModel to the sheet if AddReadingView needs it directly
                 // Or handle submission via closure as before
                 AddReadingView() { newInput in
                     Task {
                          do {
                              try await viewModel.submitReading(input: newInput)
                              showingAddSheet = false
                          } catch {
                             print("Submission failed, sheet stays open.")
                          }
                     }
                 }
                  // Make ViewModel available to all tabs and the sheet
                  .environmentObject(viewModel)
             }
        }
        // Apply EnvironmentObject to the NavigationView content
        .environmentObject(viewModel)
        .navigationViewStyle(.stack)
        // Toolbar is now empty as FAB handles add action
        .toolbar { }
        // Use .task for initial data load (might need adjustment based on tab appearance)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
