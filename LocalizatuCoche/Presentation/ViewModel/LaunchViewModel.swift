//
//  LaunchView.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 29/6/25.
//

import Foundation
import Combine
import CoreLocation

class LaunchViewModel: NSObject, ObservableObject {
    @Published var isAuthorized = false
    
    private let locationManager = LocationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        checkAuthorization()
        setupBindings()
    }
    
    func requestAuthorization() {
        locationManager.requestAuthorization()
    }
    
    private func setupBindings() {
        locationManager.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.checkAuthorization()
            }
            .store(in: &cancellables)
    }
    
    private func checkAuthorization() {
        let status = locationManager.authorizationStatus
        isAuthorized = (status == .authorizedAlways || status == .authorizedWhenInUse)
    }
}
