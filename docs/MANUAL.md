# Bathroom Finder User Manual

### Product Purpose
Bathroom Finder is a mobile application designed to help users locate the best bathrooms on the UCSB campus. The app offers reviews, ratings, and location-based navigation to ensure users have a comfortable and efficient restroom experience. This iOS application is tailored for students, faculty, staff, and campus visitors who value convenience and hygiene.

### Intended User Audience
Students: Quickly find and rate campus restrooms between classes.\
Faculty and Staff: Navigate to well-rated facilities near offices or lecture halls.\
Campus Visitors: Easily locate restrooms during events or tours.

### Table of Contents
Introduction\
Installation Guide

User Features
- Finding Bathrooms
- Posting Reviews
- Rating Bathrooms
- Managing Posts and Reviews

Admin Features
- User Management
Known Issues
FAQ
Contact and Support


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

### User Features
Finding Bathrooms
- Locate bathrooms by browsing the campus map integrated with Google Maps.
- <img width="286" alt="Screenshot 2024-11-15 at 10 26 59 AM" src="https://github.com/user-attachments/assets/c01206d0-35d4-4425-b9c3-06db5652daf1">

- Or locate the bathroom by finding the Nearest, Top Rated, and Most Used
- <img width="285" alt="Screenshot 2024-11-15 at 10 28 00 AM" src="https://github.com/user-attachments/assets/67d5563d-ce96-42a0-b3c3-2c3a35394c0f">


Posting Reviews
- Tap the "Add Review" button on any bathroom's detail page to post your feedback.
- <img width="282" alt="Screenshot 2024-11-15 at 10 28 53 AM" src="https://github.com/user-attachments/assets/923e339b-f0e7-44b3-a71b-c8e5c0200dc7">

Rating Bathrooms
- Select a star rating (1–5) to score cleanliness, accessibility, and overall experience.
Check your Posts and Reviews
- See you own posts and reviews from the "My account" section.
- <img width="283" alt="Screenshot 2024-11-15 at 10 29 46 AM" src="https://github.com/user-attachments/assets/8b743081-e392-4797-9e8e-e5360b495008">


### FAQ
How do I create an account?
- Navigate to the login screen and select "Sign Up." Fill in the required details to register.

Can I use the app without an account?
- No, creating an account is mandatory to access features like reviews and ratings.
