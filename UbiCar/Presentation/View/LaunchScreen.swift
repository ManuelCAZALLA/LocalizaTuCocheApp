//
//  LaunchScreen.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 21/7/25.
//

import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            
            LinearGradient(
                gradient: Gradient(colors: [Color("AppPrimary"), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
               
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 130, height: 130)
                        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
                    Image("LaunchImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                }

                Text("Aparca, guarda y vuelve fácilmente")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("AppPrimary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("Tu coche siempre localizado")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Color("AppPrimary").opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    LaunchScreen()
}
