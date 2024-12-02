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
    @State private var floorText: String = ""
    @State private var selectedGender: String = "Unisex"
    @State private var location: CLLocationCoordinate2D
    @State private var isLoading = false
    @State private var errorMessage: String = ""
    @State private var showAlert = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?

    @State private var region: MKCoordinateRegion

    init(initialLocation: CLLocationCoordinate2D) {
        _location = State(initialValue: initialLocation)
        _region = State(initialValue: MKCoordinateRegion(
            center: initialLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
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
                    Picker("Gender", selection: $selectedGender) {
                        Text("Unisex").tag("Unisex")
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                    }

                    // Image Selection
                    Button(action: { showImagePicker = true }) {
                        HStack {
                            Image(systemName: "photo")
                            Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                        }
                    }

                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                    }
                }

                Section {
                    Button(action: addBathroom) {
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
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }

    private var isFormValid: Bool {
        !bathroomName.isEmpty &&
        !buildingName.isEmpty &&
        !floorText.isEmpty &&
        Int(floorText) != nil
    }

    private func addBathroom() {
        guard let floor = Int(floorText) else {
            errorMessage = "Please enter a valid floor number."
            showAlert = true
            return
        }

        isLoading = true

        Task {
            do {
                try await FirestoreManager.shared.addBathroom(
                    name: bathroomName,
                    buildingName: buildingName,
                    floor: floor,
                    latitude: location.latitude,
                    longitude: location.longitude,
                    gender: selectedGender,
                    image: selectedImage  // Pass the UIImage directly
                )
                await MainActor.run {
                    isLoading = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}
