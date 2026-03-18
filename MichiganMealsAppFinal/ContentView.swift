//
//  ContentView.swift
//  MichiganMealsAppFinal
//
//  Created by Alex Barba on 8/6/25.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
            
            MealView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Meal")
                }
            
            MakeView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Make")
                }
            
            AccountView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Account")
                }
        }
        .accentColor(Color.maizeYellow)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.michiganBlue)
            
            // Unselected tab item color
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.maizeYellow.opacity(0.6))
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Color.maizeYellow.opacity(0.6))
            ]
            
            // Selected tab item color
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.maizeYellow)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color.maizeYellow)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}


struct MealView: View {
    @StateObject private var dataManager = DiningDataManager()
    @State private var mDiningHall: DiningHall? = nil
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundColor.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Meal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.michiganBlue)
                    if(mDiningHall == nil){
                        Text("Plan and track your meals")
                            .font(.body)
                            .foregroundColor(.michiganBlue.opacity(0.7))
                            .multilineTextAlignment(.center)
                        Text("Select a Dining Hall")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.michiganBlue)
                        if !dataManager.getRecommendedItems().isEmpty {
                            ForEach(dataManager.getDiningHalls()) { diningHall in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.maizeYellow.opacity(0.2))
                                    .frame(height: 60)
                                    .overlay(
                                        Text(diningHall.name)
                                            .foregroundColor(.michiganBlue)
                                            .font(.headline)
                                            .multilineTextAlignment(.center)
                                    )
                                    .onTapGesture {
                                        mDiningHall = diningHall
                                    }
                            }
                        }
                    }else {
                        Text("Dining Hall : \(mDiningHall!.name)")
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.2))
                            .frame(height: 60)
                            .overlay(
                                Text("Back")
                                    .foregroundColor(.michiganBlue)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                            )
                            .onTapGesture {
                                mDiningHall = nil
                            }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .onAppear{
                dataManager.loadDiningData()
            }
        }
    }
}

struct MakeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Make")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.michiganBlue)
                    
                    Text("Create and build something new")
                        .font(.body)
                        .foregroundColor(.michiganBlue.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    // Placeholder content
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.maizeYellow.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            Text("Make content will go here based on your screenshots")
                                .foregroundColor(.michiganBlue)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        )
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

struct AccountView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.michiganBlue)
                    
                    Text("Manage your profile and settings")
                        .font(.body)
                        .foregroundColor(.michiganBlue.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    // Placeholder content
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.maizeYellow.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            Text("Account content will go here based on your screenshots")
                                .foregroundColor(.michiganBlue)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        )
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static let maizeYellow = Color(hex: "#FFCB05")
    static let michiganBlue = Color(hex: "#00274C")
    static let backgroundColor = Color(UIColor.systemBackground)
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
