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
            ContentView()
        }
    }
}
