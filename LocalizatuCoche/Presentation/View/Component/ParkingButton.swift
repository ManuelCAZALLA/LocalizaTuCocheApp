//
//  ParkingButton.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 28/6/25.
//

import SwiftUI

struct ParkingButton: View {
    let enabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Aparcado aquí")
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .background(enabled ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .disabled(!enabled)
    }
}

#Preview {
    ParkingButton(enabled: true) {
        print("Botón Aparcado aquí pulsado")
    }
}

