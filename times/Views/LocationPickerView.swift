import SwiftUI
import CoreLocation
import MapKit

struct LocationPickerView: View {
    @Binding var locationName: String?
    @Binding var latitude: Double?
    @Binding var longitude: Double?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("場所を検索...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit { searchLocation() }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Current location button
                Button {
                    useCurrentLocation()
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                        Text("現在地を使用")
                            .font(.body)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Divider()

                // Search results
                if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { item in
                        Button {
                            selectLocation(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "不明な場所")
                                    .font(.body)
                                if let address = item.placemark.title {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                } else {
                    // Map preview
                    Map(coordinateRegion: $region, showsUserLocation: true)
                        .frame(maxHeight: .infinity)
                }
            }
            .navigationTitle("位置情報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }

    private func searchLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response {
                searchResults = response.mapItems
            }
        }
    }

    private func useCurrentLocation() {
        locationManager.requestLocation()
        if let location = locationManager.lastLocation {
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude

            // Reverse geocode
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                if let placemark = placemarks?.first {
                    locationName = [placemark.name, placemark.locality].compactMap { $0 }.joined(separator: ", ")
                } else {
                    locationName = "現在地"
                }
                dismiss()
            }
        }
    }

    private func selectLocation(_ item: MKMapItem) {
        locationName = item.name ?? "不明な場所"
        latitude = item.placemark.coordinate.latitude
        longitude = item.placemark.coordinate.longitude
        dismiss()
    }
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location failed silently
    }
}
