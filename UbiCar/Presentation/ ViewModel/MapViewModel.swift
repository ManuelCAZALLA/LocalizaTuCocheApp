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
    
    // Distancia máxima permitida a la ruta antes de recalcular (en metros)
    private let maxDistanceFromRoute: CLLocationDistance = 50

    // Comprueba si el usuario está fuera de la ruta y recalcula si es necesario
    private func checkIfUserIsOffRouteAndRecalculate() {
        guard let route = route, let userCoord = userLocation else { return }
        let userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let polyline = route.polyline
        let points = polyline.points()
        let count = polyline.pointCount
        var minDistance = CLLocationDistance.greatestFiniteMagnitude
        for i in 0..<count {
            let coord = points[i].coordinate
            let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let distance = userLoc.distance(from: loc)
            if distance < minDistance {
                minDistance = distance
            }
        }
        if minDistance > maxDistanceFromRoute {
            announceRecalculatingRouteIfNeeded()
            calculateRoute()
        }
    }

    private var hasAnnouncedRecalculation = false
    private func announceRecalculatingRouteIfNeeded() {
        if !hasAnnouncedRecalculation {
            let utterance = AVSpeechUtterance(string: "Recalculando ruta")
            utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
            speechSynthesizer.speak(utterance)
            hasAnnouncedRecalculation = true
        }
    }
    private func resetRecalculationAnnouncement() {
        hasAnnouncedRecalculation = false
    }
    
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
    
    private var lastAnnouncedInstruction: String? = nil

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
        guard let idx = closestIndex else { return }
        let step = route.steps[idx]
        let ignoredInstructions = [
            "", "Ve al inicio de la ruta", "En 2 metros llegará a su destino"
        ]
        // No anunciar instrucciones vacías o genéricas más de una vez
        if !ignoredInstructions.contains(step.instructions) &&
            (step.instructions != lastAnnouncedInstruction) {
            let utterance = AVSpeechUtterance(string: step.instructions)
            utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
            speechSynthesizer.speak(utterance)
            lastAnnouncedInstruction = step.instructions
        } else if idx + 1 < route.steps.count {
            let nextStep = route.steps[idx + 1]
            let nextStepLoc = CLLocation(latitude: nextStep.polyline.coordinate.latitude, longitude: nextStep.polyline.coordinate.longitude)
            let distanceToNext = userLoc.distance(from: nextStepLoc)
            if distanceToNext < 30 && !ignoredInstructions.contains(nextStep.instructions) && (nextStep.instructions != lastAnnouncedInstruction) {
                let utterance = AVSpeechUtterance(string: "En \(Int(distanceToNext)) metros, \(nextStep.instructions)")
                utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
                speechSynthesizer.speak(utterance)
                lastAnnouncedInstruction = nextStep.instructions
            }
        }
    }
    
    // Devuelve una polilínea  desde el punto más cercano al usuario hasta el coche
    var trimmedPolyline: MKPolyline? {
        guard let route = route, let userCoord = userLocation else { return route?.polyline }
        let userLocation = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let polyline = route.polyline
        let points = polyline.points()
        let count = polyline.pointCount
        // Buscar el punto de la polilínea más cercano al usuario
        var closestIndex = 0
        var minDistance = CLLocationDistance.greatestFiniteMagnitude
        for i in 0..<count {
            let coord = points[i].coordinate
            let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let distance = userLocation.distance(from: loc)
            if distance < minDistance {
                minDistance = distance
                closestIndex = i
            }
        }
        // Crear una nueva polilínea desde el punto más cercano hasta el final
        let trimmedCoords = (closestIndex..<count).map { points[$0].coordinate }
        guard trimmedCoords.count > 1 else { return nil }
        return MKPolyline(coordinates: trimmedCoords, count: trimmedCoords.count)
    }
    
    var expectedTravelTimeMinutes: Int? {
        guard let route = route else { return nil }
        return Int(route.expectedTravelTime / 60)
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
            self.checkIfUserIsOffRouteAndRecalculate()
            self.resetRecalculationAnnouncement()
            self.calculateRoute()
        }
    }
}
