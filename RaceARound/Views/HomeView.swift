//
//  HomeView.swift
//  RaceARound
//
//  Created by Tej Patel on 08/11/24.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome \(viewModel.username), Select Your Car & Track")
                    .font(.largeTitle)
                    .padding()
                
                HStack{
                    VStack {
                        Text("Select Your Car")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        CarSelectionView(viewModel: viewModel)
                            .frame(height: 150)
                            .background(Color(red: 63 / 255, green: 63 / 255, blue: 63 / 255))
                            .cornerRadius(25)
                        
                    }
                    
                    VStack {
                        Text("Select Your Track")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        TrackSelectionView(viewModel: viewModel)
                            .frame(height: 150)
                            .background(Color(red: 63 / 255, green: 63 / 255, blue: 63 / 255))
                            .cornerRadius(25)
                        
                    }
                }
                
                HStack(spacing: 40) {
                    NavigationLink(destination: LeaderboardView(username: $viewModel.username, viewModel: viewModel.leaderboardViewModel)) {
                        Text("View Leaderboard")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    NavigationLink(destination: TrackPlacementView(username: $viewModel.username, totalLaps: $viewModel.selectedLapCount, viewModel: viewModel.trackPlacementViewModel)) {
                        Text("Start Race")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        
                    }
                    
                    VStack {
                        Text("Laps")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Picker("Laps", selection: $viewModel.selectedLapCount) {
                            ForEach(1...10, id: \.self) { lap in
                                Text("\(lap)").tag(lap)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 50)   
                    }
                    
                }
                .padding()
            }
            .padding()
        }
        
    }
}

struct CarSelectionView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        TabView(selection: $viewModel.selectedCar) {
            ForEach(viewModel.cars, id: \.id) { car in
                CarCardView(car: car, isSelected: car == viewModel.selectedCar)
                    .tag(car)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

struct CarCardView: View {
    let car: CarModel
    let isSelected: Bool
    
    var body: some View {
        HStack {
            
            Image(car.ImageFileName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 200, maxHeight: 130)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(), value: isSelected)
            
            Text(car.name)
                .font(.headline)
                .foregroundColor(isSelected ? .green : .gray)
                .padding()
            
        }
    }
}

struct TrackSelectionView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        TabView(selection: $viewModel.selectedTrack) {
            ForEach(viewModel.tracks, id: \.id) { track in
                TrackCardView(track: track, isSelected: track == viewModel.selectedTrack)
                    .tag(track)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

struct TrackCardView: View {
    let track: TrackModel
    let isSelected: Bool
    
    var body: some View {
        HStack {
            
            Image(track.ImageFileName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 200, maxHeight: 130)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(), value: isSelected)
            
            Text(track.name)
                .font(.headline)
                .foregroundColor(isSelected ? .green : .gray)
                .padding()
            
        }
    }
}


