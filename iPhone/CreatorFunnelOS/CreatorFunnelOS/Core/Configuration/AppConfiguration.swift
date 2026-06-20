import Foundation

struct AppConfiguration: Sendable {
    let apiBaseURL: URL
    let callbackScheme: String
    let monthlyProductID: String
    let yearlyProductID: String
    let useMockServices: Bool

    static let current: AppConfiguration = {
        let info = Bundle.main.infoDictionary ?? [:]
        let baseURLString = info["API_BASE_URL"] as? String ?? "https://api.creatorfunnelos.com"
        let callbackScheme = info["INSTAGRAM_CALLBACK_SCHEME"] as? String ?? "creatorfunnelos"
        let monthly = info["STOREKIT_MONTHLY_PRODUCT_ID"] as? String
            ?? "com.shveatamishra.creatorfunnelos.pro.monthly"
        let yearly = info["STOREKIT_YEARLY_PRODUCT_ID"] as? String
            ?? "com.shveatamishra.creatorfunnelos.pro.yearly"
        let configuredMock = (info["USE_MOCK_SERVICES"] as? String)?
            .lowercased() == "true"

        guard let baseURL = URL(string: baseURLString) else {
            preconditionFailure("API_BASE_URL must be a valid HTTPS URL.")
        }

        return AppConfiguration(
            apiBaseURL: baseURL,
            callbackScheme: callbackScheme,
            monthlyProductID: monthly,
            yearlyProductID: yearly,
            useMockServices: configuredMock
        )
    }()

    var productIDs: Set<String> {
        [monthlyProductID, yearlyProductID]
    }
}
