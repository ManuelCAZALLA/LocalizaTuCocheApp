import Foundation
import Combine

class AppState: ObservableObject {
    @Published var openParkingFromNotification: Bool = false
} 