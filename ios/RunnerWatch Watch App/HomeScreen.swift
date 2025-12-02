//
//  HomeScreen.swift
//  RunnerWatch Watch App
//
//  Created by Crislenny Uceta on 11/30/25.
//

import Foundation
import SwiftUI

struct HomeScreen: View {

    var body: some View {
        ZStack {
            if #available(iOS 14.0, *) {
                ThriveTheme.background
                    .ignoresSafeArea()
            } else {
                // Fallback on earlier versions
            }

            VStack(spacing: 12) {
                Text("Hey!")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ThriveTheme.accent)

//                // Log Habit
//                NavigationLink(destination: HabitListScreen()) {
//                    MenuButton(icon: "habit-icon", label: "Log Habit")
//                }
//
//                // Log Mood
//                NavigationLink(destination: MoodListScreen()) {
//                    MenuButton(icon: "mood-icon", label: "Log Mood")
//                }
            }
        }
    }
}

struct MenuButton: View {
    let icon: String
    let label: String

    var body: some View {
        HStack {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)

            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ThriveTheme.primary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(red: 233/255, green: 238/255, blue: 235/255))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 181/255, green: 200/255, blue: 189/255), lineWidth: 1)
        )
        .cornerRadius(10)
    }
}
