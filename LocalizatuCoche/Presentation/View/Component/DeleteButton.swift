import SwiftUI

struct DeleteButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("Borrar ubicación")
                .foregroundColor(.red)
        }
    }
} 

#Preview {
    DeleteButton(action: {
        print("Borrar ubicación")
    })
}
