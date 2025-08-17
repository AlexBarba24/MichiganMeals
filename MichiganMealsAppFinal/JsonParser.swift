//
//  JsonParser.swift
//  MichiganMealsAppFinal
//
//  Created by Alex Barba on 8/6/25.
//
import Foundation

// MARK: - Root Data Model
struct DiningData: Codable {
    let user: User
    let popular: PopularSection
    let recommended: RecommendedSection
    let diningHalls: [DiningHall]
    let metadata: Metadata
    
    enum CodingKeys: String, CodingKey {
        case user, popular, recommended, metadata
        case diningHalls = "dining_halls"
    }
}

// MARK: - User Model
struct User: Codable {
    let id: String
    let name: String
    let preferences: UserPreferences
}

struct UserPreferences: Codable {
    let dietaryRestrictions: [String]
    let allergens: [String]
    
    enum CodingKeys: String, CodingKey {
        case dietaryRestrictions = "dietary_restrictions"
        case allergens
    }
}

// MARK: - Section Models
struct PopularSection: Codable {
    let title: String
    let description: String?
    let items: [MenuItem]
}

struct RecommendedSection: Codable {
    let title: String
    let description: String?
    let items: [MenuItem]
}

// MARK: - Dining Hall Model
struct DiningHall: Codable, Identifiable {
    let id: String
    let name: String
    let location: Location
    let hours: Hours
    let currentStatus: String
    let recommended: RecommendedSection
    let servingAreas: [ServingArea]
    
    enum CodingKeys: String, CodingKey {
        case id, name, location, hours, recommended
        case currentStatus = "current_status"
        case servingAreas = "serving_areas"
    }
}

struct Location: Codable {
    let building: String
    let address: String
    let coordinates: Coordinates
}

struct Coordinates: Codable {
    let lat: Double
    let lng: Double
}

struct Hours: Codable {
    let monday: DayHours?
    let tuesday: DayHours?
    let wednesday: DayHours?
    let thursday: DayHours?
    let friday: DayHours?
    let saturday: DayHours?
    let sunday: DayHours?
}

struct DayHours: Codable {
    let open: String?
    let close: String?
    let closed: Bool?
}

// MARK: - Serving Area Model
struct ServingArea: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let currentStatus: String
    let currentTheme: String?
    let items: [MenuItem]
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, items
        case currentStatus = "current_status"
        case currentTheme = "current_theme"
    }
}

// MARK: - Menu Item Model
struct MenuItem: Codable, Identifiable {
    let id: String
    let name: String
    let diningHall: String?
    let servingArea: String?
    let communityRating: Double
    let userRating: Double?
    let totalReviews: Int
    let price: String?
    let calories: String?
    let prepTime: String?
    let imageUrl: String?
    let description: String?
    let dietaryInfo: DietaryInfo
    let nutritionalInfo: NutritionalInfo?
    let availability: Availability?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, price, calories
        case diningHall = "dining_hall"
        case servingArea = "serving_area"
        case communityRating = "community_rating"
        case userRating = "user_rating"
        case totalReviews = "total_reviews"
        case prepTime = "prep_time"
        case imageUrl = "image_url"
        case dietaryInfo = "dietary_info"
        case nutritionalInfo = "nutritional_info"
        case availability
    }
}

struct DietaryInfo: Codable {
    let vegetarian: Bool
    let vegan: Bool
    let glutenFree: Bool
    let allergens: [String]
    
    enum CodingKeys: String, CodingKey {
        case vegetarian, vegan, allergens
        case glutenFree = "gluten_free"
    }
}

struct NutritionalInfo: Codable {
    let calories: String?
    let protein: String?
    let carbs: String?
    let fat: String?
    let fiber: String?
    let sodium: String?
}

struct Availability: Codable {
    let current: Bool
    let quantityRemaining: String?
    let lastServed: String?
    let typicalDays: [String]?
    
    enum CodingKeys: String, CodingKey {
        case current
        case quantityRemaining = "quantity_remaining"
        case lastServed = "last_served"
        case typicalDays = "typical_days"
    }
}

