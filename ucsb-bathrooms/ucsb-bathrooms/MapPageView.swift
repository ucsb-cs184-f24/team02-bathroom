import SwiftUI
import MapKit

struct MapPageView: View {
    @State private var position = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.413963, longitude: -119.848946), 
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    ))
    
    var body: some View {
        Map(position: $position)
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    MapPageView()
}
