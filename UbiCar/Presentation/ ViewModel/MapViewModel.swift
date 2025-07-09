//
//  MapViewModel.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 29/6/25.
//

import Foundation
import MapKit
import AVFoundation
import CoreLocation

class MapViewModel: NSObject, ObservableObject {
    @Published var route: MKRoute?
    @Published var userLocation: CLLocationCoordinate2D?
    let parkingLocation: CLLocationCoordinate2D
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let locationManager = CLLocationManager()
    private var lastSpokenStepIndex: Int? = nil
    
    init(parkingLocation: CLLocationCoordinate2D) {
        self.parkingLocation = parkingLocation
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func calculateRoute() {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: parkingLocation))
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            if let route = response?.routes.first {
                DispatchQueue.main.async {
                    self?.route = route
                }
            } else if let error = error {
                print("Error calculando ruta: \(error.localizedDescription)")
            }
        }
    }
    
    func distanceToCar() -> Int? {
        guard let userCoord = userLocation else { return nil }
        let userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let carLoc = CLLocation(latitude: parkingLocation.latitude, longitude: parkingLocation.longitude)
        let distance = userLoc.distance(from: carLoc)
        return Int(distance)
    }
    
    func announceClosestStepIfNeeded() {
        guard let route = route, let userCoord = userLocation else { return }
        let userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        var closestIndex: Int?
        var minDistance: CLLocationDistance = .greatestFiniteMagnitude
        for (i, step) in route.steps.enumerated() {
            let stepLoc = CLLocation(latitude: step.polyline.coordinate.latitude, longitude: step.polyline.coordinate.longitude)
            let distance = userLoc.distance(from: stepLoc)
            if distance < minDistance {
                minDistance = distance
                closestIndex = i
            }
        }
        // Solo anunciar si es un paso nuevo y la instrucción no está vacía
        if let idx = closestIndex, idx != lastSpokenStepIndex {
            let step = route.steps[idx]
            if !step.instructions.isEmpty {
                // No hablar si ya está hablando
                if speechSynthesizer.isSpeaking { return }
                speechSynthesizer.stopSpeaking(at: .immediate)
                let utterance = AVSpeechUtterance(string: step.instructions)
                utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
                speechSynthesizer.speak(utterance)
                lastSpokenStepIndex = idx
            }
        }
    }
}

extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async {
            let newLocation = locations.last?.coordinate
            // Solo recalcular si el usuario se ha movido más de 10 metros
            if let last = self.userLocation, let newLoc = newLocation {
                let lastLoc = CLLocation(latitude: last.latitude, longitude: last.longitude)
                let newLocObj = CLLocation(latitude: newLoc.latitude, longitude: newLoc.longitude)
                if lastLoc.distance(from: newLocObj) < 10 {
                    self.userLocation = newLoc
                    self.announceClosestStepIfNeeded()
                    return
                }
            }
            self.userLocation = newLocation
            self.announceClosestStepIfNeeded()
            self.calculateRoute()
        }
    }
}
