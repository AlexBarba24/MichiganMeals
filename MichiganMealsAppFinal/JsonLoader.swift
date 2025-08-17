//
//  JsonLoader.swift
//  MichiganMealsAppFinal
//
//  Created by Alex Barba on 8/6/25.
//
import Foundation

// MARK: - JSON Data Loader Extension
extension DiningDataManager {
    
    // Method to load from a JSON file in your app bundle
    func loadFromBundle(fileName: String = "dining_data") {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let path = Bundle.main.path(forResource: fileName, ofType: "json"),
                  let data = NSData(contentsOfFile: path) as Data? else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Could not find \(fileName).json in app bundle"
                    self?.isLoading = false
                }
                return
            }
            
            self?.parseJSONData(data)
        }
    }
    
    // Method to load from a network URL
    func loadFromNetwork(url: URL) {
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    self?.isLoading = false
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received from server"
                    self?.isLoading = false
                    return
                }
                
                self?.parseJSONData(data)
            }
        }.resume()
    }
    
    // Method to load from JSON string (for testing)
    func loadFromJSONString(_ jsonString: String) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let data = jsonString.data(using: .utf8) else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Invalid JSON string format"
                    self?.isLoading = false
                }
                return
            }
            
            print("JsonData: \(data)")
            self?.parseJSONData(data)
        }
    }
    
    // Common parsing method
    private func parseJSONData(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            let diningData = try decoder.decode(DiningData.self, from: data)
            
            DispatchQueue.main.async { [weak self] in
                self?.diningData = diningData
                self?.isLoading = false
                print("Successfully loaded \(diningData.diningHalls.count) dining halls")
                print("Total items: \(diningData.metadata.totalItems)")
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "JSON parsing error: \(error.localizedDescription)"
                self?.isLoading = false
                print("Parsing error: \(error)")
            }
        }
    }
    
    // Updated loadDiningData method with your actual JSON
    func loadDiningData() {
        let jsonString = """
        {
          "user": {
            "id": "user123",
            "name": "John Doe",
            "preferences": {
              "dietary_restrictions": ["vegetarian"],
              "allergens": ["nuts", "dairy"]
            }
          },
          "popular": {
            "title": "Community Favorites",
            "description": "Top rated items across all dining halls",
            "items": [
              {
                "id": "food001",
                "name": "Grilled Salmon with Herb Butter",
                "dining_hall": "North Campus Dining",
                "serving_area": "Grill Station",
                "community_rating": 4.8,
                "user_rating": 5.0,
                "total_reviews": 245,
                "image_url": "https://example.com/images/grilled_salmon.jpg",
                "dietary_info": {
                  "vegetarian": false,
                  "vegan": false,
                  "gluten_free": true,
                  "allergens": ["fish"]
                }
              },
              {
                "id": "food002", 
                "name": "Quinoa Buddha Bowl",
                "dining_hall": "West Side Eatery",
                "serving_area": "Healthy Options",
                "community_rating": 4.7,
                "user_rating": null,
                "total_reviews": 189,
                "image_url": "https://example.com/images/quinoa_bowl.jpg",
                "dietary_info": {
                  "vegetarian": true,
                  "vegan": true,
                  "gluten_free": true,
                  "allergens": []
                }
              }
            ]
          },
          "recommended": {
            "title": "Your Favorites",
            "description": "Items you've rated highly",
            "items": [
              {
                "id": "food003",
                "name": "Margherita Pizza",
                "dining_hall": "Central Food Court",
                "serving_area": "Pizza Counter",
                "community_rating": 4.2,
                "user_rating": 5.0,
                "total_reviews": 312,
                "image_url": "https://example.com/images/margherita_pizza.jpg",
                "dietary_info": {
                  "vegetarian": true,
                  "vegan": false,
                  "gluten_free": false,
                  "allergens": ["gluten", "dairy"]
                }
              }
            ]
          },
          "dining_halls": [
            {
              "id": "dh001",
              "name": "North Campus Dining",
              "location": {
                "building": "Student Union North",
                "address": "123 University Ave",
                "coordinates": {
                  "lat": 40.7128,
                  "lng": -74.0060
                }
              },
              "hours": {
                "monday": {"open": "07:00", "close": "22:00"},
                "tuesday": {"open": "07:00", "close": "22:00"},
                "wednesday": {"open": "07:00", "close": "22:00"},
                "thursday": {"open": "07:00", "close": "22:00"},
                "friday": {"open": "07:00", "close": "20:00"},
                "saturday": {"open": "10:00", "close": "20:00"},
                "sunday": {"open": "10:00", "close": "21:00"}
              },
              "current_status": "open",
              "recommended": {
                "title": "Top 10 at North Campus",
                "items": [
                  {
                    "id": "food001",
                    "name": "Grilled Salmon with Herb Butter",
                    "serving_area": "Grill Station",
                    "community_rating": 4.8,
                    "user_rating": 5.0,
                    "total_reviews": 245,
                    "image_url": "https://example.com/images/grilled_salmon.jpg",
                    "dietary_info": {
                      "vegetarian": false,
                      "vegan": false,
                      "gluten_free": true,
                      "allergens": ["fish"]
                    }
                  }
                ]
              },
              "serving_areas": [
                {
                  "id": "area001",
                  "name": "Grill Station",
                  "description": "Fresh grilled meats, fish, and vegetables",
                  "current_status": "open",
                  "items": [
                    {
                      "id": "food001",
                      "name": "Grilled Salmon with Herb Butter",
                      "community_rating": 4.8,
                      "user_rating": 5.0,
                      "total_reviews": 245,
                      "price": "$12.99",
                      "calories": "420",
                      "prep_time": "8-10 minutes",
                      "image_url": "https://example.com/images/grilled_salmon.jpg",
                      "description": "Fresh Atlantic salmon grilled to perfection with our signature herb butter blend",
                      "dietary_info": {
                        "vegetarian": false,
                        "vegan": false,
                        "gluten_free": true,
                        "allergens": ["fish"]
                      },
                      "nutritional_info": {
                        "calories": "420",
                        "protein": "35g",
                        "carbs": "2g",
                        "fat": "28g",
                        "fiber": "0g",
                        "sodium": "380mg"
                      },
                      "availability": {
                        "current": true,
                        "quantity_remaining": "high",
                        "last_served": "2024-01-15T18:45:00Z",
                        "typical_days": ["daily"]
                      }
                    },
                    {
                      "id": "food004",
                      "name": "Grilled Chicken Breast",
                      "community_rating": 4.3,
                      "user_rating": 4.0,
                      "total_reviews": 198,
                      "price": "$10.99",
                      "calories": "350",
                      "prep_time": "6-8 minutes",
                      "image_url": "https://example.com/images/grilled_chicken.jpg",
                      "description": "Tender chicken breast seasoned with Mediterranean herbs",
                      "dietary_info": {
                        "vegetarian": false,
                        "vegan": false,
                        "gluten_free": true,
                        "allergens": []
                      },
                      "nutritional_info": {
                        "calories": "350",
                        "protein": "42g",
                        "carbs": "0g",
                        "fat": "18g",
                        "fiber": "0g",
                        "sodium": "320mg"
                      },
                      "availability": {
                        "current": true,
                        "quantity_remaining": "medium",
                        "last_served": "2024-01-15T18:45:00Z",
                        "typical_days": ["daily"]
                      }
                    }
                  ]
                },
                {
                  "id": "area002",
                  "name": "Salad Bar",
                  "description": "Fresh greens, toppings, and house-made dressings",
                  "current_status": "open",
                  "items": [
                    {
                      "id": "food005",
                      "name": "Build Your Own Salad",
                      "community_rating": 4.1,
                      "user_rating": null,
                      "total_reviews": 156,
                      "price": "$8.99/lb",
                      "calories": "varies",
                      "prep_time": "2-3 minutes",
                      "image_url": "https://example.com/images/salad_bar.jpg",
                      "description": "Fresh mixed greens with unlimited toppings",
                      "dietary_info": {
                        "vegetarian": true,
                        "vegan": true,
                        "gluten_free": true,
                        "allergens": ["varies by selection"]
                      },
                      "availability": {
                        "current": true,
                        "quantity_remaining": "high",
                        "last_served": "2024-01-15T19:15:00Z",
                        "typical_days": ["daily"]
                      }
                    }
                  ]
                }
              ]
            },
            {
              "id": "dh002",
              "name": "West Side Eatery",
              "location": {
                "building": "West Campus Center",
                "address": "456 College Blvd",
                "coordinates": {
                  "lat": 40.7589,
                  "lng": -73.9851
                }
              },
              "hours": {
                "monday": {"open": "11:00", "close": "21:00"},
                "tuesday": {"open": "11:00", "close": "21:00"},
                "wednesday": {"open": "11:00", "close": "21:00"},
                "thursday": {"open": "11:00", "close": "21:00"},
                "friday": {"open": "11:00", "close": "19:00"},
                "saturday": {"closed": true},
                "sunday": {"open": "12:00", "close": "20:00"}
              },
              "current_status": "open",
              "recommended": {
                "title": "Top 10 at West Side",
                "items": [
                  {
                    "id": "food002",
                    "name": "Quinoa Buddha Bowl",
                    "serving_area": "Healthy Options",
                    "community_rating": 4.7,
                    "user_rating": null,
                    "total_reviews": 189,
                    "image_url": "https://example.com/images/quinoa_bowl.jpg",
                    "dietary_info": {
                      "vegetarian": true,
                      "vegan": true,
                      "gluten_free": true,
                      "allergens": []
                    },
                    "availability": {
                      "current": false,
                      "last_served": "2024-01-14T12:00:00Z"
                    }
                  }
                ]
              },
              "serving_areas": [
                {
                  "id": "area004",
                  "name": "Healthy Options",
                  "description": "Nutritious meals focusing on fresh, whole ingredients",
                  "current_status": "open",
                  "items": [
                    {
                      "id": "food002",
                      "name": "Quinoa Buddha Bowl",
                      "community_rating": 4.7,
                      "user_rating": null,
                      "total_reviews": 189,
                      "price": "$9.99",
                      "calories": "380",
                      "prep_time": "ready to serve",
                      "image_url": "https://example.com/images/quinoa_bowl.jpg",
                      "description": "Organic quinoa with roasted vegetables, avocado, and tahini dressing",
                      "dietary_info": {
                        "vegetarian": true,
                        "vegan": true,
                        "gluten_free": true,
                        "allergens": []
                      },
                      "nutritional_info": {
                        "calories": "380",
                        "protein": "14g",
                        "carbs": "52g",
                        "fat": "16g",
                        "fiber": "12g",
                        "sodium": "420mg"
                      },
                      "availability": {
                        "current": false,
                        "quantity_remaining": "out",
                        "last_served": "2024-01-14T12:00:00Z",
                        "typical_days": ["tuesday", "thursday"]
                      }
                    }
                  ]
                }
              ]
            }
          ],
          "metadata": {
            "last_updated": "2024-01-15T19:30:00Z",
            "version": "1.0",
            "total_items": 156,
            "total_dining_halls": 2,
            "cache_duration": 300
          }
        }
        """
        
        loadFromJSONString(jsonString)
    }
}

