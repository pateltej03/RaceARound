//
//  HomeViewModel.swift
//  RaceARound
//
//  Created by Tej Patel on 08/11/24.
//

import Foundation

class HomeViewModel: ObservableObject {
    @Published var username: String = "User1"
    @Published var totalLaps : Int = 3
    @Published var selectedCar: CarModel? = nil
    @Published var selectedTrack: TrackModel? = nil
    @Published var cars: [CarModel] = []
    @Published var tracks: [TrackModel] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var selectedLapCount: Int = 3
    
    var leaderboardViewModel: LeaderboardViewModel {
        LeaderboardViewModel(entries: leaderboard)
    }
    
    var trackPlacementViewModel: TrackPlacementViewModel {
        let vm = TrackPlacementViewModel()
        vm.username = username
        vm.selectedCar = selectedCar
        vm.selectedTrack = selectedTrack
        vm.totalLaps = selectedLapCount
        vm.onFastestLapRecorded = { [weak self] fastestLap in
            self?.addFastestLapToLeaderboard(from: fastestLap)
        }
        return vm
    }
    
    func addFastestLapToLeaderboard(from entry: LeaderboardEntry) {
        leaderboard.append(entry)
        leaderboard.sort(by: { $0.lapTime < $1.lapTime })
        if leaderboard.count > 10 {
            leaderboard = Array(leaderboard.prefix(10))
        }
        saveLeaderboardToJSON()
    }
    
    private func saveLeaderboardToJSON() {
        let fileName = "GameData.json"
        guard let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) else {
            print("Failed to locate file path for JSON.")
            return
        }
        
        do {
            
            let updatedRootModel = RootModel(leaderboard: leaderboard, cars: cars, tracks: tracks)
            
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(updatedRootModel)
            
            
            try data.write(to: fileURL)
            print("Leaderboard successfully saved to \(fileURL)")
        } catch {
            print("Failed to save leaderboard to JSON: \(error)")
        }
    }
    
    init() {
        loadDataFromJSON()
        if let firstCar = cars.first {
            selectedCar = firstCar
        }
        if let firstTrack = tracks.first {
            selectedTrack = firstTrack
        }
        
    }
    
    private func loadDataFromJSON() {
        guard let url = Bundle.main.url(forResource: "GameData", withExtension: "json") else {
            print("JSON file not found.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 
            let rootModel = try decoder.decode(RootModel.self, from: data)
            
            self.leaderboard = rootModel.leaderboard
            self.cars = rootModel.cars
            self.tracks = rootModel.tracks
            
            
            print("Loaded \(self.cars.count) cars and \(self.tracks.count) tracks from JSON.")
            //            print(self.leaderboard)
        } catch {
            print("Failed to decode JSON: \(error)")
        }
    }
}
