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
            // Optionally clear data on error?
            // self.readings = []
            // self.stats = nil
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
        isLoadingStats = true
        errorMessage = nil
        do {
            stats = try await networkService.fetchStats()
        } catch {
             if let networkError = error as? NetworkService.NetworkError {
                 errorMessage = "Failed to refresh stats: \(networkError)"
             } else {
                 errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
             }
            print(errorMessage ?? "Unknown error")
        }
        isLoadingStats = false
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

    // Remove clearInputFields as state is local to AddReadingView
    // private func clearInputFields() { ... }
}

struct ContentView: View {
    @StateObject private var viewModel = ReadingViewModel()
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            // Use ZStack for layering FAB over the content
            ZStack(alignment: .bottomTrailing) {
                // Main content ScrollView or List
                VStack(spacing: 0) { // Remove default VStack spacing
                    // MARK: - Stats View
                    StatsView(stats: viewModel.stats)
                        .padding(.bottom) // Add some space below stats

                     // MARK: - Loading/Error for Stats
                     // Consider placing inside StatsView or handling more gracefully
                     if viewModel.isLoadingStats {
                         ProgressView("Loading Stats...").padding()
                     }

                    // MARK: - Readings List Header
                     HStack {
                         Text("History")
                            .font(.title2)
                            .fontWeight(.bold)
                         Spacer()
                         // Optional: Add filtering/sorting controls here later
                     }
                     .padding(.horizontal)
                     .padding(.top)
                     .padding(.bottom, 5)
                     .background(Color(UIColor.systemGroupedBackground)) // Subtle background

                    Divider()

                    // MARK: - Readings List
                    List {
                        if viewModel.isLoadingReadings && viewModel.readings.isEmpty {
                            ProgressView("Loading readings...")
                        } else if let errorMessage = viewModel.errorMessage, viewModel.readings.isEmpty {
                             // Show general error if list is empty, could refine error display
                            Text("Error: \(errorMessage)")
                                .foregroundColor(.red)
                                .padding()
                        } else if viewModel.readings.isEmpty {
                            Text("No readings recorded yet.")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(viewModel.readings) { reading in
                                ReadingRow(reading: reading)
                                    // Apply list row styling if needed
                                    .listRowInsets(EdgeInsets()) // Remove default padding if using cards in ReadingRow
                                    .padding(.vertical, 4)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .listStyle(.plain) // Use plain style for less visual clutter
                    .refreshable { // Add pull-to-refresh
                        await viewModel.fetchAllData()
                    }
                    // Add bottom padding to prevent FAB overlap
                    .padding(.bottom, 60)

                } // End Main VStack

                // MARK: - Floating Action Button (FAB)
                 Button {
                     showingAddSheet = true
                 } label: {
                     HStack {
                         Image(systemName: "plus")
                         Text("Add Reading")
                     }
                     .padding()
                     .foregroundColor(.white)
                     .background(Color.blue) // Or your app's accent color
                     .clipShape(Capsule())
                     .shadow(radius: 5)
                     .padding() // Padding from the edge of the screen
                 }

            } // End ZStack
            .navigationTitle("Blood Pressure Tracker") // Change title back to full name
            .toolbar {
                 // Remove the old toolbar item
                 /*
                 ToolbarItem(placement: .navigationBarTrailing) {
                      Button {
                          showingAddSheet = true
                      } label: {
                          Image(systemName: "plus.circle.fill")
                              .font(.title2) // Make icon slightly larger
                      }
                 }
                 */
            }
            // Use .task for initial data load
            .task {
                if viewModel.readings.isEmpty && viewModel.stats == nil {
                   await viewModel.fetchAllData()
                }
            }
            // Sheet for adding new readings
            .sheet(isPresented: $showingAddSheet) {
                AddReadingView() { newInput in
                    // This closure is called by AddReadingView on successful save
                    Task {
                         do {
                             try await viewModel.submitReading(input: newInput)
                             // If submitReading is successful, dismiss the sheet
                             showingAddSheet = false
                         } catch {
                            // Error is handled and published by ViewModel
                            // Sheet remains open for user to see/correct
                            print("Submission failed, sheet stays open.")
                         }
                    }
                }
                 // Inject environment object if ViewModel needed deeper
                 // .environmentObject(viewModel)
            }
        }
        .navigationViewStyle(.stack) // Use stack style for standard behavior
    }
}

// Simple row view for displaying a single reading
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
                    .foregroundColor(.secondary) // Use secondary color for timestamp
                Text("Pulse: \(reading.pulse) bpm")
                    .font(.callout) // Slightly smaller font for pulse
                    .foregroundColor(.gray)
            }
            Spacer()
            // Classification Badge
             Text(reading.classification)
                .font(.caption).bold()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(classificationColor(reading.classification)) // Use updated helper
                .foregroundColor(.white)
                .clipShape(Capsule()) // Use Capsule shape
        }
        .cardStyle()
        .padding(.bottom, 8) // Add space between cards in the list
    }
}

// Helper function to assign colors based on classification (customize as needed)
func classificationColor(_ classification: String) -> Color {
    switch classification.lowercased() {
    case "normal": return .green
    case "elevated": return .yellow.opacity(0.9) // Slightly less transparent yellow
    case "hypertension stage 1": return .orange.opacity(0.9)
    case "hypertension stage 2": return .red.opacity(0.85) // Soften red
    case "hypertensive crisis": return .purple
    default: return .gray
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
