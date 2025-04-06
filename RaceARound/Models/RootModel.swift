//
//  RootModel.swift
//  RaceARound
//
//  Created by Tej Patel on 01/12/24.
//

import Foundation

struct RootModel: Codable {
    let leaderboard: [LeaderboardEntry]
    let cars: [CarModel]
    let tracks: [TrackModel]
}
