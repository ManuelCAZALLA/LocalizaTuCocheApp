import Foundation
import MapKit
import AVFoundation
import Combine
import SwiftUI

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Propiedades Publicas
    @Published var route: MKRoute?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var parkingLocation: CLLocationCoordinate2D
    @Published var trimmedPolyline: MKPolyline?
    @Published var timeRemaining: TimeInterval = 0
    @Published var distanceRemaining: CLLocationDistance = 0
    @Published var destination: CLLocationCoordinate2D?
    @Published var isRecalculatingRoute = false
    @Published var currentStepInstruction: String?
    @Published var nextStepInstruction: String?
    
    // MARK: - Propiedades Privadas
    private let locationManager = CLLocationManager()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var cancellables = Set<AnyCancellable>()
    private var lastSpokenTime: Date?
    private var lastRouteRecalculationTime: Date?
    private var consecutiveOffRouteCount = 0
    private var lastKnownGoodLocation: CLLocation?
    private var routeDeviation = false
    private var routeCalculationTimer: Timer?
    private var currentStepIndex = 0
    private var hasSpokenInitialMessage = false
    
    // 🔹 Nuevo: para recordar el último paso anunciado
    private var lastSpokenStepIndex: Int?
    
    // MARK: - Inicialización
    init(parkingLocation: CLLocationCoordinate2D) {
        self.parkingLocation = parkingLocation
        self.destination = parkingLocation
        super.init()
        
        configureLocationManager()
        configureAudioSession()
        setupBindings()
        
        // Calcula la ruta inicial después de un breve retraso
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.calculateRoute()
        }
    }
    
    // MARK: - Configuración
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 3
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error configurando audio: \(error)")
            try? AVAudioSession.sharedInstance().setCategory(.playback)
        }
    }
    
    private func setupBindings() {
        $route
            .compactMap { $0 }
            .sink { [weak self] route in
                self?.updateRouteSteps(route: route)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Gestión de Ubicación
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy > 0 && location.horizontalAccuracy < 50 else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.userLocation = location.coordinate
            self?.updateTimeAndDistance(from: location)
            self?.checkForRouteRecalculation(from: location)
            self?.updateCurrentStep(from: location)
            self?.speakNextInstructionIfNeeded(from: location)
            self?.lastKnownGoodLocation = location
        }
    }
    
    // MARK: - Cálculo de Ruta
    func calculateRoute(isRecalculation: Bool = false) {
        guard let userLocation = userLocation else { return }
        
        isRecalculatingRoute = true
        routeCalculationTimer?.invalidate()
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: parkingLocation))
        request.transportType = .walking
        request.requestsAlternateRoutes = false
        
        MKDirections(request: request).calculate { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isRecalculatingRoute = false
                
                if let error = error {
                    print("Error calculando ruta: \(error)")
                    self.speak("No se pudo calcular la ruta")
                    return
                }
                
                guard let route = response?.routes.first else {
                    print("No se encontraron rutas")
                    self.speak("No se encontró una ruta válida")
                    return
                }
                
                print("Ruta calculada: \(Int(route.distance))m, \(Int(route.expectedTravelTime/60))min")
                self.route = route
                self.trimmedPolyline = route.polyline
                self.timeRemaining = route.expectedTravelTime
                self.distanceRemaining = route.distance
                
                if isRecalculation {
                    self.currentStepIndex = 0
                    self.speak("Ruta recalculada")
                } else if !self.hasSpokenInitialMessage {
                    let startStreet = self.extractStreetName(from: route.steps.first?.instructions ?? "")
                    self.speak("Dirígete hacia \(startStreet) para llegar a tu coche")
                    self.hasSpokenInitialMessage = true
                }
                
                self.lastRouteRecalculationTime = Date()
            }
        }
    }
    
    // MARK: - Gestión de Pasos de Ruta
    private func updateRouteSteps(route: MKRoute) {
        let steps = route.steps.filter { !$0.instructions.isEmpty }
        guard !steps.isEmpty else { return }
        
        currentStepIndex = 0
        currentStepInstruction = steps.first?.instructions
        nextStepInstruction = steps.count > 1 ? steps[1].instructions : nil
    }
    
    private func updateCurrentStep(from location: CLLocation) {
        guard let route = route else { return }
        
        let steps = route.steps.filter { !$0.instructions.isEmpty }
        guard !steps.isEmpty else { return }
        
        for (index, step) in steps.enumerated() {
            let stepLocation = CLLocation(latitude: step.polyline.coordinate.latitude,
                                         longitude: step.polyline.coordinate.longitude)
            let distance = location.distance(from: stepLocation)
            
            if distance < 20 { // Umbral de 20 metros para cambiar de paso
                if index != currentStepIndex {
                    currentStepIndex = index
                    currentStepInstruction = step.instructions
                    nextStepInstruction = index + 1 < steps.count ? steps[index + 1].instructions : nil
                }
                break
            }
        }
    }
    
    // MARK: - Desviación de Ruta
    private func checkForRouteRecalculation(from location: CLLocation) {
        guard let route = route, !isRecalculatingRoute else { return }
        
        let now = Date()
        if let lastRecalc = lastRouteRecalculationTime, now.timeIntervalSince(lastRecalc) < 8.0 {
            return
        }
        
        let point = MKMapPoint(location.coordinate)
        let distanceToRoute = route.polyline.distance(to: point)
        
        if distanceToRoute > 25 {
            consecutiveOffRouteCount += 1
            routeDeviation = true
            
            if consecutiveOffRouteCount >= 2 {
                lastRouteRecalculationTime = now
                consecutiveOffRouteCount = 0
                calculateRoute(isRecalculation: true)
            }
        } else {
            if routeDeviation {
                routeDeviation = false
            }
            consecutiveOffRouteCount = 0
        }
    }
    
    // MARK: - Instrucciones de Voz
    private func speakNextInstructionIfNeeded(from location: CLLocation) {
        guard let route = route else { return }
        
        let now = Date()
        // 🔹 Esperar más tiempo antes de permitir otra instrucción
        if let lastSpokenTime = lastSpokenTime, now.timeIntervalSince(lastSpokenTime) < 10.0 {
            return
        }
        
        let steps = route.steps.filter { !$0.instructions.isEmpty }
        
        for (index, step) in steps.enumerated() {
            if index <= currentStepIndex { continue }
            
            let stepLocation = CLLocation(latitude: step.polyline.coordinate.latitude,
                                          longitude: step.polyline.coordinate.longitude)
            let distance = location.distance(from: stepLocation)
            
            var triggerDistance: CLLocationDistance = 40
            if step.instructions.lowercased().contains("llegado") ||
               step.instructions.lowercased().contains("destino") {
                triggerDistance = 20
            }
            
            if distance < triggerDistance {
                // 🔹 Solo hablar si este paso no se ha anunciado aún
                if lastSpokenStepIndex != index {
                    speak(step.instructions)
                    lastSpokenStepIndex = index
                    lastSpokenTime = now
                }
                break
            }
        }
    }
    
    private func speak(_ text: String) {
        guard !text.isEmpty else { return }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error activando audio: \(error)")
        }

        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        let localeLanguageCode: String
        if #available(iOS 16.0, *) {
            if let languageCode = Locale.current.language.languageCode {
                localeLanguageCode = languageCode.identifier
            } else {
                localeLanguageCode = "es" // default fallback
            }
        } else {
            localeLanguageCode = Locale.current.languageCode ?? "es"
        }

        let supportedLanguages = [
            "es": "es-ES",
            "fr": "fr-FR",
            "de": "de-DE",
            "en": "en-US",
            "ar": "ar-SA",
            "it": "it-IT",
            "pt": "pt-PT"
        ]

        let languageCode = supportedLanguages[localeLanguageCode] ?? "es-ES"

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        utterance.rate = 0.5
        utterance.volume = 1.0

        speechSynthesizer.speak(utterance)
    }

    // MARK: - Cálculo de Distancia y Tiempo
    private func updateTimeAndDistance(from location: CLLocation) {
        if let route = route {
            updateTimeAndDistanceWithRoute(from: location, route: route)
        } else {
            updateDirectTimeAndDistance(from: location)
        }
    }
    
    private func updateTimeAndDistanceWithRoute(from location: CLLocation, route: MKRoute) {
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
        let points = polyline.points()
        
        for i in closestIndex..<polyline.pointCount - 1 {
            let start = points[i]
            let end = points[i + 1]
            remainingDistance += start.distance(to: end)
        }
        
        let progressFactor = min(1.0, max(0.0, remainingDistance / route.distance))
        let remainingTime = route.expectedTravelTime * progressFactor
        
        distanceRemaining = max(0, remainingDistance)
        timeRemaining = max(0, remainingTime)
    }
    
    private func updateDirectTimeAndDistance(from location: CLLocation) {
        let directDistance = location.distance(from: CLLocation(
            latitude: parkingLocation.latitude,
            longitude: parkingLocation.longitude
        ))
        
        distanceRemaining = directDistance
        timeRemaining = directDistance / 1.4 // Velocidad de caminata ~5 km/h
    }
    
    // MARK: - Helpers
    func distanceToCar() -> Int? {
        Int(distanceRemaining)
    }
    
    var expectedTravelTimeMinutes: Int? {
        guard timeRemaining.isFinite, !timeRemaining.isNaN else { return nil }
        return Int(timeRemaining / 60)
    }
    
    private func extractStreetName(from instruction: String) -> String {
        let words = instruction.split(separator: " ")
        if let index = words.firstIndex(where: { $0.lowercased() == "en" }), index + 1 < words.count {
            return words[(index + 1)...].joined(separator: " ")
        }
        return "la calle actual"
    }
    
    // MARK: - Limpieza
    deinit {
        routeCalculationTimer?.invalidate()
        locationManager.stopUpdatingLocation()
        cancellables.forEach { $0.cancel() }
    }
}
