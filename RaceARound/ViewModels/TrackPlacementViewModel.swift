//
//  TrackPlacementViewModel.swift
//  RaceARound
//
//  Created by Tej Patel on 08/11/24.
//

import Foundation
import RealityKit
import ARKit
import CoreMotion
import SwiftUI

class TrackPlacementViewModel: ObservableObject {
    @Published var username: String
    @Published var selectedCar: CarModel?
    @Published var selectedTrack: TrackModel?
    
    @Published var carEntity: ModelEntity?
    @Published var trackEntity: ModelEntity?
    @Published var isPlacementValid: Bool = false
    @Published var placementMessage: String = "Point your device at a flat surface to place the car. Hold Still!"
    @Published var isPlaying: Bool = false
    @Published var arView = ARView(frame: .zero)
    @Published var steeringAngle: Float = 0.0
    
    @Published var throttleTimer: Timer?
    @Published var currentSpeed: Float = 0.0
    
    @Published var lastCheckpoint: Int = 0
    @Published var currentLap: Int = 0
    @Published var totalLaps: Int
    @Published var checkpointEntities: [ModelEntity] = []
    @Published var lastLapTime: TimeInterval = 0.0
    
    @Published var showResultsView: Bool = false
    
    init(username: String = "User1", totalLaps: Int = 3) {
        self.username = username
        self.totalLaps = totalLaps
    }
    
    private var lapTimer: Timer?
    @Published var lapTimes: [LeaderboardEntry] = []
    private var lapStartTime: Date?
    
    @Published var shouldDismissView: Bool = false
    
    private var maxSpeed: Float {
        selectedCar?.maxSpeed ?? 3.0
    }
    
    private var acceleration: Float {
        selectedCar?.acceleration ?? 0.02
    }
    
    private var coastingDeceleration: Float {
        selectedCar?.coastingDeceleration ?? 0.01
    }
    
    private var brakingDeceleration: Float {
        selectedCar?.brakingDeceleration ?? 0.03
    }
    
    var motionManager = CMMotionManager()
    private let maxSteeringAngle: Float = 50.0
    private var currentOrientation: UIDeviceOrientation = .portrait
    
    var onFastestLapRecorded: ((LeaderboardEntry) -> Void)?
    
    func getFastestLapEntry() -> LeaderboardEntry? {
        lapTimes.min(by: { $0.lapTime < $1.lapTime })
    }
    
    // MARK: - PLACE CAR AND TRACK
    
