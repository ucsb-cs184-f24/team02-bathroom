# Design Document: Bathroom Finder

## Project Overview
The Bathroom Finder app is designed to assist users in finding the best bathrooms on the UCSB campus, ensuring a comfortable and efficient experience. The app leverages user ratings, reviews, and location-based features to provide personalized and relevant restroom suggestions. This iOS-based app is designed with two user roles: Users and Admins. Users can search, rate, and review bathrooms, while Admins moderate content to maintain a clean and respectful platform.

### Team Members
- Thienan Vu: thienanvuu
- Kendrick Lee: kendrick-lee
- Jiaqi Guan: jiaqiquan2003
- Justin Hao: haojustin
- Megumi Ondo: megumi-ondo
- Luis Bravo: Bravo-Luis
- Zheli Chen: chendashi


### Tech Stack
- Platform: iOS
- Programming Language: Swift
- Backend: Firebase (for real-time database and user authentication)
- APIs: Google Maps API (for location services)

### User Roles and Permissions
Capabilities:
- Search for bathrooms by location or browse campus facilities.
- Post new bathrooms with descriptions and details.
- Rate bathrooms using a star-based rating system.
- Write, edit, or delete their reviews of bathrooms.
- Access their user account to manage their posts and reviews.

#### Key Features
1. Bathroom Search\
Users can search bathrooms based on their current location using the Google Maps API.\
Option to browse bathrooms by campus building or facilities.\
2. Rating and Reviews\
Users can rate bathrooms on a 1–5 star scale.\
Users can leave text reviews and edit or delete their submissions.\
3. Posting Bathrooms\
Users can add new bathrooms by providing a title, location, and optional description.\
Currently working on adding photo uploads to posts.\
4. Admin Moderation\
Admins can remove inappropriate reviews or posts.\
Admins manage user accounts and can ban repeat offenders.\
Known Problems\
Photo Uploads: Photo functionality for posts is under development\
Future Improvements\
Add photo upload support for bathroom posts.




