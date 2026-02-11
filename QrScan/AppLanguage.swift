import Foundation

enum AppLanguage: Equatable {
    case en
    case zhHans

    static func resolve(regionCode: String?) -> AppLanguage {
        guard let regionCode = regionCode?.uppercased() else {
            return .en
        }
        return regionCode == "CN" ? .zhHans : .en
    }

    static func current(locale: Locale = .current) -> AppLanguage {
        if #available(iOS 16.0, *) {
            return resolve(regionCode: locale.region?.identifier)
        } else {
            return resolve(regionCode: locale.regionCode)
        }
    }

    var locale: Locale {
        switch self {
        case .en:
            return Locale(identifier: "en")
        case .zhHans:
            return Locale(identifier: "zh-Hans")
        }
    }

    var lprojName: String {
        switch self {
        case .en:
            return "en"
        case .zhHans:
            return "zh-Hans"
        }
    }

    var bundle: Bundle {
        guard
            let path = Bundle.main.path(forResource: lprojName, ofType: "lproj"),
            let localizedBundle = Bundle(path: path)
        else {
            return .main
        }
        return localizedBundle
    }
}

enum L10n {
    static func tr(_ key: String, language: AppLanguage) -> String {
        NSLocalizedString(
            key,
            tableName: "Localizable",
            bundle: language.bundle,
            value: key,
            comment: ""
        )
    }
}
