//
//  ExploreView.swift
//  MichiganMealsAppFinal
//
//  Created by Alex Barba on 8/6/25.
//

import SwiftUI

struct ExploreView: View {
    @StateObject private var dataManager = DiningDataManager()
    @State private var searchText = ""
    
    var filteredDiningHalls: [String] {
        let halls = dataManager.getDiningHallNames()
        if searchText.isEmpty {
            return halls
        }
        return halls.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 16) {
                            // Delivery Info Header
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Dining now")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.michiganBlue.opacity(0.7))
                                    
                                    HStack {
                                        Text("University of Michigan")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.michiganBlue)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.michiganBlue)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Image(systemName: "bell")
                                        .font(.system(size: 20))
                                        .foregroundColor(.michiganBlue)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                                
                                TextField("Search dining halls & food", text: $searchText)
                                    .font(.system(size: 16))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                            
                            // Dining Hall Quick Navigation
                            if !dataManager.getDiningHallNames().isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 24) {
                                        ForEach(filteredDiningHalls, id: \.self) { diningHall in
                                            VStack(spacing: 8) {
                                                Text("🏛️")
                                                    .font(.system(size: 32))
                                                
                                                Text(diningHall)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.michiganBlue)
                                                    .multilineTextAlignment(.center)
                                            }
                                            .onTapGesture {
                                                withAnimation(.easeInOut(duration: 0.5)) {
                                                    proxy.scrollTo(diningHall, anchor: .top)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            // Quick Access Buttons
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    QuickAccessButton(icon: "star.fill", title: "Popular", isSelected: true)
                                    QuickAccessButton(icon: "heart", title: "Recommended", isSelected: false)
                                    QuickAccessButton(icon: "tag", title: "Offers", isSelected: false)
                                    QuickAccessButton(icon: "clock", title: "Open Now", isSelected: false)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .background(Color.backgroundColor)
                        
                        // Loading State
                        if dataManager.isLoading {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Loading dining options...")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.michiganBlue.opacity(0.7))
                            }
                            .padding(.vertical, 50)
                        }
                        
                        // Error State
                        else if let errorMessage = dataManager.errorMessage {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                
                                Text("Unable to load dining data")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.michiganBlue)
                                
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.michiganBlue.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                
                                Button("Try Again") {
                                    dataManager.loadDiningData()
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.michiganBlue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 50)
                        }
                        
                        // Content Sections
                        else if let diningData = dataManager.diningData {
                            // Popular Section
                            if !dataManager.getPopularItems().isEmpty {
                                Section {
                                    DynamicFoodItemsSection(
                                        sectionTitle: diningData.popular.title,
                                        items: dataManager.getPopularItems().map { dataManager.menuItemToFoodItem($0) }
                                    )
                                } header: {
                                    SectionHeader(title: diningData.popular.title)
                                }
                                .id("Popular")
                            }
                            
                            // Recommended Section
                            if !dataManager.getRecommendedItems().isEmpty {
                                Section {
                                    DynamicFoodItemsSection(
                                        sectionTitle: diningData.recommended.title,
                                        items: dataManager.getRecommendedItems().map { dataManager.menuItemToFoodItem($0) }
                                    )
                                } header: {
                                    SectionHeader(title: diningData.recommended.title)
                                }
                                .id("Recommended")
                            }
                            
                            // Dining Halls Sections
                            ForEach(dataManager.getDiningHalls()) { diningHall in
                                Section {
                                    DiningHallSection(diningHall: diningHall, dataManager: dataManager)
                                } header: {
                                    DiningHallHeader(diningHall: diningHall)
                                }
                                .id(diningHall.name)
                            }
                        }
                    }
                }
                .navigationBarHidden(true)
                .refreshable {
                    dataManager.loadDiningData()
                }
            }
        }
        .onAppear {
            if dataManager.diningData == nil {
                dataManager.loadDiningData()
            }
        }
    }
}

// MARK: - Updated Components

struct DynamicFoodItemsSection: View {
    let sectionTitle: String
    let items: [FoodItem]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(items, id: \.name) { item in
                    EnhancedFoodItemCard(item: item)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }
}

struct DiningHallSection: View {
    let diningHall: DiningHall
    let dataManager: DiningDataManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(dataManager.getItemsForDiningHall(diningHall.name).map { dataManager.menuItemToFoodItem($0) }, id: \.name) { item in
                    EnhancedFoodItemCard(item: item)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }
}

struct EnhancedFoodItemCard: View {
    let item: FoodItem
    
