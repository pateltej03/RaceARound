//
//  CarModel.swift
//  RaceARound
//
//  Created by Tej Patel on 08/11/24.
//

import Foundation

struct CarModel: Identifiable, Codable, Hashable, Equatable {
    var id : String
    var name: String
    var ARFileName: String
    var ImageFileName: String
    var acceleration: Float
    var coastingDeceleration: Float
    var brakingDeceleration: Float
    var maxSpeed: Float
}
