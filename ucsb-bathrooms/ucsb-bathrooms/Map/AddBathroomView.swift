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
    @State private var buildingName: String = ""
    @State private var floor: Int = 1
    @State private var selectedGender: String = "All Gender"
    @State private var location: CLLocationCoordinate2D
    @State private var isLoading = false
    @State private var errorMessage: String = ""
    @State private var showAlert = false
    @State private var floorText = "1"

    @State private var region: MKCoordinateRegion
    var onBathroomAdded: () -> Void

    init(initialLocation: CLLocationCoordinate2D, onBathroomAdded: @escaping () -> Void) {
        _location = State(initialValue: initialLocation)
        _region = State(initialValue: MKCoordinateRegion(
            center: initialLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
        self.onBathroomAdded = onBathroomAdded
    }

    private let genderOptions = ["All Gender", "Men", "Women"]

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
                .onChange(of: region) { newRegion in
                    location = newRegion.center
                }
                .frame(height: 300)

                // Center Pin
                Image(systemName: "mappin")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                    .offset(y: -20)
            }

            Form {
                Section(header: Text("Bathroom Details")) {
                    TextField("Bathroom Name", text: $bathroomName)
                    TextField("Building Name", text: $buildingName)
                    TextField("Floor", text: $floorText)
                        .keyboardType(.numberPad)
                        .onChange(of: floorText) { newValue in
                            if let newFloor = Int(newValue) {
                                floor = newFloor
                            }
                        }
                    Picker("Gender", selection: $selectedGender) {
                        ForEach(genderOptions, id: \.self) { gender in
                            Text(gender)
                        }
                    }

                }

                Section {
                    Button(action: submitBathroom) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Add Bathroom")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationBarTitle("Add A Bathroom", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var isFormValid: Bool {
        !bathroomName.isEmpty &&
        !buildingName.isEmpty &&
        !floorText.isEmpty &&
        Int(floorText) != nil
    }

    @MainActor
    func submitBathroom() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                try await FirestoreManager.shared.addBathroom(
                    name: bathroomName,
                    buildingName: buildingName,
                    floor: floor,
                    latitude: location.latitude,
                    longitude: location.longitude,
                    gender: selectedGender
                )
                isLoading = false
                onBathroomAdded()
                presentationMode.wrappedValue.dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}
