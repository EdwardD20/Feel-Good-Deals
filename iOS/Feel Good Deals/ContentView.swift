import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    
    // Editable search / UPC field, shows the actual UPC code
    @State private var scannedUPC: String = "No UPC set"
    
    // Product information from API
    @State private var productOffers: [UPCOffer] = []
    
    // Loading state for API call
    @State private var isLoadingProduct = false
    @State private var lookupError: String?
    
    @State private var isShowingScanner = false
    @State private var activeURL: URL? = nil
    
    // Single Costco retailer
    private let costcoRetailer = Retailer(
        name: "Costco",
        urlTemplate: "https://www.costco.com/CatalogSearch?dept=All&keyword=<UPC>",
        logoAssetName: "CostcoLogo"
    )
    
    // Whether there is something meaningful to search
    private var hasValidSearch: Bool {
        let trimmed = scannedUPC.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != "No UPC set"
    } // var hasValidSearch
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                
                // Logo
                Image("FeelGoodDealsLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .padding(.top, 0)
                    .padding(.bottom, 4)
                
                // UPC field (shows the scanned UPC code)
                HStack {
                    TextField("No UPC set", text: $scannedUPC)
                        .keyboardType(.numberPad)
                        .textContentType(.none)
                        .disableAutocorrection(true)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Show loading indicator when fetching
                    if isLoadingProduct {
                        ProgressView()
                            .padding(.trailing, 8)
                    } // if isLoadingProduct
                } // HStack
                
                // Error message if lookup failed
                if let error = lookupError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                } // if let error
                
                // UPC scan button
                HStack(spacing: 12) {
                    Button {
                        isShowingScanner = true
                    } label: {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                            Text("Scan UPC")
                                .fontWeight(.semibold)
                        } // HStack
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } // label
                    .buttonStyle(.plain)
                } // HStack
                
                // Offers Table - BETWEEN Scan UPC button and Costco button
                if !productOffers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Offers (\(productOffers.count))")
                            .font(.headline)
                            .padding(.top, 8)
                            .onAppear {
                                #if DEBUG
                                print("🎨 Table is rendering with \(productOffers.count) offers")
                                #endif
                            } // onAppear
                        
                        // Table Header
                        HStack {
                            Text("Merchant")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Price")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 80, alignment: .trailing)
                        } // HStack
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // Table Rows - now scrollable
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(productOffers, id: \.link) { offer in
                                    Button {
                                        if let url = URL(string: offer.link) {
                                            activeURL = url
                                        } // if let url
                                    } label: {
                                        HStack {
                                            Text(offer.merchant)
                                                .font(.body)
                                                .foregroundColor(.blue)
                                                .underline()
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            if let priceFormatted = offer.price.formattedUSD {
                                                Text(priceFormatted)
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                    .frame(width: 80, alignment: .trailing)
                                            } else {
                                                Text("N/A")
                                                    .font(.body)
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 80, alignment: .trailing)
                                            } // if let priceFormatted
                                        } // HStack
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } // label
                                    .buttonStyle(.plain)
                                } // ForEach
                            } // VStack
                            .padding(.vertical, 4)
                        } // ScrollView
                        .frame(maxHeight: 300)  // Limit height to make it scrollable
                    } // VStack
                    .padding(.vertical, 8)
                } else {
                    #if DEBUG
                    let _ = print("❌ Table NOT rendering - productOffers.isEmpty = \(productOffers.isEmpty), count = \(productOffers.count)")
                    #endif
                } // if !productOffers.isEmpty
                
                Divider()
                
                // Costco button (only retailer)
                Button {
                    guard let url = costcoRetailer.url(for: scannedUPC) else {
                        return
                    } // guard let url
                    activeURL = url
                } label: {
                    HStack(spacing: 12) {
                        Image(costcoRetailer.logoAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                        
                        Text(costcoRetailer.name)
                            .font(.body)
                        
                        Spacer()
                        
                        Image(systemName: "safari")
                    } // HStack
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } // label
                .buttonStyle(.plain)
                .disabled(!hasValidSearch)
                
                Spacer(minLength: 0)
            } // VStack
            .padding(.horizontal)
        } // NavigationView
        .navigationViewStyle(StackNavigationViewStyle())
        
        // Barcode scanner sheet
        .sheet(isPresented: $isShowingScanner) {
            BarcodeScannerView { result in
                isShowingScanner = false
                if let code = result {
                    // Update the UPC field with the scanned code
                    scannedUPC = code
                    // Then look up the product info via API
                    Task {
                        await lookupProduct(upc: code)
                    } // Task
                } // if let code
            } // BarcodeScannerView
        } // .sheet(isPresented: $isShowingScanner)
        
        // Web view sheet
        .sheet(isPresented: Binding(
            get: { activeURL != nil },
            set: { newValue in
                if !newValue {
                    activeURL = nil
                } // if !newValue
            } // set
        )) {
            if let url = activeURL {
                SafariView(url: url)
            } // if let url
        } // .sheet(isPresented: Binding)
    } // var body
    
    // MARK: - API Lookup
    
    /// Looks up the product info via UPCitemdb API and updates product details
    private func lookupProduct(upc: String) async {
        isLoadingProduct = true
        lookupError = nil
        productOffers = []
        
        do {
            let (data, response) = try await fetchProductData(upc: upc)
            
            // Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UPCLookupError.invalidResponse
            } // guard let httpResponse
            
            guard httpResponse.statusCode == 200 else {
                throw UPCLookupError.httpError(statusCode: httpResponse.statusCode)
            } // guard httpResponse.statusCode == 200
            
            // Decode the response
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(UPCItemDBResponse.self, from: data)
            
            #if DEBUG
            print("📦 API Response decoded successfully")
            print("   Total items: \(apiResponse.items.count)")
            #endif
            
            // Check if we got results
            guard let item = apiResponse.items.first else {
                throw UPCLookupError.noResults
            } // guard let item
            
            #if DEBUG
            print("   Product: \(item.title)")
            print("   Brand: \(item.brand ?? "N/A")")
            print("   Offers count: \(item.offers?.count ?? 0)")
            print("   Category: \(item.category ?? "<no category>")")
            if let offers = item.offers {
                for (index, offer) in offers.enumerated() {
                    print("   Offer \(index + 1): \(offer.merchant) - \(offer.currency) - Price: \(offer.price.value ?? 0)")
                } // for offer
            } // if let offers
            #endif
            
            // Update UI on main thread
            await MainActor.run {
                // Store offers (accept USD or empty/missing currency for US products)
                if let offers = item.offers {
                    let filteredOffers = offers.filter { offer in
                        // Accept if currency is "USD" OR if currency is empty/missing (default to USD)
                        return offer.currency.uppercased() == "USD" || offer.currency.isEmpty
                    } // offers.filter
                    
                    // Sort by price (low to high), placing offers without prices at the end
                    productOffers = filteredOffers.sorted { offer1, offer2 in
                        guard let price1 = offer1.price.value else { return false }
                        guard let price2 = offer2.price.value else { return true }
                        return price1 < price2
                    } // filteredOffers.sorted
                    
                    #if DEBUG
                    print("🎯 Filtered and sorted USD/empty currency offers: \(productOffers.count)")
                    print("🎯 productOffers array populated with \(productOffers.count) items")
                    for (index, offer) in productOffers.enumerated() {
                        print("   Filtered Offer \(index + 1): \(offer.merchant) - '\(offer.currency)' - \(offer.price.value ?? 0)")
                    } // for offer
                    #endif
                } else {
                    #if DEBUG
                    print("⚠️ No offers in item")
                    #endif
                } // if let offers
                
                isLoadingProduct = false
            } // MainActor.run
            
            #if DEBUG
            print("✅ Product lookup completed")
            print("💰 Total offers stored: \(productOffers.count)")
            #endif
            
        } catch {
            // Handle error
            await MainActor.run {
                lookupError = error.localizedDescription
                isLoadingProduct = false
            } // MainActor.run
            
            #if DEBUG
            print("❌ UPC Lookup Error: \(error)")
            #endif
        } // do-catch
    } // func lookupProduct
    
    /// Fetches product data from UPCitemdb API
    private func fetchProductData(upc: String) async throws -> (Data, URLResponse) {
        let cleanedUPC = upc.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedUPC.isEmpty else {
            throw UPCLookupError.invalidUPC
        } // guard !cleanedUPC.isEmpty
        
        guard let url = URL(string: "https://api.upcitemdb.com/prod/trial/lookup?upc=\(cleanedUPC)") else {
            throw UPCLookupError.invalidURL
        } // guard let url
        
        #if DEBUG
        print("🔍 UPC Lookup URL → \(url.absoluteString)")
        #endif
        
        return try await URLSession.shared.data(from: url)
    } // func fetchProductData
} // struct ContentView

// MARK: - Retailer Model (kept for Costco)

struct Retailer: Identifiable {
    let id = UUID()
    let name: String
    let urlTemplate: String
    let logoAssetName: String
    
    func url(for rawQuery: String) -> URL? {
        // Treat the special default text as "no value"
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "No UPC set" {
            return nil
        } // if trimmed == "No UPC set"
        guard !trimmed.isEmpty else { return nil }
        
        // Encode for URL, ensuring spaces become %20
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        let spaceFixed = encoded.replacingOccurrences(of: "+", with: "%20")
        
        let urlString = urlTemplate.replacingOccurrences(of: "<UPC>", with: spaceFixed)
        
        #if DEBUG
        print("🔗 Retailer Lookup URL → \(urlString)")
        #endif
        
        return URL(string: urlString)
    } // func url
} // struct Retailer

#if DEBUG
#Preview { ContentView() }
#endif
