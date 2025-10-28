import SwiftUI
import FamilyControls
import ManagedSettings

struct FamilyActivityPickerView: View {
    @State private var selection = FamilyActivitySelection()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            RetroTheme.Palette.background
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    pickerPanel
                    actionBar
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            let settings = AppSettings.load()
            selection = settings.selectedApps
            print("🎯 Family Activity Picker loaded with \(selection.applicationTokens.count) apps, \(selection.categoryTokens.count) categories")
        }
    }
    
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Abort")
                    .font(RetroTheme.Typography.body(14))
                    .foregroundColor(RetroTheme.Palette.warning)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .stroke(RetroTheme.Palette.panelBorder, lineWidth: 1.5)
                    )
            }
            Spacer()
            Text("APP LOCK MATRIX")
                .font(RetroTheme.Typography.title(16))
                .foregroundColor(RetroTheme.Palette.text)
        }
    }
    
    private var pickerPanel: some View {
        RetroPanel(title: nil) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(RetroTheme.Palette.panelBorder, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(RetroTheme.Palette.background.opacity(0.4))
                    )
                
                FamilyActivityPicker(selection: $selection)
                    .tint(RetroTheme.Palette.primaryAccent)
                    .labelsHidden()
            }
            .frame(minHeight: 360)
        }
    }
    
    private var actionBar: some View {
        VStack(spacing: 16) {
            Button {
                saveSelection()
            } label: {
                Text("LOCK THESE APPS")
            }
            .buttonStyle(RetroButtonStyle(kind: .primary))
        }
    }
    
    private func saveSelection() {
        var finalSelection: FamilyActivitySelection
        if selection.categoryTokens.count > 0 {
            var appsOnlySelection = FamilyActivitySelection()
            appsOnlySelection.applicationTokens = selection.applicationTokens
            appsOnlySelection.webDomainTokens = selection.webDomainTokens
            finalSelection = appsOnlySelection
            print("💾 Saved \(appsOnlySelection.applicationTokens.count) apps (excluded \(selection.categoryTokens.count) categories for better control)")
        } else {
            finalSelection = selection
            print("💾 Family Activity selection saved: \(selection.applicationTokens.count) apps")
        }
        
        print("🔍 Saving selection with \(finalSelection.applicationTokens.count) app tokens, \(finalSelection.categoryTokens.count) categories, \(finalSelection.webDomainTokens.count) domains")
        finalSelection.applicationTokens.forEach { token in
            let app = ManagedSettings.Application(token: token)
            print("   • App token: \(AppSettings.debugDescription(for: token))")
            print("     ↳ bundle: \(app.bundleIdentifier ?? "nil"), name: \(app.localizedDisplayName ?? "nil")")
        }
        finalSelection.categoryTokens.forEach { token in
            print("   • Category token: \(AppSettings.debugDescription(for: token))")
        }
        finalSelection.webDomainTokens.forEach { token in
            print("   • Domain token: \(AppSettings.debugDescription(for: token))")
        }
        
        var settings = AppSettings.load()
        settings.selectedApps = finalSelection
        settings.save()
        selection = finalSelection
        dismiss()
    }
}
