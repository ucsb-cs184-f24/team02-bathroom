//
//  BathroomDetailViewController.swift
//  ucsb-bathrooms
//
//  Created by Julissa Guan on 10/19/24.
//
import SwiftUI

struct BathroomDetailView: View {
    @State private var reviewText: String = ""
    @State private var rating: Int = 3
    @State private var reviews: [Review] = []
    
    let bathroomID: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                
                Text("Bathroom: \(bathroomID)")
                    .font(.largeTitle)
                    .padding(.bottom, 10)
                
                //iamge
                Image("bathroom_placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                
                Text("Rate this Bathroom")
                    .font(.headline)
                HStack {
                    ForEach(1..<6) { star in
                        Image(systemName: star <= self.rating ? "star.fill" : "star")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(star <= self.rating ? .yellow : .gray)
                            .onTapGesture {
                                self.rating = star
                            }
                    }
                }
                .padding(.bottom, 20)
                
                Text("Comment:")
                    .font(.headline)
                TextField("Leave your thoughts here...", text: $reviewText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 20)
                
                Button(action: submitReview) {
                    Text("Submit Review")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
                
                //all other reviews
                if !reviews.isEmpty {
                    Text("Reviews:")
                        .font(.headline)
                    ForEach(reviews) { review in
                        VStack(alignment: .leading) {
                            Text(review.text)
                                .font(.subheadline)
                            HStack {
                                ForEach(1..<6) { star in
                                    Image(systemName: star <= review.rating ? "star.fill" : "star")
                                        .foregroundColor(star <= review.rating ? .yellow : .gray)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Bathroom Review")
        .onAppear {
            loadReviews()
        }
    }
    
    //save the new review locally - make it sync with backend later
    func submitReview() {
        let newReview = Review(text: reviewText, rating: rating)
        reviews.append(newReview)
        saveReviews()
        reviewText = ""
        rating = 3
    }

    func loadReviews() {
        if let savedReviews = UserDefaults.standard.array(forKey: "reviews_\(bathroomID)") as? [[String: Any]] {
            reviews = savedReviews.map { Review(text: $0["text"] as! String, rating: $0["rating"] as! Int) }
        }
    }
    
    func saveReviews() {
        let reviewData = reviews.map { ["text": $0.text, "rating": $0.rating] }
        UserDefaults.standard.set(reviewData, forKey: "reviews_\(bathroomID)")
    }
}

struct Review: Identifiable {
    var id = UUID()
    var text: String
    var rating: Int
}

struct BathroomDetailView_Previews: PreviewProvider {
    static var previews: some View {
        BathroomDetailView(bathroomID: "ILP 1st Floor")
    }
}

