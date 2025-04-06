//
//  LeaderboardView.swift
//  RaceARound
//
//  Created by Tej Patel on 08/11/24.
//

import SwiftUI

struct LeaderboardView: View {
    @Binding var username: String
    @ObservedObject var viewModel: LeaderboardViewModel
    
    var body: some View {
        ZStack{
            VStack {
                Spacer().frame(height: 50)
                TextField("Enter Username", text: $username, onCommit: {
                    viewModel.updateUsername(to: username)
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(EdgeInsets(top: 0, leading: 65, bottom: 0, trailing: 65))
                .background(Color(UIColor.systemGray6))
                
                List(viewModel.entries) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.username)
                            Text(entry.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text(entry.carName)
                        Spacer()
                        Text(entry.trackName)
                        Spacer()
                        Text("\(entry.lapTime, specifier: "%.2f")s")
                    }
                }.padding(EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 50))
                
            }
            .ignoresSafeArea(.all)
            .background(Color(UIColor.systemGray6))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ZStack {
                        
                        Text("Leaderboard")
                            .font(.largeTitle)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .ignoresSafeArea(.all)
        .background(Color(UIColor.systemGray6))
    }
}
