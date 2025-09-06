import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showingParkingLocation = false
    @State private var showingDirections = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack {
                    Image(systemName: "car.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Localiza tu Coche")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Main Actions
                VStack(spacing: 15) {
                    Button(action: {
                        showingParkingLocation = true
                    }) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text("Ver Aparcamiento")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showingDirections = true
                    }) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.green)
                            Text("Direcciones")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                
                Spacer()
                
                // Status
                if let location = locationManager.location {
                    Text("Ubicación disponible")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Buscando ubicación...")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingParkingLocation) {
            ParkingLocationView()
        }
        .sheet(isPresented: $showingDirections) {
            DirectionsView()
        }
    }
}

struct ParkingLocationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Ubicación del Aparcamiento")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Tu coche está aparcado en:")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Text("Calle Principal, 123")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Button("Cerrar") {
                // Dismiss sheet
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct DirectionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Direcciones")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Gira a la derecha en 50m")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Text("Continúa recto 200m")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Text("Tu coche está a la izquierda")
                .font(.body)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Button("Cerrar") {
                // Dismiss sheet
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
