# Bathroom Finder  

Our app will help users find the best bathroom on the UCSB campus, ensuring they have a comfortable and pleasant experience while navigating the facilities. With ratings, user reviews, and location-based features, we aim to make restroom finding easier and more efficient for everyone. This app is developed on an iOS platform. There will be two types of users, users and admins. Users can post about bathrooms, review and comment on them as they wish. Admins will manage the posts that the users make to ensure that only the appropriate ones are present.

## Members  
Thienan Vu - thienanvuu    
Kendrick Lee - kendrick-lee  
Jiaqi Guan - jiaqiquan2003  
Justin Hao - haojustin  
Megumi Ondo - megumi-ondo  
Luis Bravo - Bravo-Luis  
Zheli Chen - chendashi

## Tech Stack
- Platform: iOS
- Languages: Swift
- Backend: Firebase (for real-time database and user authentication)
- APIs: Google Maps API (for location services)

## User Roles and Permissions
There are two types of users:

### Users:
- Can search for bathrooms based on their location or by browsing campus facilities.
- Can post new bathrooms, rate existing ones, and leave reviews.
- Can edit or delete their own posts and reviews.
### Admins:
- Have all user capabilities.
- Can moderate the content, ensuring that posts and reviews adhere to community guidelines.
- Can delete inappropriate content or ban users who violate rules.
- Admins will also be responsible for managing spam or inappropriate content that might be posted, keeping the app clean and reliable for all users.


## Deployment Instructions
To deploy the Bathroom Finder app, please follow these instructions:

#### Prerequisites:
- Xcode 15 or later
- Swift 5.x
- An Apple Developer account (for device deployment)

#### Clone the Repository:
Run: git clone git@github.com:ucsb-cs184-f24/team02-bathroom.git

#### Install Dependencies:
- Open the ucsb-bathrooms.xcodeproj in Xcode.
- Ensure that all dependencies are installed, especially Firebase and Google Maps SDK.

#### Build and Run:
- Select your target device and ensure it’s connected or use the simulator.
- Click Run in Xcode to deploy to your selected device or simulator.

#### Test User Roles and Permissions:
- Sign up as a user to test bathroom posts and reviews.
- Use an admin account to verify content moderation features.
