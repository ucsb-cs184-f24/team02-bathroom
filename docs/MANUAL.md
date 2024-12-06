# Bathroom Finder User Manual

### Product Purpose
Bathroom Finder is an intuitive mobile application designed to simplify the search for clean, accessible restrooms on the UCSB campus. With user-generated reviews, detailed ratings, and real-time location-based navigation, the app ensures that students, faculty, staff, and visitors can easily find nearby bathrooms that meet their needs. Whether you’re rushing between classes or attending a campus event, Bathroom Finder makes it easier to navigate UCSB with comfort and convenience.

### Intended User Audience
Students: Quickly find and rate campus restrooms between classes.\
Faculty and Staff: Navigate to well-rated facilities near offices or lecture halls.\
Campus Visitors: Easily locate restrooms during events or tours.


### Installation Guide
Prerequisites
- Hardware: An iOS device (iPhone/iPad) running iOS 15.0 or later.
- Software: Xcode 15 or later.
- Accounts: An Apple Developer account for deployment on physical devices.

### Steps to Install
- Clone the repository: git clone git@github.com:ucsb-cs184-f24/team02-bathroom.git
- Open the project in Xcode: ucsb-bathrooms.xcodeproj.
- Install dependencies using Swift Package Manager:
  - Firebase Authentication
  - Firebase Firestore
  - GoogleSignIn
- Select your target device (physical or simulator).
- Build and run the application.

## User Features
#### Log in
- Users will need to log in with a Google Account to begin using the app
  - <img width="297" alt="Screenshot 2024-12-06 at 11 56 45 AM" src="https://github.com/user-attachments/assets/8cd40e4b-2d19-4ceb-a401-a583d3f86305">


#### Finding Bathrooms
- Browse the Campus Map: Locate bathrooms by browsing the campus map integrated with Google Maps.
   - <img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/9d7f3689-7543-4996-bce8-84fdf2dbcdfe">
- Grouped Locations: Some bathrooms are clustered together if they are within the same building or area. Easily identify these locations on the map.
   - <img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/eed82ec2-8480-4dc5-836a-faa04554300d">
- Leaderboard Page: View the "Nearest," "Top Rated," and "Most Used" bathrooms, helping you find the best options in real time.
  - <img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/823bb451-3b1c-458b-9dce-9e2ecfa3a464"><img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/d9041efe-c200-4714-a538-4d08b2eacf43"><img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/27de1f91-6b74-4092-9999-118c4fe0786e">


#### Rate Bathrooms & Post Reviews
- After visiting a bathroom, select the facility on the map to view its details. Tap "View Details" to write a review.
  - <img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/95a56afe-d1d1-44a6-ba97-5bd1312ab2a6">
- Tap the "View Details" to navigate to the bathroom's detail page to post your feedback.
  - Logging Visits & Directions: Log your visit by clicking "Log Visit," and easily navigate to the bathroom using the "Directions" button, which opens Apple Maps.
    - <img width="261" alt="Screenshot 2024-12-06 at 11 43 46 AM" src="https://github.com/user-attachments/assets/bf38d70c-8daf-448c-aa5c-d6954fb4c0a3">
  - Favorite Bathrooms: Mark your favorite bathrooms by clicking the heart icon, making them easy to find later.
    - <img width="50" alt="Screenshot 2024-12-06 at 11 44 44 AM" src="https://github.com/user-attachments/assets/8fc3ba2f-21d3-41e6-802b-7ca795fd01c3">

- Rate the Bathroom: Give a star rating (1–5) for cleanliness, accessibility, and overall experience. Add any additional comments and click "Post Review" to share your feedback.
  - <img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/bb515d0d-496c-4b49-b281-9049ab7552c0"><img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/ce7f0f48-becd-4e0c-9206-56dc013f8133">
- User can choose to post anonymously or non-anonymously by turning on or off the "Post Anonymously" button
  - <img width="256" alt="Screenshot 2024-12-06 at 11 54 06 AM" src="https://github.com/user-attachments/assets/877e2235-4724-4cba-b486-066829284edd">
- Delete a Review: If needed, users can delete their reviews by tapping the trash can icon next to their reviews.
  - <img width="100" alt="Screenshot 2024-12-06 at 11 40 22 AM" src="https://github.com/user-attachments/assets/0258c774-c52b-43e6-8a5c-cf048db94992">
  - <img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/5f63331c-9b05-4d81-bfd2-6a69fe5c0f4a">
  

#### Add New Bathrooms
- Add a New Bathroom: To contribute to the campus map, simply click the "Add" button on the map interface.
  - <img width="84" alt="Screenshot 2024-12-06 at 11 25 28 AM" src="https://github.com/user-attachments/assets/4bcf3fbe-0d53-4f9d-9c87-1c2f716154b1">
- Fill in the Details: Provide essential information for the new restroom, such as its name, location, floor number, and gender. Once added, the bathroom will appear on the campus map
  - <img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/f1417221-77e2-4f65-aaa8-2ea796e3bfee"><img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/b2082168-c497-4896-aa15-27a2526afc67">


#### User Account Page
- Past Visits: Review all of your past bathroom visits in one place. Access a list of all the facilities you’ve rated and reviewed.
- Favorite Bathrooms: Quickly access the bathrooms you’ve marked as favorites for easy reference.
- Review History: See all reviews you've posted, and revisit any past comments you've made on specific bathrooms.
  - <img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/62831051-8328-47f1-898e-3b9669a29ee3"><img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/b4ff7535-2382-408f-b41a-ab9d99e84da1"><img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/b4f113ea-c6ab-4a5b-bdcd-ec746ca43ebc">
- Users can view other user's account page by clicking on their name and it will show their recent comments and total visits
  - <img width="200" alt="Screenshot 2024-12-06 at 11 51 17 AM" src="https://github.com/user-attachments/assets/560b0a82-0fba-4f5a-8d93-2f6b57394119">
  - <img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/faec3fcb-26ba-4c35-a324-3b554c8c3e28">




### FAQ
How do I create an account?
- Navigate to the login screen and select "Sign Up." Fill in the required details to register.

Can I use the app without an account?
- No, creating an account is mandatory to access features like reviews and ratings.
