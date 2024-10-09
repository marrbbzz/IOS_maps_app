//
//  ContentView.swift
//  Exercise5
//
//  Created by Maria Kailahti on 9.10.2024
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 60.3913, longitude: 5.3221),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var locations: [Location] = []
    @State private var showingLocationsList = false
    let geocoder = CLGeocoder()

    var body: some View {
        ZStack {
            Map(coordinateRegion: $mapRegion, annotationItems: locations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.largeTitle)
                }
            }
            .ignoresSafeArea()
            .gesture(MagnificationGesture()
                .onChanged { value in
                    zoomMap(by: value)
                }
            )
            
            VStack {
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        resetToInitialLocation()
                    }) {
                        Text("Bergen")
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showingLocationsList = true
                    }) {
                        Text("Show Locations")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .sheet(isPresented: $showingLocationsList) {
                        LocationsListView(
                            locations: locations,
                            selectLocation: { location in
                                mapRegion.center = location.coordinate
                            },
                            deleteLocation: { location in
                                locations.removeAll { $0.id == location.id }
                            }
                        )
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
        .gesture(
            TapGesture()
                .onEnded { value in
                    let newLocation = Location(coordinate: mapRegion.center)
                    reverseGeocode(location: newLocation)
                }
        )
    }
    
    private func reverseGeocode(location: Location) {
        let clLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
            if let placemark = placemarks?.first {
                let city = placemark.locality ?? "Unknown city"
                let country = placemark.country ?? "Unknown country"
                let updatedLocation = Location(
                    coordinate: location.coordinate,
                    city: city,
                    country: country
                )
                locations.append(updatedLocation)
            } else {
                locations.append(location)
            }
        }
    }

    private func resetToInitialLocation() {
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 60.3913, longitude: 5.3221),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    private func zoomMap(by scale: CGFloat) {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: mapRegion.span.latitudeDelta / scale,
            longitudeDelta: mapRegion.span.longitudeDelta / scale
        )
        mapRegion.span = newSpan
    }
}

struct Location: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    var city: String? = nil
    var country: String? = nil
}

struct LocationsListView: View {
    let locations: [Location]
    let selectLocation: (Location) -> Void
    let deleteLocation: (Location) -> Void

    var body: some View {
        NavigationView {
            List(locations) { location in
                HStack {
                    VStack(alignment: .leading) {
                        Button(action: {
                            selectLocation(location)
                        }) {
                            Text("Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)")
                                .foregroundColor(.blue)
                        }

                        if let city = location.city, let country = location.country {
                            Text("City: \(city), Country: \(country)")
                        } else {
                            Text("City/Country: Unknown")
                        }
                    }

                    Spacer()

                    // Delete button
                    Button(action: {
                        deleteLocation(location)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .navigationTitle("Marked Locations")
        }
    }
}
