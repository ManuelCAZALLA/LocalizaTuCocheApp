//
//  MapViewModel.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 29/6/25.
//

import Foundation
import MapKit
import CoreLocation

class MapViewModel: NSObject, ObservableObject {
    @Published var route: MKRoute?
    @Published var userLocation: CLLocationCoordinate2D?
    let parkingLocation: CLLocationCoordinate2D
    
    private let locationManager = CLLocationManager()
    private var lastSpokenStepIndex: Int? = nil
    private var lastAnnouncedInstruction: String? = nil
    private var lastSpokenTime: Date = .distantPast
    
    private let maxDistanceFromRoute: CLLocationDistance = 50
    private var hasAnnouncedRecalculation = false

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

        // Evitar repetir la voz demasiado seguido
        guard Date().timeIntervalSince(lastSpokenTime) > 3 else { return }

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
        let ignoredInstructions = ["", "Ve al inicio de la ruta", "En 2 metros llegará a su destino"]

        if !ignoredInstructions.contains(step.instructions) && (step.instructions != lastAnnouncedInstruction) {
            VoiceGuideService.shared.speak(step.instructions)
            lastAnnouncedInstruction = step.instructions
            lastSpokenTime = Date()
        } else if idx + 1 < route.steps.count {
            let nextStep = route.steps[idx + 1]
            let nextStepLoc = CLLocation(latitude: nextStep.polyline.coordinate.latitude, longitude: nextStep.polyline.coordinate.longitude)
            let distanceToNext = userLoc.distance(from: nextStepLoc)
            if distanceToNext < 30 &&
                !ignoredInstructions.contains(nextStep.instructions) &&
                (nextStep.instructions != lastAnnouncedInstruction) {
                let announcement = String(format: NSLocalizedString("in_meters_instruction", comment: ""), Int(distanceToNext), nextStep.instructions)
                VoiceGuideService.shared.speak(announcement)
                lastAnnouncedInstruction = nextStep.instructions
                lastSpokenTime = Date()
            }
        }
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
            VoiceGuideService.shared.speak(NSLocalizedString("recalculating_route", comment: ""))
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
