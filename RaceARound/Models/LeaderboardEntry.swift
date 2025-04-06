//
//  LeaderboardEntry.swift
//  RaceARound
//
//  Created by Tej Patel on 08/11/24.
//

import Foundation

struct LeaderboardEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var username: String
    var carName: String
    var trackName: String
    var lapTime: Double
    var date: Date
}
