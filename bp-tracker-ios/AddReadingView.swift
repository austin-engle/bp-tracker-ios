import SwiftUI

// Reusable card view for entering one reading's data
struct ReadingInputCard: View {
    let readingNumber: Int
    @Binding var systolic: String
    @Binding var diastolic: String
    @Binding var pulse: String

    // Focus state bindings passed from parent
    @FocusState.Binding var focusedField: AddReadingView.Field?
    let systolicField: AddReadingView.Field
    let diastolicField: AddReadingView.Field
    let pulseField: AddReadingView.Field

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { // Explicit spacing inside card
            // Card Header
            HStack {
                Text("🩺") // Stethoscope Icon
                    .font(.title2)
                Text("Reading \(readingNumber)")
                    .font(.headline)
                Spacer() // Push header content left
            }
            // .padding(.bottom, 5) // Use VStack spacing instead

            // Input Fields
            HStack(spacing: 12) { // Consistent spacing for input fields
                inputField(label: "Systolic", placeholder: "e.g. 120", text: $systolic, field: systolicField)
                inputField(label: "Diastolic", placeholder: "e.g. 80", text: $diastolic, field: diastolicField)
                inputField(label: "Pulse", placeholder: "e.g. 72", text: $pulse, field: pulseField)
            }
        }
        .padding(12) // Explicit internal padding
        .background(Color(UIColor.systemGray6)) // Light gray background
        .cornerRadius(16) // Slightly larger radius
        // Add subtle shadow to the card itself
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal) // Padding for the card itself
        .padding(.bottom, 16) // Space below card (margin)
    }

    // Helper for styled input fields
    @ViewBuilder
    private func inputField(label: String, placeholder: String, text: Binding<String>, field: AddReadingView.Field) -> some View {
        // Determine if this field is focused
        let isFocused = focusedField == field

        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .padding(10) // Adjust padding
                .background(
                     // Use a ZStack for layering background, border, and shadow
                     ZStack {
                         RoundedRectangle(cornerRadius: 8)
                             .fill(Color(UIColor.systemBackground))
                         RoundedRectangle(cornerRadius: 8)
                              // Subtle inner shadow for depth when not focused
                             .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                     }
                 )
                 // Add a subtle elevation shadow to the text field itself
                 .shadow(color: .black.opacity(isFocused ? 0.15 : 0.05), radius: isFocused ? 3 : 1, x: 0, y: isFocused ? 2 : 1)
                 .overlay(
                     // Highlight border when focused
                     RoundedRectangle(cornerRadius: 8)
                         .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2) // Blue border on focus
                 )
                .focused($focusedField, equals: field)
                .animation(.easeInOut(duration: 0.2), value: isFocused) // Animate focus changes
        }
    }
}

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

    // Environment variable to dismiss the sheet
    @Environment(\.dismiss) var dismiss

    // Closure to call when save is successful
    var onSave: (ReadingInput) -> Void

    // Focus state management (iOS 15+)
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case s1, d1, p1, s2, d2, p2, s3, d3, p3
    }

    var body: some View {
        NavigationView {
            ScrollView { // Use ScrollView instead of Form
                 VStack(spacing: 0) { // Keep spacing 0, handled by card padding
                     // Validation Error Display (moved to top)
                      if let error = validationError {
                          Text(error)
                              .foregroundColor(.red)
                              .font(.caption)
                              .padding(.horizontal)
                              .padding(.bottom, 5)
                      }

                    // Reading Input Cards
                    ReadingInputCard(readingNumber: 1,
                                     systolic: $systolic1, diastolic: $diastolic1, pulse: $pulse1,
                                     focusedField: $focusedField,
                                     systolicField: .s1, diastolicField: .d1, pulseField: .p1)

                    ReadingInputCard(readingNumber: 2,
                                     systolic: $systolic2, diastolic: $diastolic2, pulse: $pulse2,
                                     focusedField: $focusedField,
                                     systolicField: .s2, diastolicField: .d2, pulseField: .p2)

                    ReadingInputCard(readingNumber: 3,
                                     systolic: $systolic3, diastolic: $diastolic3, pulse: $pulse3,
                                     focusedField: $focusedField,
                                     systolicField: .s3, diastolicField: .d3, pulseField: .p3)

                     Spacer() // Pushes content up if scroll view has extra space
                }
                 .padding(.top) // Add padding at the top of the scroll content
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea()) // Background for the whole screen
            .navigationTitle("Add New Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveReading()
                        }
                        .disabled(!isFormValid() || isSaving)
                    }
                }

                // Focus navigation toolbar
                 ToolbarItemGroup(placement: .keyboard) {
                     // Add Next/Previous buttons for focus navigation?
                     // Example:
                     // Button("Prev") { focusPreviousField() }.disabled(!canFocusPrevious())
                     // Button("Next") { focusNextField() }.disabled(!canFocusNext())
                     Spacer()
                     Button("Done") {
                         focusedField = nil // Dismiss keyboard
                     }
                 }
            }
        }
    }

    private func isFormValid() -> Bool {
        // Keep validation: Check all 9 fields for valid integer input
        return Int(systolic1) != nil && Int(diastolic1) != nil && Int(pulse1) != nil &&
               Int(systolic2) != nil && Int(diastolic2) != nil && Int(pulse2) != nil &&
               Int(systolic3) != nil && Int(diastolic3) != nil && Int(pulse3) != nil
    }

    private func saveReading() {
         // Validate and convert (already checked by isFormValid enable state, but double-check)
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

         // Sheet dismissal handled by ContentView
         Task { @MainActor in
              try? await Task.sleep(nanoseconds: 500_000_000)
              isSaving = false
         }
    }

    // Optional: Add focusPreviousField() / focusNextField() / canFocus...() methods here
}

// Preview Provider (Optional)
struct AddReadingView_Previews: PreviewProvider {
    static var previews: some View {
        AddReadingView() { readingInput in
            print("Preview Save Tapped: \(readingInput)")
        }
    }
}
