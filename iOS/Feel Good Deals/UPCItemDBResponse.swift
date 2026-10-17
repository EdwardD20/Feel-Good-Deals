import Foundation

// MARK: - API Response Models

struct UPCItemDBResponse: Codable {
    let code: String
    let total: Int
    let items: [UPCItem]
} // struct UPCItemDBResponse

struct UPCItem: Codable {
    let ean: String
    let title: String
    let description: String?
    let brand: String?
    let category: String?
    let images: [String]?
    let offers: [UPCOffer]?
    let lowestRecordedPrice: FlexiblePrice?
    let highestRecordedPrice: FlexiblePrice?
    
    enum CodingKeys: String, CodingKey {
        case ean, title, description, brand, category, images, offers
        case lowestRecordedPrice = "lowest_recorded_price"
        case highestRecordedPrice = "highest_recorded_price"
    } // enum CodingKeys
} // struct UPCItem

struct UPCOffer: Codable {
    let merchant: String
    let domain: String
    let price: FlexiblePrice  // Can be number or empty string
    let currency: String
    let link: String
} // struct UPCOffer

// MARK: - FlexiblePrice: Handles both Double and String (empty or numeric)

struct FlexiblePrice: Codable {
    let value: Double?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as Double first
        if let doubleValue = try? container.decode(Double.self) {
            self.value = doubleValue
        }
        // Try to decode as String
        else if let stringValue = try? container.decode(String.self) {
            // If it's an empty string, set value to nil
            if stringValue.isEmpty {
                self.value = nil
            }
            // Try to parse string as Double (e.g., "1.09")
            else if let doubleValue = Double(stringValue) {
                self.value = doubleValue
            } else {
                self.value = nil
            } // if stringValue.isEmpty
        }
        // If neither works, set to nil
        else {
            self.value = nil
        } // if let doubleValue
    } // init(from decoder: Decoder)
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = value {
            try container.encode(value)
        } else {
            try container.encode("")
        } // if let value
    } // func encode
    
    // Convenience property to get formatted string
    var formattedUSD: String? {
        guard let value = value else { return nil }
        return String(format: "$%.2f", value)
    } // var formattedUSD
} // struct FlexiblePrice

// MARK: - UPC Lookup Service

class UPCLookupService {
    
    static let shared = UPCLookupService()
    
    private init() {}
    
    /// Looks up a UPC code and returns a formatted string with brand and product title
    /// - Parameter upc: The UPC code to lookup
    /// - Returns: Formatted string: "Brand - Product Title" or just "Product Title"
    func lookupUPC(_ upc: String) async throws -> String {
        // Clean the UPC string
        let cleanedUPC = upc.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedUPC.isEmpty else {
            throw UPCLookupError.invalidUPC
        } // guard !cleanedUPC.isEmpty
        
        // Build the API URL
        guard let url = URL(string: "https://api.upcitemdb.com/prod/trial/lookup?upc=\(cleanedUPC)") else {
            throw UPCLookupError.invalidURL
        } // guard let url
        
        #if DEBUG
        print("🔍 UPC Lookup URL → \(url.absoluteString)")
        #endif
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UPCLookupError.invalidResponse
        } // guard let httpResponse
        
        #if DEBUG
        print("📡 Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Response Data: \(responseString)")
        } // if let responseString
        #endif
        
        guard httpResponse.statusCode == 200 else {
            throw UPCLookupError.httpError(statusCode: httpResponse.statusCode)
        } // guard httpResponse.statusCode == 200
        
        // Decode the response
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(UPCItemDBResponse.self, from: data)
        
        // Check if we got results
        guard let item = apiResponse.items.first else {
            throw UPCLookupError.noResults
        } // guard let item
        
        // Format the result: "Brand - Product Title"
        let formattedString: String
        if let brand = item.brand, !brand.isEmpty {
            formattedString = "\(brand) - \(item.title)"
        } else {
            formattedString = item.title
        } // if let brand
        
        #if DEBUG
        print("✅ Found: \(formattedString)")
        print("✅ Brand: \(item.brand ?? "<no brand>")")
        print("✅ Title: \(item.title)")
        print("✅ Category: \(item.category ?? "<no category>")")

        // Log price information
        if let lowestPrice = item.lowestRecordedPrice?.formattedUSD {
            print("💰 Lowest Price: \(lowestPrice)")
        } // if let lowestPrice
        
        if let highestPrice = item.highestRecordedPrice?.formattedUSD {
            print("💰 Highest Price: \(highestPrice)")
        } // if let highestPrice
        
        // Log US retailers and prices in USD
        if let offers = item.offers {
            let usOffers = offers.filter { $0.currency == "USD" && $0.price.value != nil }
            print("💰 US Offers (\(usOffers.count) found):")
            for offer in usOffers {
                if let priceFormatted = offer.price.formattedUSD {
                    print("   - \(offer.merchant): \(priceFormatted)")
                } // if let priceFormatted
            } // for offer
        } // if let offers
        #endif
        
        return formattedString
    } // func lookupUPC
} // class UPCLookupService

// MARK: - Error Types

enum UPCLookupError: LocalizedError {
    case invalidUPC
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidUPC:
            return "Invalid UPC code"
        case .invalidURL:
            return "Failed to create API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "Server error (Status: \(statusCode))"
        case .noResults:
            return "No product found for this UPC"
        } // switch self
    } // var errorDescription
} // enum UPCLookupError