    var body: some View {
        VStack(spacing: 0) {
            // Food Image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.maizeYellow.opacity(0.2))
                .frame(width: 140, height: 100)
                .overlay(
                    Text(item.image)
                        .font(.system(size: 40))
                )
            
            // Food Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.michiganBlue)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if !item.restaurant.isEmpty {
                    Text(item.restaurant)
                        .font(.system(size: 12))
                        .foregroundColor(.michiganBlue.opacity(0.6))
                }
                
                HStack {
                    Text(item.price)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.michiganBlue)
                    
                    Spacer()
                    
                    // Rating stars (simplified)
                    HStack(spacing: 2) {
                        ForEach(0..<5) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.maizeYellow)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(width: 140)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct DiningHallHeader: View {
    let diningHall: DiningHall
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(diningHall.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.michiganBlue)
                
                HStack {
                    // Status indicator
                    Circle()
                        .fill(diningHall.currentStatus == "open" ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(diningHall.currentStatus.capitalized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.michiganBlue.opacity(0.7))
                    
                    Text("• \(diningHall.location.building)")
                        .font(.system(size: 12))
                        .foregroundColor(.michiganBlue.opacity(0.6))
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.michiganBlue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.backgroundColor)
    }
}

// Keep your existing components
struct QuickAccessButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(title)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.michiganBlue : Color.gray.opacity(0.1))
        .foregroundColor(isSelected ? .white : .michiganBlue)
        .cornerRadius(20)
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.michiganBlue)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.michiganBlue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.backgroundColor)
    }
}

//
//import SwiftUI
//
//// MARK: - Individual Views
//struct ExploreView: View {
//    @State private var searchText = ""
//    
//    let diningHalls = ["South Quad", "North Quad", "East Quad", "Markley", "Bursley"]
//    let specialSections = ["Popular", "Recommended"]
//    
//    // Sample food items for each dining hall
//    let menuItems: [String: [FoodItem]] = [
//        "Popular": [
//            FoodItem(name: "Margherita Pizza", price: "$8.99", image: "🍕", restaurant: "South Quad"),
//            FoodItem(name: "Buffalo Chicken Wrap", price: "$7.50", image: "🌯", restaurant: "North Quad"),
//            FoodItem(name: "Chicken Teriyaki Bowl", price: "$9.25", image: "🍜", restaurant: "East Quad"),
//            FoodItem(name: "Classic Burger", price: "$8.75", image: "🍔", restaurant: "Markley")
//        ],
//        "Recommended": [
//            FoodItem(name: "Caesar Salad", price: "$6.99", image: "🥗", restaurant: "South Quad"),
//            FoodItem(name: "Grilled Salmon", price: "$12.99", image: "🐟", restaurant: "North Quad"),
//            FoodItem(name: "Veggie Stir Fry", price: "$7.99", image: "🥬", restaurant: "East Quad")
//        ],
//        "South Quad": [
//            FoodItem(name: "Pepperoni Pizza", price: "$9.99", image: "🍕", restaurant: "South Quad"),
//            FoodItem(name: "Margherita Pizza", price: "$8.99", image: "🍕", restaurant: "South Quad"),
//            FoodItem(name: "BBQ Chicken Pizza", price: "$10.99", image: "🍕", restaurant: "South Quad"),
//            FoodItem(name: "Greek Salad", price: "$7.99", image: "🥗", restaurant: "South Quad")
//        ],
//        "North Quad": [
//            FoodItem(name: "Chicken Sandwich", price: "$8.99", image: "🥪", restaurant: "North Quad"),
//            FoodItem(name: "Fish Tacos", price: "$9.50", image: "🌮", restaurant: "North Quad"),
//            FoodItem(name: "Buffalo Wings", price: "$11.99", image: "🍗", restaurant: "North Quad"),
//            FoodItem(name: "Quinoa Bowl", price: "$8.25", image: "🍚", restaurant: "North Quad")
//        ],
//        "East Quad": [
//            FoodItem(name: "Pad Thai", price: "$10.99", image: "🍜", restaurant: "East Quad"),
//            FoodItem(name: "Sushi Roll", price: "$12.99", image: "🍣", restaurant: "East Quad"),
//            FoodItem(name: "Ramen Bowl", price: "$9.99", image: "🍲", restaurant: "East Quad"),
//            FoodItem(name: "Fried Rice", price: "$7.99", image: "🍚", restaurant: "East Quad")
//        ],
//        "Markley": [
//            FoodItem(name: "Double Cheeseburger", price: "$9.99", image: "🍔", restaurant: "Markley"),
//            FoodItem(name: "Chicken Tenders", price: "$8.50", image: "🍗", restaurant: "Markley"),
//            FoodItem(name: "French Fries", price: "$3.99", image: "🍟", restaurant: "Markley"),
//            FoodItem(name: "Milkshake", price: "$4.99", image: "🥤", restaurant: "Markley")
//        ],
//        "Bursley": [
//            FoodItem(name: "Grilled Chicken", price: "$10.99", image: "🍗", restaurant: "Bursley"),
//            FoodItem(name: "Vegetable Curry", price: "$8.99", image: "🍛", restaurant: "Bursley"),
//            FoodItem(name: "Mediterranean Wrap", price: "$7.99", image: "🌯", restaurant: "Bursley"),
//            FoodItem(name: "Fresh Fruit Bowl", price: "$5.99", image: "🍇", restaurant: "Bursley")
//        ]
//    ]
//    
//    var body: some View {
//        NavigationView {
//            ScrollViewReader { proxy in
//                ScrollView {
//                    LazyVStack(spacing: 0) {
//                        // Header Section
//                        VStack(spacing: 16) {
//                            // Delivery Info Header
//                            HStack {
//                                VStack(alignment: .leading, spacing: 2) {
//                                    Text("Dining now")
//                                        .font(.system(size: 15, weight: .medium))
//                                        .foregroundColor(.michiganBlue.opacity(0.7))
//                                    
//                                    HStack {
//                                        Text("University of Michigan")
//                                            .font(.system(size: 17, weight: .semibold))
//                                            .foregroundColor(.michiganBlue)
//                                        
//                                        Image(systemName: "chevron.down")
//                                            .font(.system(size: 14, weight: .medium))
//                                            .foregroundColor(.michiganBlue)
//                                    }
//                                }
//                                
//                                Spacer()
//                                
//                                Button(action: {}) {
//                                    Image(systemName: "bell")
//                                        .font(.system(size: 20))
//                                        .foregroundColor(.michiganBlue)
//                                }
//                            }
//                            .padding(.horizontal, 20)
//                            .padding(.top, 8)
//                            
//                            // Search Bar
//                            HStack {
//                                Image(systemName: "magnifyingglass")
//                                    .foregroundColor(.gray)
//                                    .font(.system(size: 16))
//                                
//                                TextField("Search dining halls & food", text: $searchText)
//                                    .font(.system(size: 16))
//                            }
//                            .padding(.horizontal, 16)
//                            .padding(.vertical, 12)
//                            .background(Color.gray.opacity(0.1))
//                            .cornerRadius(10)
//                            .padding(.horizontal, 20)
//                            
//                            // Dining Hall Quick Navigation
//                            ScrollView(.horizontal, showsIndicators: false) {
//                                HStack(spacing: 24) {
//                                    ForEach(diningHalls, id: \.self) { diningHall in
//                                        VStack(spacing: 8) {
//                                            Text("🏛️")
//                                                .font(.system(size: 32))
//                                            
//                                            Text(diningHall)
//                                                .font(.system(size: 12, weight: .medium))
//                                                .foregroundColor(.michiganBlue)
//                                                .multilineTextAlignment(.center)
//                                        }
//                                        .onTapGesture {
//                                            withAnimation(.easeInOut(duration: 0.5)) {
//                                                proxy.scrollTo(diningHall, anchor: .top)
//                                            }
//                                        }
//                                    }
//                                }
//                                .padding(.horizontal, 20)
//                            }
//                        }
//                        .background(Color.backgroundColor)
//                        
//                        // Food Sections
//                        ForEach(specialSections + diningHalls, id: \.self) { section in
//                            Section {
//                                FoodItemsSection(sectionTitle: section, items: menuItems[section] ?? [])
//                            } header: {
//                                SectionHeader(title: section)
//                            }
//                            .id(section) // Add ID for scroll targeting
//                        }
//                    }
//                }
//                .navigationBarHidden(true)
//            }
//        }
//    }
//}
//
struct FoodItem {
    let name: String
    let price: String
    let image: String
    let restaurant: String
}

