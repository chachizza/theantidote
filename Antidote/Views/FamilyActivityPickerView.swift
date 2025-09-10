import SwiftUI
import FamilyControls

struct FamilyActivityPickerView: View {
    @State private var selection = FamilyActivitySelection()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Instructions
                VStack(spacing: 8) {
                    Text("📱 Select Individual Apps")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text("Choose specific apps like Instagram, TikTok, etc. Avoid selecting entire categories for better control.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
                FamilyActivityPicker(selection: $selection)
                    .padding()
                
                Spacer()
                
                Button("Save Selection") {
                    if selection.categoryTokens.count > 0 {
                        // Create a new selection with only apps (no categories)
                        var appsOnlySelection = FamilyActivitySelection()
                        appsOnlySelection.applicationTokens = selection.applicationTokens
                        appsOnlySelection.webDomainTokens = selection.webDomainTokens
                        // Deliberately exclude categoryTokens
                        
                        var settings = AppSettings.load()
                        settings.selectedApps = appsOnlySelection
                        settings.save()
                        print("💾 Saved \(appsOnlySelection.applicationTokens.count) apps (excluded \(selection.categoryTokens.count) categories for better control)")
                    } else {
                        var settings = AppSettings.load()
                        settings.selectedApps = selection
                        settings.save()
                        print("💾 Family Activity selection saved: \(selection.applicationTokens.count) apps")
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Select Apps")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Load current selection when picker appears
            let settings = AppSettings.load()
            selection = settings.selectedApps
            print("🎯 Family Activity Picker loaded with \(selection.applicationTokens.count) apps, \(selection.categoryTokens.count) categories")
        }
    }
}

struct FamilyActivityPickerView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyActivityPickerView()
    }
}