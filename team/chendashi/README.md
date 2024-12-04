# HW04B

## Pull Request
[PR #66](https://github.com/ucsb-cs184-f24/team02-bathroom/pull/66)

## Overall Structure
This update introduces enhancements to bathroom markers by changing the original marker to circle/circle.fill marker, and dynamically changing their background color based on their rating, with custom color saturation + brightness adjustments.

### Key Changes

1. **State Variables for Best and Worst Bathrooms**
    Added two `@State` variables initialized when loading bathrooms from Firebase:  
   ```swift
   @State private var worstBathroomIDs: Set<String> = []
   @State private var bestBathroomIDs: Set<String> = []
   ```
2. **Identifying Best and Worst Bathrooms**
   Bathrooms are enumerated during the loading phase to find the minimum and maximum average ratings, and their IDs are added to the state variables:
```swift
if let minRating = bathrooms.map({ $0.averageRating }).min() {
if let maxRating = bathrooms.map({ $0.averageRating }).max() {
```
3. **Dynamic Marker Coloring**
The marker background color changes based on whether a bathroom is in the best or worst group:
```swift
private var markerColor: Color {
.fill(markerColor)
```
4. **Custom Color Modifier**
The system color can now adjust their saturation and brightness:
```swift
extension Color {
    func adjustBrightness(_ amount: Double) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        brightness += CGFloat(amount)
        brightness = max(min(brightness, 1.0), 0.0)
        return Color(hue: hue, saturation: saturation, brightness: brightness, opacity: alpha)
    }

    func adjustSaturation(_ amount: Double) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        saturation += CGFloat(amount)
        saturation = max(min(saturation, 1.0), 0.0)
        return Color(hue: hue, saturation: saturation, brightness: brightness, opacity: alpha)
    }
}
```
5. **Marker Refactor**
The marker is changed to circle/circle.fill one:
```swift
Image(systemName: isSelected ? "toilet.circle.fill" : "toilet.circle")
                .font(.system(size: 24))
                .foregroundColor(markerColor)
```
### Screenshots
![IMG_6930](https://github.com/user-attachments/assets/12f58243-b4ff-453d-a1a1-f2b42af3d070)
![IMG_6931](https://github.com/user-attachments/assets/853955a7-148c-4430-978c-2d7cc176a295)

