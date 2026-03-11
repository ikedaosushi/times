import SwiftUI
import SwiftData

@main
struct timesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Channel.self, Post.self, Tag.self, EventTag.self, UserSettings.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    warmUpKeyboard()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    /// キーボードプロセスを事前ロードして初回表示の遅延を解消する
    private func warmUpKeyboard() {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first

        let field = UITextField(frame: .zero)
        window?.addSubview(field)
        field.becomeFirstResponder()
        field.resignFirstResponder()
        field.removeFromSuperview()
    }
}
