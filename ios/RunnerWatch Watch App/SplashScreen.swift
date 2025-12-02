//
//  SplashScreen.swift
//  RunnerWatch Watch App
//
//  Created by Crislenny Uceta on 11/30/25.
//

import Foundation
import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false

    var body: some View {
        ZStack {
            // Same background color as WearOS
            ThriveTheme.background
                .ignoresSafeArea()

            Image("joey")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
        }
        .onAppear {
            // 3-second timer
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            HomeScreen()   // will replace with auth logic later
        }
    }
}
