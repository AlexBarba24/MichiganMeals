//
//  StartupView.swift
//  MichiganMealsAppFinal
//
//  Created by ChatGPT on 2024-08-31.
//

import SwiftUI
import CryptoKit

struct StartupView: View {
    @AppStorage("authToken") private var authToken: String?
    @State private var username: String = ""
    @State private var password: String = ""

    var body: some View {
        if authToken != nil {
            // Token exists – user is considered logged in
            ContentView()
        } else {
            // No token – prompt user to create account
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.michiganBlue)

                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: register) {
                    Text("Sign Up")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.maizeYellow)
                        .foregroundColor(.michiganBlue)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    private func register() {
        guard !username.isEmpty, !password.isEmpty else { return }
        let token = generateToken(username: username, password: password)
        // In a real app this token would be sent to the server for account creation.
        authToken = token
    }

    private func generateToken(username: String, password: String) -> String {
        let combined = "\(username):\(password)"
        let hash = SHA256.hash(data: Data(combined.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    StartupView()
}

