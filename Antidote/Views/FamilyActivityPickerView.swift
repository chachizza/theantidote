import SwiftUI
import FamilyControls

struct FamilyActivityPickerView: View {
    @State private var selection = FamilyActivitySelection()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                FamilyActivityPicker(selection: $selection)
                    .padding()
                
                Spacer()
                
                Button("Save Selection") {
                    StorageManager.shared.saveFamilyActivitySelection(selection)
                    var settings = AppSettings.load()
                    settings.selectedApps = selection
                    settings.save()
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
    }
}

struct FamilyActivityPickerView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyActivityPickerView()
    }
}