// MARK: - Usage Examples
/*
 
 // Example 1: Load from app bundle
 dataManager.loadFromBundle(fileName: "dining_data")
 
 // Example 2: Load from network
 if let url = URL(string: "https://your-api.com/dining-data") {
     dataManager.loadFromNetwork(url: url)
 }
 
 // Example 3: Load from JSON string (current implementation)
 dataManager.loadDiningData()
 
 */

// MARK: - Additional Helper Methods
extension DiningDataManager {
    
    // Get items filtered by dietary preferences
    func getFilteredItems(for preferences: UserPreferences) -> [MenuItem] {
        guard let diningData = diningData else { return [] }
        
        var allItems: [MenuItem] = []
        allItems.append(contentsOf: diningData.popular.items)
        allItems.append(contentsOf: diningData.recommended.items)
        
        for hall in diningData.diningHalls {
            for area in hall.servingAreas {
                allItems.append(contentsOf: area.items)
            }
        }
        
        return allItems.filter { item in
            // Check dietary restrictions
            for restriction in preferences.dietaryRestrictions {
                switch restriction.lowercased() {
                case "vegetarian":
                    if !item.dietaryInfo.vegetarian { return false }
                case "vegan":
                    if !item.dietaryInfo.vegan { return false }
                case "gluten_free", "gluten-free":
                    if !item.dietaryInfo.glutenFree { return false }
                default:
                    break
                }
            }
            
            // Check allergens
            for allergen in preferences.allergens {
                if item.dietaryInfo.allergens.contains(where: { $0.lowercased().contains(allergen.lowercased()) }) {
                    return false
                }
            }
            
            return true
        }
    }
    
    // Get currently available items only
    func getCurrentlyAvailableItems() -> [MenuItem] {
        guard let diningData = diningData else { return [] }
        
        var allItems: [MenuItem] = []
        
        for hall in diningData.diningHalls {
            guard hall.currentStatus == "open" else { continue }
            
            for area in hall.servingAreas {
                guard area.currentStatus == "open" else { continue }
                
                let availableItems = area.items.filter { item in
                    item.availability?.current ?? true
                }
                allItems.append(contentsOf: availableItems)
            }
        }
        
        return allItems
    }
    
    // Search items by name
    func searchItems(query: String) -> [MenuItem] {
        guard !query.isEmpty, let diningData = diningData else { return [] }
        
        var allItems: [MenuItem] = []
        allItems.append(contentsOf: diningData.popular.items)
        allItems.append(contentsOf: diningData.recommended.items)
        
        for hall in diningData.diningHalls {
            for area in hall.servingAreas {
                allItems.append(contentsOf: area.items)
            }
        }
        
        return allItems.filter { item in
            item.name.localizedCaseInsensitiveContains(query) ||
            item.description?.localizedCaseInsensitiveContains(query) == true ||
            item.diningHall?.localizedCaseInsensitiveContains(query) == true
        }
    }
}