    func placeCar() {
        
        shouldDismissView = false
        lapTimes.removeAll()
        
        if let existingCar = carEntity {
            existingCar.removeFromParent()
            carEntity = nil
        }
        
        placeTrack()
        
        guard let selectedCar = selectedCar else {
            placementMessage = "No car selected. Please select a car."
            return
        }
        
        let center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        
        if let result = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .horizontal).first {
            let anchor = AnchorEntity(world: result.worldTransform)
            
            carEntity = try? Entity.loadModel(named: selectedCar.ARFileName)
            carEntity?.scale = SIMD3<Float>(0.1, 0.1, 0.1)
            carEntity?.generateCollisionShapes(recursive: true)
            carEntity?.physicsBody = PhysicsBodyComponent(massProperties: .default, material: PhysicsMaterialResource.generate(friction: 0.2, restitution: 0.0), mode: .dynamic)
            carEntity?.physicsMotion = PhysicsMotionComponent()
            
            carEntity?.position = SIMD3<Float>(0, -1.4, -1)
            
            if let carEntity = carEntity {
                anchor.addChild(carEntity)
                arView.scene.addAnchor(anchor)
                placementMessage = "Car placed successfully."
                print("Car Added: \(selectedCar.name)")
            } else {
                placementMessage = "Failed to load car model."
            }
        } else {
            placementMessage = "Could not find a valid surface to place the car."
        }
    }
    
    func placeTrack() {
        
        if let existingTrack = trackEntity {
            existingTrack.removeFromParent()
            trackEntity = nil
        }
        
        guard let selectedTrack = selectedTrack else {
            placementMessage = "No track selected. Please select a track."
            return
        }
        
        let center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        
        if let result = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .horizontal).first {
            let anchor = AnchorEntity(world: result.worldTransform)
            
            trackEntity = try? Entity.loadModel(named: selectedTrack.ARFileName)
            trackEntity?.scale = SIMD3<Float>(0.2, 0.2, 0.2)
            trackEntity?.generateCollisionShapes(recursive: true)
            trackEntity?.physicsBody = PhysicsBodyComponent(massProperties: .default, material: PhysicsMaterialResource.generate(friction: 0.2, restitution: 0.0), mode: .kinematic)
            
            if let trackEntity = trackEntity {
                anchor.addChild(trackEntity)
                arView.scene.addAnchor(anchor)
                print("Track Added: \(selectedTrack.name)")
            } else {
                placementMessage = "Failed to load track model."
            }
        } else {
            placementMessage = "Could not find a valid surface to place the track."
        }
        
        setupCheckpoints()
    }
    
    // MARK: - THROTTLE, COASTING, BRAKE
    
    func applyThrottle() {
        guard let car = carEntity else { return }
        
        throttleTimer?.invalidate()
        throttleTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            
            let forwardDirection = -car.transform.matrix.columns.1
            let normalizedDirection = normalize(SIMD3<Float>(forwardDirection.x, forwardDirection.y, forwardDirection.z))
            
            
            let currentVelocity = car.physicsMotion?.linearVelocity ?? SIMD3<Float>(0, 0, 0)
            let currentSpeed = length(currentVelocity)
            
            if currentSpeed < self.maxSpeed {
                let newSpeed = currentSpeed + self.acceleration
                let motionVector = normalizedDirection * newSpeed
                car.physicsMotion?.linearVelocity = motionVector
            } else {
                let motionVector = normalizedDirection * self.maxSpeed
                car.physicsMotion?.linearVelocity = motionVector
            }
        }
    }
    
    func coasting() {
        guard let car = carEntity else { return }
        
        throttleTimer?.invalidate()
        throttleTimer = nil
        
        throttleTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            
            let forwardDirection = -car.transform.matrix.columns.1
            let normalizedDirection = normalize(SIMD3<Float>(forwardDirection.x, forwardDirection.y, forwardDirection.z))
            
            
            let currentVelocity = car.physicsMotion?.linearVelocity ?? SIMD3<Float>(0, 0, 0)
            let currentSpeed = length(currentVelocity)
            
            if currentSpeed >= 0.2 {
                let newSpeed = currentSpeed - self.coastingDeceleration
                let motionVector = normalizedDirection * newSpeed
                car.physicsMotion?.linearVelocity = motionVector
            } else {
                car.physicsMotion?.linearVelocity = .zero
                self.throttleTimer?.invalidate()
            }
        }
    }
    
    func applyBrake() {
        
        guard let car = carEntity else { return }
        
        throttleTimer?.invalidate()
        throttleTimer = nil
        
        throttleTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            
            let forwardDirection = -car.transform.matrix.columns.1
            let normalizedDirection = normalize(SIMD3<Float>(forwardDirection.x, forwardDirection.y, forwardDirection.z))
            
            let currentVelocity = car.physicsMotion?.linearVelocity ?? SIMD3<Float>(0, 0, 0)
            let currentSpeed = length(currentVelocity)
            
            var brakingDeceleration = Float(0.0)
            
            if currentSpeed > 0.75 {
                brakingDeceleration = (self.brakingDeceleration * (currentSpeed + 0.25))
            }
            else{
                brakingDeceleration = self.brakingDeceleration
            }
            
            if currentSpeed >= 0.2 {
                let newSpeed = currentSpeed - brakingDeceleration
                let motionVector = normalizedDirection * newSpeed
                car.physicsMotion?.linearVelocity = motionVector
            } else {
                car.physicsMotion?.linearVelocity = .zero
                self.throttleTimer?.invalidate()
            }
        }
        
    }
    
    // MARK: - UPDATE CAR ROTATION
    
    func updateCarRotation() {
        guard let car = carEntity else { return }
        
        var rotationDelta = (steeringAngle / maxSteeringAngle) / 15.0
        
        let currentVelocity = car.physicsMotion?.linearVelocity ?? SIMD3<Float>(0, 0, 0)
        let currentSpeed = length(currentVelocity)
        
        if currentSpeed < 0.1 {
            rotationDelta = rotationDelta * 0
        }
        else if currentSpeed < 0.5 {
            rotationDelta = rotationDelta * currentSpeed
        }
        else if currentSpeed >= 0.5{
            rotationDelta = rotationDelta * currentSpeed * 0.5
        }
        
        let position = car.position(relativeTo: nil)
        // print("Car Position: x: \(position.x), y: \(position.y), z: \(position.z)")
        
        if (position.y < -3){
            resetCarPosition()
        }
        
        validateCheckpoint(carPosition: car.position)
        
        let rotation = simd_quatf(angle: rotationDelta, axis: SIMD3<Float>(0, 0, -1))
        
        car.transform.rotation *= rotation
    }
    
    func startMonitoringDeviceTilt() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01
            motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
                guard let motion = motion, error == nil else { return }
                
                switch self.currentOrientation {
                case .landscapeLeft:
                    self.steeringAngle = Float(motion.attitude.pitch) * self.maxSteeringAngle
                case .landscapeRight:
                    self.steeringAngle = Float(-motion.attitude.pitch) * self.maxSteeringAngle
                case .portrait:
                    self.steeringAngle = Float(motion.attitude.roll) * self.maxSteeringAngle
                default:
                    self.steeringAngle = 0.0
                }
            }
        }
    }
    
    func updateOrientation() {
        let newOrientation = UIDevice.current.orientation
        if newOrientation.isValidInterfaceOrientation {
            currentOrientation = newOrientation
        }
    }
    
    // MARK: - RESET
    
    func resetCarPosition() {
        guard let car = carEntity else {
            placementMessage = "Car entity not found. Cannot reset position."
            return
        }
        
        car.position = SIMD3<Float>(0, -1.4, -1)
        
        car.transform.rotation = simd_quatf(angle: Float.pi * 0.5 , axis: SIMD3<Float>(-1, 0, 0))
        
        car.physicsMotion?.linearVelocity = SIMD3<Float>(0, 0, 0)
        car.physicsMotion?.angularVelocity = SIMD3<Float>(0, 0, 0)
        
        currentSpeed = 0.0
        steeringAngle = 0.0
        
        print("Car position reset to initial placement.")
    }
    
    func resetLapTracking() {
        lastCheckpoint = 0
        currentLap = 0
        updateCheckpointVisualsForANewLap()
    }
    
    // MARK: - CHECKPOINT
    
    func validateCheckpoint(carPosition: SIMD3<Float>) {
        guard let selectedTrack = selectedTrack else { return }
        
        guard !selectedTrack.checkpoints.isEmpty else {
            return
        }
        
        let nextCheckpointIndex = lastCheckpoint
        if nextCheckpointIndex >= selectedTrack.checkpoints.count {
            handleLapCompletion()
            return
        }
        
        let nextCheckpoint = selectedTrack.checkpoints[nextCheckpointIndex]
        
        //        Check if the car's position is within the checkpoint bounds
        //        print("Looking for checkpoint \(nextCheckpoint.id)")
        //        print("want to go between \(nextCheckpoint.inner) and \(nextCheckpoint.outer)")
        
        //        print("car position: \(carPosition.x), \(carPosition.y), \(carPosition.z)")
        
        if isPositionWithinCheckpointBounds(carPosition: carPosition, checkpoint: nextCheckpoint) {
            lastCheckpoint = nextCheckpointIndex + 1
            print("Checkpoint \(nextCheckpoint.id) reached!")
            
            print("Next Checkpoint is \(lastCheckpoint + 1)")
            
            updateCheckpointVisuals()
            
        }
    }
    
    private func isPositionWithinCheckpointBounds(carPosition: SIMD3<Float>, checkpoint: Checkpoint) -> Bool {
        
        let scale: Float = 1
        
        let xWithinBounds = carPosition.x * scale >= min(checkpoint.innerToVerify.x, checkpoint.outerToVerify.x) &&
        carPosition.x * scale <= max(checkpoint.innerToVerify.x, checkpoint.outerToVerify.x)
        let zWithinBounds = carPosition.z * scale >= min(checkpoint.innerToVerify.z, checkpoint.outerToVerify.z) &&
        carPosition.z * scale <= max(checkpoint.innerToVerify.z, checkpoint.outerToVerify.z)
        
        return xWithinBounds && zWithinBounds
    }
    
    func updateCheckpointVisuals() {
        guard let checkpoints = selectedTrack?.checkpoints else { return }
        
        for (index, checkpoint) in checkpoints.enumerated() {
            let innerIndex = index * 2
            let outerIndex = innerIndex + 1
            
            guard innerIndex < checkpointEntities.count, outerIndex < checkpointEntities.count else { continue }
            
            let innerEntity = checkpointEntities[innerIndex]
            let outerEntity = checkpointEntities[outerIndex]
            
            let material: SimpleMaterial
            
            if checkpoint.id == lastCheckpoint + 1 {
                material = SimpleMaterial(color: .green, isMetallic: false)
            } else if checkpoint.id <= lastCheckpoint {
                material = SimpleMaterial(color: .blue, isMetallic: false)
            } else {
                material = SimpleMaterial(color: .yellow, isMetallic: false)
            }
            
            innerEntity.model?.materials = [material]
            outerEntity.model?.materials = [material]
        }
    }
    
    func setupCheckpoints() {
        guard let checkpoints = selectedTrack?.checkpoints else { return }
        
        checkpointEntities = checkpoints.flatMap { checkpoint -> [ModelEntity] in
            var entities: [ModelEntity] = []
            
            let innerSphere = createCheckpointSphere(color: .yellow, position: checkpoint.innerToSee / 2)
            arView.scene.addAnchor(createAnchor(for: innerSphere))
            entities.append(innerSphere)
            
            let outerSphere = createCheckpointSphere(color: .yellow, position: checkpoint.outerToSee / 2)
            arView.scene.addAnchor(createAnchor(for: outerSphere))
            entities.append(outerSphere)
            
            print("Added checkpoint \(checkpoint.id): Inner at \(checkpoint.innerToSee), Outer at \(checkpoint.outerToSee)")
            
            return entities
        }
        
        updateCheckpointVisualsForANewLap()
    }
    
    private func createCheckpointSphere(color: UIColor, position: SIMD3<Float>) -> ModelEntity {
        let sphereRadius: Float = 0.2
        let sphereMesh = MeshResource.generateSphere(radius: sphereRadius)
        let sphereMaterial = SimpleMaterial(color: color, isMetallic: false)
        let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
        sphereEntity.position = position
        return sphereEntity
    }
    
    private func createAnchor(for entity: ModelEntity) -> AnchorEntity {
        let anchor = AnchorEntity(world: entity.position)
        anchor.addChild(entity)
        return anchor
    }
    
    func updateCheckpointVisualsForANewLap() {
        guard let checkpoints = selectedTrack?.checkpoints else { return }
        
        for (index, _) in checkpoints.enumerated() {
            let innerIndex = index * 2
            let outerIndex = innerIndex + 1
            
            guard innerIndex < checkpointEntities.count, outerIndex < checkpointEntities.count else { continue }
            
            let innerEntity = checkpointEntities[innerIndex]
            let outerEntity = checkpointEntities[outerIndex]
            
            if index == 0 {
                let material = SimpleMaterial(color: .green, isMetallic: false)
                innerEntity.model?.materials = [material]
                outerEntity.model?.materials = [material]
            } else {
                let material = SimpleMaterial(color: .yellow, isMetallic: false)
                innerEntity.model?.materials = [material]
                outerEntity.model?.materials = [material]
            }
        }
    }
    
    private func handleLapCompletion() {
        currentLap += 1
        print("Lap \(currentLap) completed!")
        
        if let lapStartTime = lapStartTime {
            let lapEndTime = Date()
            let lapTime = lapEndTime.timeIntervalSince(lapStartTime)
            
            print("Lap Time for Lap \(currentLap): \(lapTime) seconds")
            
            if let selectedCar = selectedCar, let selectedTrack = selectedTrack {
                let entry = LeaderboardEntry(
                    username: username,
                    carName: selectedCar.name,
                    trackName: selectedTrack.name,
                    lapTime: lapTime,
                    date: lapEndTime
                )
                lapTimes.append(entry)
                lastLapTime = lapTime
            }
            
        }
        
        lapStartTime = Date()
        
        lastCheckpoint = 0
        updateCheckpointVisualsForANewLap()
        
        if currentLap > totalLaps {
            
            handleRaceCompletion()
        }
    }
    
    func handleRaceCompletion() {
        print("Race Completed!")
        isPlaying = false
        resetLapTracking()
        
        lapTimer?.invalidate()
        lapTimer = nil
        
        print("All Lap Times: \(lapTimes)")
        
        DispatchQueue.main.async {
            
            self.quitGame()
        }
    }
    
    func quitGame() {
        arView.scene.anchors.removeAll()
        carEntity = nil
        trackEntity = nil
        
        isPlaying = false
        isPlacementValid = false
        steeringAngle = 0
        currentSpeed = 0
        placementMessage = "Point your device at a flat surface to place the car. Hold Still!"
        
        throttleTimer?.invalidate()
        throttleTimer = nil
        motionManager.stopDeviceMotionUpdates()
        
        resetLapTracking()
        lapTimer?.invalidate()
        lapTimer = nil
        lapStartTime = nil
        lastLapTime = 0.0
        
        showResultsView = true
        
        print("Quit Game Function Executed. All lap times and game state reset.")
    }
    
    func printCarLocation() {
        guard let carEntity = carEntity else {
            print("Car entity not found.")
            return
        }
        
        let carPosition = carEntity.position(relativeTo: nil)
        
        print("Car Position -> x: \(carPosition.x), y: \(carPosition.y), z: \(carPosition.z)")
    }
    
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var arView: ARView
    @Binding var isPlaying: Bool
    @Binding var isPlacementValid: Bool
    
    func makeUIView(context: Context) -> ARView {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.frameSemantics = []
        
        arView.session.run(config)
        
        if !isPlaying {
            let coachingOverlay = ARCoachingOverlayView()
            coachingOverlay.session = arView.session
            coachingOverlay.goal = .horizontalPlane
            coachingOverlay.activatesAutomatically = true
            
            coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
            arView.addSubview(coachingOverlay)
            
            
            NSLayoutConstraint.activate([
                coachingOverlay.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
                coachingOverlay.centerYAnchor.constraint(equalTo: arView.centerYAnchor),
                coachingOverlay.widthAnchor.constraint(equalTo: arView.widthAnchor),
                coachingOverlay.heightAnchor.constraint(equalTo: arView.heightAnchor)
            ])
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            let center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
            if let _ = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .horizontal).first {
                isPlacementValid = true
            } else {
                isPlacementValid = false
            }
        }
        
        //        arView.debugOptions = [.showPhysics]
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
