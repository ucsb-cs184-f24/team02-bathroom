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
- Some bathrooms are grouped together if they are in the same location. 
![IMG_7544](https://github.com/user-attachments/assets/eed82ec2-8480-4dc5-836a-faa04554300d)


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



![IMG_7557](https://github.com/user-attachments/assets/62831051-8328-47f1-898e-3b9669a29ee3)
![IMG_7556](https://github.com/user-attachments/assets/b4ff7535-2382-408f-b41a-ab9d99e84da1)
![IMG_7555](https://github.com/user-attachments/assets/b4f113ea-c6ab-4a5b-bdcd-ec746ca43ebc)
![IMG_7554](https://github.com/user-attachments/assets/faec3fcb-26ba-4c35-a324-3b554c8c3e28)
![IMG_7553](https://github.com/user-attachments/assets/823bb451-3b1c-458b-9dce-9e2ecfa3a464)
![IMG_7552](https://github.com/user-attachments/assets/d9041efe-c200-4714-a538-4d08b2eacf43)
![IMG_7551](https://github.com/user-attachments/assets/27de1f91-6b74-4092-9999-118c4fe0786e)
![IMG_7550](https://github.com/user-attachments/assets/b2082168-c497-4896-aa15-27a2526afc67)
![IMG_7549 2](https://github.com/user-attachments/assets/f1417221-77e2-4f65-aaa8-2ea796e3bfee)
![IMG_7548](https://github.com/user-attachments/assets/5f63331c-9b05-4d81-bfd2-6a69fe5c0f4a)
![IMG_7547](https://github.com/user-attachments/assets/ce7f0f48-becd-4e0c-9206-56dc013f8133)
![IMG_7546](https://github.com/user-attachments/assets/bb515d0d-496c-4b49-b281-9049ab7552c0)
![IMG_7545](https://github.com/user-attachments/assets/95a56afe-d1d1-44a6-ba97-5bd1312ab2a6)
![IMG_7544 2](https://github.com/user-attachments/assets/8024a9b1-5a78-4518-bd4c-a7909463ae0f)
![IMG_7543](https://github.com/user-attachments/assets/9d7f3689-7543-4996-bce8-84fdf2dbcdfe)



### FAQ
How do I create an account?
- Navigate to the login screen and select "Sign Up." Fill in the required details to register.

Can I use the app without an account?
- No, creating an account is mandatory to access features like reviews and ratings.
