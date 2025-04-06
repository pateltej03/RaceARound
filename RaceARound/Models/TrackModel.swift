//
//  TrackModel.swift
//  RaceARound
//
//  Created by Tej Patel on 08/11/24.
//

import Foundation

struct TrackModel: Identifiable, Codable, Hashable, Equatable {
    var id : String
    var name: String
    var ARFileName: String
    var ImageFileName: String
    var checkpoints: [Checkpoint]
}

struct Checkpoint: Identifiable, Codable, Hashable, Equatable {
    var id: Int
    var innerToSee: SIMD3<Float>
    var outerToSee: SIMD3<Float>
    var innerToVerify: SIMD3<Float>
    var outerToVerify: SIMD3<Float>
}

