# Bathroom Finder Design Document

## Overview
This document outlines the design and architectural details of the Bathroom Finder application, including system architecture, team decisions, and User Experience (UX) considerations. It serves as a reference for current and future development.

### System Architecture
Architecture Diagram\
<img width="387" alt="Screenshot 2024-11-15 at 10 49 29 AM" src="https://github.com/user-attachments/assets/9a04be2f-d69b-49b8-94d8-d2642cb1ac32">

#### Explanation
Frontend (iOS App):
- Built using Swift and SwiftUI for a smooth and intuitive user interface.
- Handles user input, bathroom search, review management, and admin moderation.

Backend (Firebase):
- Firestore: Stores bathroom data, user reviews, and ratings in real time.
- Authentication: Secures user access and enables role-based permissions (user/admin).

Third-Party API:
- Google Maps API: Provides map-based navigation to bathroom locations and displays markers for user convenience.

### Team Decisions
Project Start (Week 1):
- Decided on project scope and purpose: Bathroom Finder for UCSB campus.
- Determined iOS as the platform for development.

Meeting (Week 2):
- Finalized tech stack: Swift, Firebase, and Google Maps API.
- Assigned roles for issues:

Meeting (Week 2):
- Introduced daily Slack updates to track progress and blockers.
- Decided to stop unnecessary GitHub repo reorganization and focus on functionality.

Meeting (Week 3):
- make authenification work
- Voted on adding features upload functionality (currently in progress).

Meeting (Week 4):
- make map work and location work
- make review work
- Voted on adding features upload functionality (currently in progress).

Meeting (Week 5):
- make backend to store information
- Voted on adding features upload functionality (currently in progress).


### User Experience (UX) Considerations
Task/User Flow

User Flow for Finding a Bathroom:
- Login: Users authenticate via Firebase.
- Search: Navigate to the search page to find bathrooms by name, location, or rating.
- Details: Tap on a bathroom marker or search result to view details (ratings, reviews, photos).
- Post Review: Users can leave reviews or rate their experience.

UX Design Goals
- Simplicity: Minimalist interface with clear navigation for both users and admins.
- Responsiveness: Optimize layouts for different screen sizes
- Intuitiveness: Provide clear feedback for user actions

Future Enhancements
- Add photo upload capability for bathrooms and reviews.
- Integrate filters for search results (e.g., cleanliness, accessibility).
