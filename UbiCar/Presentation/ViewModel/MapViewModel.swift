import Foundation
import MapKit
import AVFoundation
import Combine
import SwiftUI

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var route: MKRoute?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var parkingLocation: CLLocationCoordinate2D
    @Published var trimmedPolyline: MKPolyline?
    @Published var timeRemaining: TimeInterval = 0
    @Published var distanceRemaining: CLLocationDistance = 0
    @Published var destination: CLLocationCoordinate2D?

    private let locationManager = CLLocationManager()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastInstructionIndex: Int?
    private var hasSpokenInitialMessage = false
    
    // PROPIEDADES PARA CONTROLAR RECÁLCULO Y AUDIO
    private var lastSpokenTime: Date?
    private var isRecalculating = false
    private var routeRecalculationCount = 0
    private var lastRouteRecalculationTime: Date?

    init(parkingLocation: CLLocationCoordinate2D) {
        self.parkingLocation = parkingLocation
        self.destination = parkingLocation
        super.init()

        // CONFIGURAR AUDIO SESSION PARA MODO SILENCIO
        configureAudioSession()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.calculateRoute()
        }
    }
    
    // CONFIGURACIÓN DE AUDIO PARA MODO SILENCIO
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Configurar categoría que ignora el modo silencio
            try audioSession.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
            )
            
            // Activar la sesión
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            print("🔊 Audio session configurada correctamente")
            
        } catch {
            print("❌ Error configurando audio session: \(error)")
            // Fallback: intentar configuración básica
            try? AVAudioSession.sharedInstance().setCategory(.playback)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        updateRouteIfNeeded(from: location)
        updateTimeAndDistance(from: location)
        speakNextInstructionIfNeeded(from: location)
    }

    // FUNCIÓN UPDATEROUTE CORREGIDA
    private func updateRouteIfNeeded(from location: CLLocation) {
        guard let route = route else {
            calculateRoute()
            return
        }
        
        // Evitar recálculos muy frecuentes
        if isRecalculating {
            return
        }
        
        let now = Date()
        if let lastRecalc = lastRouteRecalculationTime,
           now.timeIntervalSince(lastRecalc) < 5.0 {
            return
        }

        let point = MKMapPoint(location.coordinate)
        let distanceToRoute = route.polyline.distance(to: point)
        
        // Aumentamos la tolerancia para evitar recálculos innecesarios
        if distanceToRoute > 30 {
            print("📍 Usuario fuera de ruta (\(Int(distanceToRoute))m), recalculando...")
            lastRouteRecalculationTime = now
            routeRecalculationCount += 1
            calculateRoute(isRecalculation: true)
        }
    }

    // FUNCIÓN CALCULATEROUTE CORREGIDA
    func calculateRoute(isRecalculation: Bool = false) {
        guard let userLocation = userLocation else { return }
        
        isRecalculating = true

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: parkingLocation))
        request.transportType = .walking

        MKDirections(request: request).calculate { [weak self] response, error in
            guard let self = self, let route = response?.routes.first else {
                self?.speak("No se pudo calcular la ruta.")
                self?.isRecalculating = false
                return
            }

            DispatchQueue.main.async {
                self.route = route
                self.trimmedPolyline = route.polyline
                self.timeRemaining = route.expectedTravelTime
                self.distanceRemaining = route.distance
                self.isRecalculating = false

                if isRecalculation {
                    // CLAVE: En recálculo, resetear índices pero mantener estado de audio
                    self.lastInstructionIndex = nil // Permitir nuevas instrucciones
                    
                    if self.routeRecalculationCount <= 3 {
                        self.speak("Ruta recalculada. Continuamos hacia tu coche.")
                    }
                } else {
                    // Solo en cálculo inicial
                    if !self.hasSpokenInitialMessage {
                        let startStreet = self.extractStreetName(from: route.steps.first?.instructions ?? "")
                        let initialMessage = "Vamos hacia tu coche. Comenzamos en \(startStreet)."
                        print("🗣 \(initialMessage)")
                        self.speak(initialMessage)
                        self.hasSpokenInitialMessage = true
                        self.lastInstructionIndex = 0
                    }
                }
            }
        }
    }

    private func updateTimeAndDistance(from location: CLLocation) {
        guard let route = route else { return }

        let polyline = route.polyline
        let point = MKMapPoint(location.coordinate)

        var closestIndex = 0
        var closestDistance = CLLocationDistance.greatestFiniteMagnitude

        for i in 0..<polyline.pointCount {
            let pt = polyline.points()[i]
            let dist = point.distance(to: pt)
            if dist < closestDistance {
                closestDistance = dist
                closestIndex = i
            }
        }

        var remainingDistance: CLLocationDistance = 0
        for i in closestIndex..<polyline.pointCount - 1 {
            let start = polyline.points()[i]
            let end = polyline.points()[i + 1]
            remainingDistance += start.distance(to: end)
        }

        let factor = remainingDistance / route.distance
        let remainingTime = route.expectedTravelTime * factor

        DispatchQueue.main.async {
            self.distanceRemaining = remainingDistance
            self.timeRemaining = remainingTime
        }
    }

    private func extractStreetName(from instruction: String) -> String {
        let words = instruction.split(separator: " ")
        if let index = words.firstIndex(where: { $0.lowercased() == "en" }), index + 1 < words.count {
            return words[(index + 1)...].joined(separator: " ")
        }
        return "la calle actual"
    }

    // FUNCIÓN SPEAKNEXTINSTRUCTION CORREGIDA
    private func speakNextInstructionIfNeeded(from location: CLLocation) {
        guard let route = route else { return }
        
        // Evitar múltiples instrucciones muy seguidas
        let now = Date()
        if let lastSpokenTime = lastSpokenTime,
           now.timeIntervalSince(lastSpokenTime) < 3.0 {
            return
        }

        for (index, step) in route.steps.enumerated() {
            if step.instructions.isEmpty { continue }
            if let lastIndex = lastInstructionIndex, index <= lastIndex { continue }

            // Ignorar la primera instrucción si ya se dijo el mensaje inicial
            if index == 0 && hasSpokenInitialMessage { continue }

            let stepCoord = step.polyline.coordinate
            let stepLocation = CLLocation(latitude: stepCoord.latitude, longitude: stepCoord.longitude)
            let distance = location.distance(from: stepLocation)

            // Distancia ajustada según el tipo de instrucción
            var triggerDistance: CLLocationDistance = 40
            if step.instructions.lowercased().contains("llegado") ||
               step.instructions.lowercased().contains("destino") {
                triggerDistance = 20 // Más cerca para el destino
            }

            if distance < triggerDistance {
                var message = ""

                let instruction = step.instructions.lowercased()

                if instruction.contains("gira a la derecha") {
                    message = "Gira a la derecha en \(Int(distance)) metros."
                } else if instruction.contains("gira a la izquierda") {
                    message = "Gira a la izquierda en \(Int(distance)) metros."
                } else if instruction.contains("continúa recto") || instruction.contains("sigue recto") {
                    message = "Sigue recto."
                } else if instruction.contains("has llegado") || instruction.contains("llega a tu destino") {
                    message = "Has llegado a tu coche."
                } else {
                    message = step.instructions
                }

                print("🗣 Próxima instrucción: \(message)")
                speak(message)
                lastInstructionIndex = index
                lastSpokenTime = now
                break
            }
        }
    }

    // FUNCIÓN SPEAK CON AUDIO SESSION
    private func speak(_ text: String) {
        // Reactivar audio session antes de hablar
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Error activando audio session: \(error)")
        }
        
        // Parar cualquier audio en curso
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.5
        utterance.volume = 1.0 // Volumen máximo
        speechSynthesizer.speak(utterance)
        
        print("🎤 Audio iniciado: \(text)")
    }

    // MARK: - Helpers

    func distanceToCar() -> Int? {
        Int(distanceRemaining)
    }

    var expectedTravelTimeMinutes: Int? {
        guard timeRemaining.isFinite, !timeRemaining.isNaN else {
            return nil
        }
        return Int(timeRemaining / 60)
    }
}
