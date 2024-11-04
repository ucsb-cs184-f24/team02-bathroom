//
//  LocationManager.swift
//  ucsb-bathrooms
//
//  Created by Zheli Chen on 10/19/24.
//

import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocation? = CLLocation(latitude: 34.4140, longitude: -119.8489) // UCSB default
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastError: String?
    private var isUpdatingLocation = false

    override init() {
        super.init()
        self.setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // Less strict accuracy
        locationManager.distanceFilter = 10.0
        locationManager.allowsBackgroundLocationUpdates = false

        // Check current authorization status
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestLocationIfNeeded() {
        guard !isUpdatingLocation else { return }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied:
            lastError = "Location access denied. Please enable in Settings."
        case .restricted:
            lastError = "Location access restricted"
        @unknown default:
            break
        }
    }

    private func startUpdatingLocation() {
        guard !isUpdatingLocation else { return }
        isUpdatingLocation = true

        // Request a single location update instead of continuous updates
        locationManager.requestLocation()
    }

    func stopUpdatingLocation() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startUpdatingLocation()
            case .denied:
                self.lastError = "Location access denied"
            case .restricted:
                self.lastError = "Location access restricted"
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            @unknown default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Only update if accuracy is reasonable
            if location.horizontalAccuracy <= 100 {
                self.userLocation = location
                self.lastError = nil
                self.isUpdatingLocation = false
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Handle the specific kCLErrorDomain error 0
            if (error as NSError).domain == kCLErrorDomain && (error as NSError).code == 0 {
                // This is often a temporary error, try again with single update
                self.locationManager.requestLocation()
                return
            }

            #if targetEnvironment(simulator)
            // Use UCSB location for simulator
            self.userLocation = CLLocation(latitude: 34.4140, longitude: -119.8489)
            #else
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.lastError = "Location access denied"
                case .locationUnknown:
                    // Try again once for unknown location
                    self.locationManager.requestLocation()
                default:
                    self.lastError = "Unable to determine location"
                }
            }
            #endif

            self.isUpdatingLocation = false
        }
    }
}
