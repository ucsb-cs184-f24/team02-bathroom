# HW04B

## Pull Request
[PR #66](https://github.com/ucsb-cs184-f24/team02-bathroom/pull/66)

## Overall Structure
This update introduces enhancements to bathroom markers by dynamically changing their background color based on their rating.

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
### Screenshots are available in pull request
