//
//  countdownApp.swift
//  countdown
//
//  Created by Sagar Varma on 1/7/25.
//

import SwiftUI

@main
struct countdownApp: App {
    init() {
        // Set navigation title font to Georgia
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont(name: "Georgia", size: 34)!
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont(name: "Georgia", size: 17)!
        ]
    }
    
    var body: some Scene {
        WindowGroup {
            // Runtime check for device idiom
            if UIDevice.current.userInterfaceIdiom == .phone {
                ContentView()
            } else {
                // Display a message on iPad instead of loading the app UI
                VStack {
                    Spacer()
                    Image(systemName: "iphone.gen2") // Example iPhone icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                        .padding(.bottom)
                    Text("Event Countdown is designed for iPhone.")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
    }
}
