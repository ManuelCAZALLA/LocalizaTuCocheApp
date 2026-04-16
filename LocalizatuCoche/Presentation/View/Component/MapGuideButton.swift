import SwiftUI

struct MapGuideButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("Volver a mi coche")
                .padding(.top, 8)
        }
    }
} 

#Preview {
    MapGuideButton(action: {
        print("Botón Volver a mi coche")
    })
}