// MARK: - Metadata Model
struct Metadata: Codable {
    let lastUpdated: String
    let version: String
    let totalItems: Int
    let totalDiningHalls: Int
    let cacheDuration: Int
    
    enum CodingKeys: String, CodingKey {
        case version
        case lastUpdated = "last_updated"
        case totalItems = "total_items"
        case totalDiningHalls = "total_dining_halls"
        case cacheDuration = "cache_duration"
    }
}

// MARK: - Data Manager
class DiningDataManager: ObservableObject {
    @Published var diningData: DiningData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func tloadDiningData() {
        isLoading = true
        errorMessage = nil
        
        // In a real app, this would be a network call
        // For now, we'll simulate loading from a local JSON file or string
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                // Replace this with your actual data loading logic
                let jsonData = self?.getSampleJSONData() ?? Data()
                let decoder = JSONDecoder()
                let diningData = try decoder.decode(DiningData.self, from: jsonData)
                
                DispatchQueue.main.async {
                    self?.diningData = diningData
                    self?.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to load dining data: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            }
        }
    }
    
    // Helper method to get sample JSON data
    private func getSampleJSONData() -> Data {
        // In a real implementation, you would either:
        // 1. Load from a bundled JSON file
        // 2. Make a network request
        // 3. Load from Core Data or another local storage
        
        // For now, return the JSON string as Data
        let jsonString = """
        // Your JSON data would go here - paste the entire JSON from your document
        """
        
        return jsonString.data(using: .utf8) ?? Data()
    }
    
    // Helper methods to organize data for the UI
    func getPopularItems() -> [MenuItem] {
        return diningData?.popular.items ?? []
    }
    
    func getRecommendedItems() -> [MenuItem] {
        return diningData?.recommended.items ?? []
    }
    
    func getDiningHalls() -> [DiningHall] {
        return diningData?.diningHalls ?? []
    }
    
    func getItemsForDiningHall(_ diningHallName: String) -> [MenuItem] {
        guard let diningHalls = diningData?.diningHalls else { return [] }
        
        for hall in diningHalls {
            if hall.name == diningHallName {
                var allItems: [MenuItem] = []
                for area in hall.servingAreas {
                    allItems.append(contentsOf: area.items)
                }
                return allItems
            }
        }
        return []
    }
    
    func getDiningHallNames() -> [String] {
        return getDiningHalls().map { $0.name }
    }
    
    // Convert MenuItem to your existing FoodItem for compatibility
    func menuItemToFoodItem(_ menuItem: MenuItem) -> FoodItem {
        return FoodItem(
            name: menuItem.name,
            price: menuItem.price ?? "$0.00",
            image: getEmojiForMenuItem(menuItem),
            restaurant: menuItem.diningHall ?? menuItem.servingArea ?? ""
        )
    }
    
    private func getEmojiForMenuItem(_ item: MenuItem) -> String {
        // Simple logic to assign emojis based on food name
        let name = item.name.lowercased()
        
        if name.contains("pizza") { return "🍕" }
        if name.contains("burger") { return "🍔" }
        if name.contains("salad") { return "🥗" }
        if name.contains("chicken") { return "🍗" }
        if name.contains("salmon") || name.contains("fish") { return "🐟" }
        if name.contains("bowl") || name.contains("quinoa") { return "🍜" }
        if name.contains("wrap") { return "🌯" }
        if name.contains("taco") { return "🌮" }
        if name.contains("sandwich") { return "🥪" }
        if name.contains("pasta") || name.contains("parmigiana") { return "🍝" }
        if name.contains("rice") { return "🍚" }
        if name.contains("curry") { return "🍛" }
        if name.contains("fruit") { return "🍇" }
        
        return "🍽️" // Default food emoji
    }
    
    // Helper method to get a default image URL if none provided
    private func getDefaultImageUrl() -> String {
        return "https://via.placeholder.com/200x200/FFCB05/00274C?text=Food"
    }
}
