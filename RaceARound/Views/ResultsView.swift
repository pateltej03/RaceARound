//
//  ResultsView.swift
//  RaceARound
//
//  Created by Tej Patel on 15/12/24.
//

import SwiftUI

struct ResultsView: View {
    let username: String
    let carName: String
    let trackName: String
    let lapTimes: [LeaderboardEntry]
    
    @Environment(\.dismiss) private var dismiss
    @Binding var showResultsView: Bool
    
    var body: some View {
        VStack() {
            VStack {
                Text("Race Results")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Username: \(username)")
                    .font(.headline)
                
                Text("Car: \(carName)")
                    .font(.headline)
                
                Text("Track: \(trackName)")
                    .font(.headline)
            }
            
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Lap Times")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 5)
                    
                    ForEach(lapTimes.indices, id: \.self) { index in
                        let entry = lapTimes[index]
                        HStack {
                            Text("Lap \(index + 1):")
                                .font(.body)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(entry.lapTime, specifier: "%.2f") seconds")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            Button("Back to Home") {
                dismiss()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .onDisappear {
            showResultsView = false 
        }
    }
}

