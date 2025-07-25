//
//  MapViewModel.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 29/6/25.
//

import Foundation
import MapKit
import CoreLocation
import AVFoundation
import UIKit

class MapViewModel: NSObject, ObservableObject {
    @Published var route: MKRoute?
    @Published var userLocation: CLLocationCoordinate2D?
    let parkingLocation: CLLocationCoordinate2D

    private let locationManager = CLLocationManager()
    private var lastAnnouncedInstruction: String? = nil
    private var lastSpokenTime: Date = .distantPast
    private let maxDistanceFromRoute: CLLocationDistance = 50
    private var hasAnnouncedRecalculation = false
    private var hasSpokenInitialInstruction = false

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
                    self?.announceInitialInstructionIfNeeded()
                }
            } else if let error = error {
                print("Error calculando ruta: \(error.localizedDescription)")
            }
        }
    }

    func announceClosestStepIfNeeded() {
        guard let route = route, let userCoord = userLocation else { return }
        guard Date().timeIntervalSince(lastSpokenTime) > 3 else { return }

        let userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        var closestIndex: Int?
        var minDistance: CLLocationDistance = .greatestFiniteMagnitude

        for (i, step) in route.steps.enumerated() {
            let stepCoord = step.polyline.coordinate
            let stepLoc = CLLocation(latitude: stepCoord.latitude, longitude: stepCoord.longitude)
            let distance = userLoc.distance(from: stepLoc)

            if distance < minDistance {
                minDistance = distance
                closestIndex = i
            }
        }

        guard let idx = closestIndex else { return }
        let step = route.steps[idx]
        let distanceToStep = userLoc.distance(from: CLLocation(latitude: step.polyline.coordinate.latitude, longitude: step.polyline.coordinate.longitude))

        guard !step.instructions.isEmpty, distanceToStep > 5 else { return }
        guard step.instructions != lastAnnouncedInstruction else { return }

        let message = personalizedInstruction(for: step.instructions)

        if distanceToStep < 10 {
            speak(message)
        } else if distanceToStep < 50 {
            let rounded = Int((distanceToStep / 10.0).rounded() * 10)
            speak("En \(rounded) metros, \(message.lowercased())")
        } else {
            let rounded = Int((distanceToStep / 10.0).rounded() * 10)
            speak("En \(rounded) metros, \(message.lowercased())")
        }

        lastAnnouncedInstruction = step.instructions
        lastSpokenTime = Date()
    }
    
    func distanceToCar() -> Int? {
        guard let userCoord = userLocation else { return nil }
        let userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let carLoc = CLLocation(latitude: parkingLocation.latitude, longitude: parkingLocation.longitude)
        let distance = userLoc.distance(from: carLoc)
        return Int(distance)
    }


    private func announceInitialInstructionIfNeeded() {
        guard let route = route, !hasSpokenInitialInstruction else { return }
        if let firstStep = route.steps.dropFirst().first, !firstStep.instructions.isEmpty {
            let message = "Todo listo. Vamos a por tu coche. " + personalizedInstruction(for: firstStep.instructions)
            speak(message)
            hasSpokenInitialInstruction = true
        }
    }

    private func personalizedInstruction(for instruction: String) -> String {
        let lower = instruction.lowercased()

        if lower.contains("gira a la derecha") {
            return "gira a la derecha para acercarte a tu coche"
        } else if lower.contains("gira a la izquierda") {
            return "gira a la izquierda, cada paso te acerca más"
        } else if lower.contains("continúa") || lower.contains("sigue") {
            return "sigue recto, tu coche te espera"
        } else if lower.contains("ha llegado") || lower.contains("su destino") {
            return "has llegado. Mira bien, tu coche debería estar muy cerca"
        } else {
            return instruction
        }
    }

    private func speak(_ instruction: String) {
        VoiceGuideService.shared.speak(instruction)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

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

    private func announceRecalculatingRouteIfNeeded() {
        if !hasAnnouncedRecalculation {
            VoiceGuideService.shared.speak("Ups, parece que tomaste otro camino. Te busco una nueva ruta.")
            hasAnnouncedRecalculation = true
        }
    }

    private func resetRecalculationAnnouncement() {
        hasAnnouncedRecalculation = false
    }

    var trimmedPolyline: MKPolyline? {
        guard let route = route, let userCoord = userLocation else { return route?.polyline }
        let userLocation = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let polyline = route.polyline
        let points = polyline.points()
        let count = polyline.pointCount

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
