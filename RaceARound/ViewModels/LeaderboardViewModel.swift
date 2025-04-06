//
//  LeaderboardViewModel.swift
//  RaceARound
//
//  Created by Tej Patel on 08/11/24.
//

import Foundation

class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry]
    
    init(entries: [LeaderboardEntry] = []) {
        self.entries = entries
    }
    
    func updateUsername(to newUsername: String) {

    }
}