struct FoodItemsSection: View {
    let sectionTitle: String
    let items: [FoodItem]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(items, id: \.name) { item in
                    FoodItemCard(item: item)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }
}

struct FoodItemCard: View {
    let item: FoodItem
    
    var body: some View {
        VStack(spacing: 0) {
            // Food Image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.maizeYellow.opacity(0.2))
                .frame(width: 140, height: 100)
                .overlay(
                    Text(item.image)
                        .font(.system(size: 40))
                )
            
            // Food Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.michiganBlue)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if item.restaurant != "" {
                    Text(item.restaurant)
                        .font(.system(size: 12))
                        .foregroundColor(.michiganBlue.opacity(0.6))
                }
                
                Text(item.price)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.michiganBlue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(width: 140)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

//struct QuickAccessButton: View {
//    let icon: String
//    let title: String
//    let isSelected: Bool
//    
//    var body: some View {
//        HStack(spacing: 6) {
//            Image(systemName: icon)
//                .font(.system(size: 14))
//            Text(title)
//                .font(.system(size: 14, weight: .medium))
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 8)
//        .background(isSelected ? Color.michiganBlue : Color.gray.opacity(0.1))
//        .foregroundColor(isSelected ? .white : .michiganBlue)
//        .cornerRadius(20)
//    }
//}
//
//struct SectionHeader: View {
//    let title: String
//    
//    var body: some View {
//        HStack {
//            Text(title)
//                .font(.system(size: 22, weight: .bold))
//                .foregroundColor(.michiganBlue)
//            
//            Spacer()
//            
//            Button(action: {}) {
//                Image(systemName: "arrow.right")
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(.michiganBlue)
//            }
//        }
//        .padding(.horizontal, 20)
//        .padding(.vertical, 16)
//        .background(Color.backgroundColor)
//    }
//}




#Preview {
    ExploreView()
}
