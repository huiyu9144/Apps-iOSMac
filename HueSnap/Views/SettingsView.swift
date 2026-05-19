import SwiftUI

struct SettingsView: View {
    @State var viewModel: HueSnapViewModel
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    private let sectionCornerRadius: CGFloat = 12

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            ScrollView {
                VStack(spacing: 16) {
                    languageCard
                    aboutCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .frame(width: 400, height: 220)
        .background(Color(.controlBackgroundColor))
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            Text(locStr("设置"))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
            Text("HueSnap")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var languageCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 24)

                Text(locStr("语言"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Picker("", selection: $appLanguage) {
                    ForEach(Language.allCases, id: \.rawValue) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 130)
                .onChange(of: appLanguage) { _, _ in
                    notifyLanguageChange()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous)
                .stroke(Color(.separatorColor).opacity(0.2), lineWidth: 0.5)
        )
    }

    private var aboutCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "eyedropper")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.accentColor)
                    .frame(width: 24)

                Text("HueSnap")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Text(locStr("版本") + " 1.0")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()
                .padding(.leading, 50)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.red)
                        .frame(width: 24)

                    Text(locStr("退出应用"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.red)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous)
                .stroke(Color(.separatorColor).opacity(0.2), lineWidth: 0.5)
        )
    }

    private func notifyLanguageChange() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.rebuildPopoverContent()
        }
        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
    }
}
