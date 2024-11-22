//
//  AddBathroomView.swift
//  ucsb-bathrooms
//
//  Created by Zheli Chen on 11/21/24.
//

import SwiftUI
import MapKit

struct AddBathroomView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var bathroomName: String = ""
    @State private var region: MKCoordinateRegion
    @State private var location: CLLocationCoordinate2D

    init(initialLocation: CLLocationCoordinate2D) {
        _region = State(initialValue: MKCoordinateRegion(
            center: initialLocation,
            span: MKCoordinateSpan(
                latitudeDelta: 0.005,
                longitudeDelta: 0.005
            )
        ))
        _location = State(initialValue: initialLocation)
    }

    var body: some View {
        VStack {
            ZStack {
                Map(
                    coordinateRegion: $region,
                    interactionModes: [.all],
                    showsUserLocation: true
                )
                .onAppear {
                    region.center = location
                }
                .onChange(of: region.center) { newCenter in
                    location = newCenter
                }

                // Center Pin
                Image(systemName: "mappin")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                    .offset(y: -20)
            }
            .frame(height: 300)

            Form {
                Section(header: Text("Bathroom Details")) {
                    TextField("Bathroom Name", text: $bathroomName)
                }

                Section {
                    Button("Add A Bathroom") {
                        saveBathroom()
                    }
                    .disabled(bathroomName.isEmpty)
                }
            }
        }
        .navigationTitle("Add A Bathroom")
        .navigationBarItems(trailing: Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        })
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func saveBathroom() {
        print("Bathroom saved: \(bathroomName) at \(location.latitude), \(location.longitude)")
        //add to firebase
        
        presentationMode.wrappedValue.dismiss()
    }
}
