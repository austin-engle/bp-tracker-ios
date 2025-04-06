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
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // Input fields for new readings
    @Published var systolic1: String = ""
    @Published var diastolic1: String = ""
    @Published var pulse1: String = ""
    @Published var systolic2: String = ""
    @Published var diastolic2: String = ""
    @Published var pulse2: String = ""
    @Published var systolic3: String = ""
    @Published var diastolic3: String = ""
    @Published var pulse3: String = ""

    private let networkService = NetworkService()

    func fetchReadings() async {
        isLoading = true
        errorMessage = nil
        do {
            readings = try await networkService.fetchReadings()
        } catch {
            if let networkError = error as? NetworkService.NetworkError {
                errorMessage = "Failed to fetch readings: \(networkError)" // Provide more specific error later
            } else {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            }
            print(errorMessage ?? "Unknown error") // Log error
        }
        isLoading = false
    }

    func submitReading() async {
        // Basic validation and conversion (improve later)
        guard let s1 = Int(systolic1), let d1 = Int(diastolic1), let p1 = Int(pulse1),
              let s2 = Int(systolic2), let d2 = Int(diastolic2), let p2 = Int(pulse2),
              let s3 = Int(systolic3), let d3 = Int(diastolic3), let p3 = Int(pulse3) else {
            errorMessage = "Please enter valid numbers for all fields."
            return
        }

        let input = ReadingInput(systolic1: s1, diastolic1: d1, pulse1: p1,
                                 systolic2: s2, diastolic2: d2, pulse2: p2,
                                 systolic3: s3, diastolic3: d3, pulse3: p3)

        isLoading = true
        errorMessage = nil
        do {
            try await networkService.submitReading(input: input)
            // Clear fields after successful submission
            clearInputFields()
            // Refresh the list to show the new reading (or rely on backend response if it included the new item)
            await fetchReadings()
        } catch {
             if let networkError = error as? NetworkService.NetworkError {
                errorMessage = "Failed to submit reading: \(networkError)" // Provide more specific error later
            } else {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            }
             print(errorMessage ?? "Unknown error") // Log error
            isLoading = false // Keep loading false on error
        }
        // isLoading is set to false in fetchReadings() upon success
    }

    private func clearInputFields() {
        systolic1 = ""; diastolic1 = ""; pulse1 = ""
        systolic2 = ""; diastolic2 = ""; pulse2 = ""
        systolic3 = ""; diastolic3 = ""; pulse3 = ""
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ReadingViewModel()

    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Add Reading Form
                // Simplified form directly in ContentView for now
                Section("Add New Reading") {
                    VStack {
                         HStack {
                            TextField("Systolic 1", text: $viewModel.systolic1).keyboardType(.numberPad)
                            TextField("Diastolic 1", text: $viewModel.diastolic1).keyboardType(.numberPad)
                            TextField("Pulse 1", text: $viewModel.pulse1).keyboardType(.numberPad)
                        }
                        HStack {
                            TextField("Systolic 2", text: $viewModel.systolic2).keyboardType(.numberPad)
                            TextField("Diastolic 2", text: $viewModel.diastolic2).keyboardType(.numberPad)
                            TextField("Pulse 3", text: $viewModel.pulse2).keyboardType(.numberPad)
                        }
                        HStack {
                            TextField("Systolic 3", text: $viewModel.systolic3).keyboardType(.numberPad)
                            TextField("Diastolic 3", text: $viewModel.diastolic3).keyboardType(.numberPad)
                            TextField("Pulse 3", text: $viewModel.pulse3).keyboardType(.numberPad)
                        }
                        Button("Submit Reading") {
                             Task {
                                 await viewModel.submitReading()
                             }
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.top)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom)

                // MARK: - Readings List
                List {
                    if viewModel.isLoading && viewModel.readings.isEmpty {
                        ProgressView("Loading readings...")
                    } else if let errorMessage = viewModel.errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                    } else if viewModel.readings.isEmpty {
                        Text("No readings found. Add one above!")
                    } else {
                        ForEach(viewModel.readings) { reading in
                            ReadingRow(reading: reading)
                        }
                    }
                }
                .navigationTitle("BP Tracker")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Button {
                                Task {
                                    await viewModel.fetchReadings()
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    }
                }
            }
            .task { // Use .task for async work tied to the view lifecycle
                if viewModel.readings.isEmpty { // Fetch only if list is empty initially
                   await viewModel.fetchReadings()
                }
            }
        }
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
                Text("Pulse: \(reading.pulse)")
                    .font(.subheadline)
                 Text(reading.timestamp, formatter: Self.dateFormatter)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(reading.classification)
                .font(.subheadline)
                .padding(5)
                .background(classificationColor(reading.classification))
                .foregroundColor(.white)
                .cornerRadius(5)
        }
    }

    // Helper to assign colors based on classification (customize as needed)
    private func classificationColor(_ classification: String) -> Color {
        switch classification.lowercased() {
        case "normal": return .green
        case "elevated": return .yellow.opacity(0.8)
        case "hypertension stage 1": return .orange
        case "hypertension stage 2": return .red
        case "hypertensive crisis": return .purple
        default: return .gray
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
