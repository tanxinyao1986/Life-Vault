import Foundation

extension String {
    /// Localized string with optional formatting arguments.
    static func loc(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        guard !args.isEmpty else { return format }
        return String(format: format, arguments: args)
    }
}
