import Foundation

final class LocalAccountStore: ObservableObject {
    @Published var isLoggedIn: Bool {
        didSet { defaults.set(isLoggedIn, forKey: Keys.isLoggedIn) }
    }

    @Published var accountName: String {
        didSet { defaults.set(accountName, forKey: Keys.accountName) }
    }

    @Published var counter: Int {
        didSet { defaults.set(counter, forKey: Keys.counter) }
    }

    @Published var note: String {
        didSet { defaults.set(note, forKey: Keys.note) }
    }

    let installID: String
    private let defaults = UserDefaults.standard

    init() {
        let defaults = UserDefaults.standard
        self.isLoggedIn = defaults.bool(forKey: Keys.isLoggedIn)
        self.accountName = defaults.string(forKey: Keys.accountName) ?? ""
        self.counter = defaults.integer(forKey: Keys.counter)
        self.note = defaults.string(forKey: Keys.note) ?? ""

        if let existing = defaults.string(forKey: Keys.installID) {
            self.installID = existing
        } else {
            let newID = UUID().uuidString
            defaults.set(newID, forKey: Keys.installID)
            self.installID = newID
        }
    }

    func login() {
        guard !accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoggedIn = true
    }

    func logout() {
        isLoggedIn = false
    }

    func resetLocalData() {
        isLoggedIn = false
        accountName = ""
        counter = 0
        note = ""
    }

    private enum Keys {
        static let isLoggedIn = "isLoggedIn"
        static let accountName = "accountName"
        static let counter = "counter"
        static let note = "note"
        static let installID = "installID"
    }
}
