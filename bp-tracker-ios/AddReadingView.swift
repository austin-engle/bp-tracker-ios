import SwiftUI

// Removed ReadingInputCard as layout is integrated now

struct AddReadingView: View {
    // State for input fields (9 total)
    @State private var systolic1: String = ""
    @State private var diastolic1: String = ""
    @State private var pulse1: String = ""
    @State private var systolic2: String = ""
    @State private var diastolic2: String = ""
    @State private var pulse2: String = ""
    @State private var systolic3: String = ""
    @State private var diastolic3: String = ""
    @State private var pulse3: String = ""

    @State private var validationError: String? = nil
    @State private var isSaving = false

    @Environment(\.dismiss) var dismiss
    var onSave: (ReadingInput) -> Void
    @FocusState private var focusedField: Field?

    // Define order for focus navigation
    enum Field: Int, CaseIterable, Hashable {
        case s1, d1, p1, s2, d2, p2, s3, d3, p3
    }

    var body: some View {
        NavigationView {
            ScrollView {
                 VStack(alignment: .leading, spacing: 15) { // Added spacing for elements
                     // 1. Contextual Text
                     Text("Enter three readings taken a few minutes apart for an accurate average.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 5) // Space below context text

                     // Validation Error Display (if needed)
                      if let error = validationError {
                          Text(error)
                              .foregroundColor(.red)
                              .font(.caption)
                              .padding(.horizontal)
                      }

                    // 2. Single Card Layout
                     VStack(alignment: .leading, spacing: 12) {
                         readingSection(number: 1,
                                        systolic: $systolic1, diastolic: $diastolic1, pulse: $pulse1,
                                        sField: .s1, dField: .d1, pField: .p1)
                         Divider()
                         readingSection(number: 2,
                                        systolic: $systolic2, diastolic: $diastolic2, pulse: $pulse2,
                                        sField: .s2, dField: .d2, pField: .p2)
                         Divider()
                         readingSection(number: 3,
                                        systolic: $systolic3, diastolic: $diastolic3, pulse: $pulse3,
                                        sField: .s3, dField: .d3, pField: .p3)
                     }
                     .padding() // Internal padding for the card content
                     .background(Color(UIColor.secondarySystemBackground)) // Card background
                     .cornerRadius(16)
                     .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                     .padding(.horizontal) // Padding around the card

                     Spacer() // Pushes card up if content is short
                }
                 .padding(.top) // Add padding at the top of the scroll content
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea()) // Background for the whole screen
            .navigationTitle("Add New Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { saveReading() }
                            .disabled(!isFormValid() || isSaving)
                    }
                }

                // 3. Keyboard Toolbar Navigation
                 ToolbarItemGroup(placement: .keyboard) {
                     Button("Prev", action: focusPreviousField)
                         .disabled(!canFocusPrevious())

                     Button("Next", action: focusNextField)
                          .disabled(!canFocusNext())

                     Spacer()
                     Button("Done") { focusedField = nil }
                 }
            }
        }
    }

    // Helper ViewBuilder for a single reading input section within the card
    @ViewBuilder
    private func readingSection(number: Int, systolic: Binding<String>, diastolic: Binding<String>, pulse: Binding<String>, sField: Field, dField: Field, pField: Field) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading \(number)")
                .font(.headline)

            HStack(spacing: 12) {
                inputField(label: "Systolic", placeholder: "e.g. 120", text: systolic, field: sField)
                inputField(label: "Diastolic", placeholder: "e.g. 80", text: diastolic, field: dField)
                inputField(label: "Pulse", placeholder: "e.g. 72", text: pulse, field: pField)
            }
        }
    }

    // Helper for styled input fields (remains mostly the same)
    @ViewBuilder
    private func inputField(label: String, placeholder: String, text: Binding<String>, field: Field) -> some View {
        let isFocused = focusedField == field
        VStack(alignment: .leading, spacing: 3) {
             Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .padding(10)
                .background(
                     ZStack {
                         RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemBackground))
                         RoundedRectangle(cornerRadius: 8).strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                     }
                 )
                 .shadow(color: .black.opacity(isFocused ? 0.15 : 0.05), radius: isFocused ? 3 : 1, x: 0, y: isFocused ? 2 : 1)
                 .overlay(
                     RoundedRectangle(cornerRadius: 8).stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                 )
                .focused($focusedField, equals: field)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }

    // --- Focus Navigation Logic ---
    private func focusPreviousField() {
        guard let currentFocus = focusedField, let currentIndex = Field.allCases.firstIndex(of: currentFocus) else { return }
        let previousIndex = currentIndex - 1
        if previousIndex >= 0 {
            focusedField = Field.allCases[previousIndex]
        }
    }

    private func focusNextField() {
        guard let currentFocus = focusedField, let currentIndex = Field.allCases.firstIndex(of: currentFocus) else { return }
        let nextIndex = currentIndex + 1
        if nextIndex < Field.allCases.count {
            focusedField = Field.allCases[nextIndex]
        } else {
            focusedField = nil // Dismiss keyboard after last field
        }
    }

    private func canFocusPrevious() -> Bool {
        guard let currentFocus = focusedField, let currentIndex = Field.allCases.firstIndex(of: currentFocus) else { return false }
        return currentIndex > 0
    }

     private func canFocusNext() -> Bool {
        guard let currentFocus = focusedField, let currentIndex = Field.allCases.firstIndex(of: currentFocus) else { return false }
        // Allow Next until the very last field
        return currentIndex < Field.allCases.count - 1
    }

    // --- Validation and Saving Logic (Unchanged) ---
    private func isFormValid() -> Bool {
        return Int(systolic1) != nil && Int(diastolic1) != nil && Int(pulse1) != nil &&
               Int(systolic2) != nil && Int(diastolic2) != nil && Int(pulse2) != nil &&
               Int(systolic3) != nil && Int(diastolic3) != nil && Int(pulse3) != nil
    }

    private func saveReading() {
         guard let s1 = Int(systolic1), let d1 = Int(diastolic1), let p1 = Int(pulse1),
               let s2 = Int(systolic2), let d2 = Int(diastolic2), let p2 = Int(pulse2),
               let s3 = Int(systolic3), let d3 = Int(diastolic3), let p3 = Int(pulse3) else {
             validationError = "Please enter valid whole numbers for all fields."
             return
         }

         validationError = nil
         isSaving = true

         let input = ReadingInput(systolic1: s1, diastolic1: d1, pulse1: p1,
                                  systolic2: s2, diastolic2: d2, pulse2: p2,
                                  systolic3: s3, diastolic3: d3, pulse3: p3)

         onSave(input)

         Task { @MainActor in
              try? await Task.sleep(nanoseconds: 500_000_000)
              isSaving = false
         }
    }
}

// Preview Provider (Optional)
struct AddReadingView_Previews: PreviewProvider {
    static var previews: some View {
        AddReadingView() { readingInput in
            print("Preview Save Tapped: \(readingInput)")
        }
    }
}
