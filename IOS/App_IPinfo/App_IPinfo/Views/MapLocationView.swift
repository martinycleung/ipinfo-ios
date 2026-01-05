import SwiftUI
import MapKit

struct MapLocationView: View {
    let latitude: Double
    let longitude: Double
    let locationName: String

    @State private var position: MapCameraPosition

    init(latitude: Double, longitude: Double, locationName: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        _position = State(initialValue: .region(region))
    }

    var body: some View {
        Map(position: $position) {
            Marker(locationName, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                .tint(.red)
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
            MapUserLocationButton()
        }
    }
}

struct MapLocationCard: View {
    let ipInfo: IPInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location", systemImage: "map")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let lat = ipInfo.latitude, let lon = ipInfo.longitude {
                MapLocationView(
                    latitude: lat,
                    longitude: lon,
                    locationName: ipInfo.city ?? ipInfo.ip ?? "Location"
                )
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    Text("Coordinates:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.4f, %.4f", lat, lon))
                        .font(.system(.body, design: .monospaced))
                }
                .font(.subheadline)
            } else {
                ContentUnavailableView(
                    "No Location Data",
                    systemImage: "location.slash",
                    description: Text("Geographic coordinates are not available for this IP address")
                )
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    MapLocationCard(ipInfo: IPInfo(
        ip: "8.8.8.8",
        city: "Mountain View",
        region: "California",
        regionCode: "CA",
        country: "US",
        countryName: "United States",
        continentCode: "NA",
        inEu: false,
        postal: "94035",
        latitude: 37.386,
        longitude: -122.0838,
        timezone: "America/Los_Angeles",
        utcOffset: "-0800",
        countryCallingCode: "+1",
        currency: "USD",
        languages: "en-US",
        asn: "AS15169",
        org: "GOOGLE",
        error: nil,
        reason: nil
    ))
    .padding()
    .background(Color(.systemGroupedBackground))
}
