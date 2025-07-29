//
//  Extension+Poliline.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 26/7/25.
//

import MapKit

extension MKPolyline {
    /// Calcula la distancia mínima (en metros) desde un punto a la polilínea
    func distance(to point: MKMapPoint) -> CLLocationDistance {
        var minDistance = CLLocationDistance(Double.greatestFiniteMagnitude)
        let points = self.points()

        for i in 0..<(self.pointCount - 1) {
            let segmentStart = points[i]
            let segmentEnd = points[i + 1]

            let distanceMapPoints = distanceFromPointToSegment(point: point, segmentStart: segmentStart, segmentEnd: segmentEnd)

            // Convertir de map points a metros (usar la latitud del punto)
            let metersPerMapPoint = MKMetersPerMapPointAtLatitude(point.coordinate.latitude)
            let distanceMeters = distanceMapPoints * metersPerMapPoint

            if distanceMeters < minDistance {
                minDistance = distanceMeters
            }
        }

        return minDistance
    }

    /// Distancia del punto a un segmento de línea (segmentStart-segmentEnd)
    private func distanceFromPointToSegment(point: MKMapPoint, segmentStart: MKMapPoint, segmentEnd: MKMapPoint) -> CLLocationDistance {
        let dx = segmentEnd.x - segmentStart.x
        let dy = segmentEnd.y - segmentStart.y

        if dx == 0 && dy == 0 {
            // El segmento es un punto
            return point.distance(to: segmentStart)
        }

        // Proyección del punto sobre el segmento (normalizado 0 a 1)
        let t = max(0, min(1, ((point.x - segmentStart.x) * dx + (point.y - segmentStart.y) * dy) / (dx * dx + dy * dy)))

        // Punto proyectado en el segmento
        let projection = MKMapPoint(x: segmentStart.x + t * dx, y: segmentStart.y + t * dy)

        // Distancia entre el punto y su proyección
        return point.distance(to: projection)
    }
}
