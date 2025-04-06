//
//  TrackPlacementView.swift
//  RaceARound
//
//  Created by Tej Patel on 08/11/24.
//

import SwiftUI
import RealityKit
import ARKit
import CoreMotion

struct TrackPlacementView: View {
    @Binding var username: String
    @Binding var totalLaps : Int
    @ObservedObject var viewModel: TrackPlacementViewModel
    @State private var showQuitConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            
            if !viewModel.showResultsView {
                ARViewContainer(arView: $viewModel.arView, isPlaying: $viewModel.isPlaying, isPlacementValid: $viewModel.isPlacementValid)
                    .edgesIgnoringSafeArea(.all)
            }
            if viewModel.showResultsView {
                
                ResultsView(
                    username: username,
                    carName: viewModel.selectedCar?.name ?? "Unknown Car",
                    trackName: viewModel.selectedTrack?.name ?? "Unknown Track",
                    lapTimes: viewModel.lapTimes,
                    showResultsView: $viewModel.showResultsView
                )
                .onDisappear {
                    
                    if let fastestLap = viewModel.getFastestLapEntry() {
                        viewModel.onFastestLapRecorded?(fastestLap)
                    }
                }
            } else if !viewModel.isPlaying {
                
                VStack {
                    Spacer()
                    Text(viewModel.placementMessage)
                        .font(.subheadline)
                        .foregroundColor(viewModel.isPlacementValid ? .green : .red)
                    
                    ZStack {
                        if let selectedTrack = viewModel.selectedTrack {
                            Image(selectedTrack.ImageFileName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 250)
                                .opacity(0.5)
                                .cornerRadius(25)
                        } else {
                            Text("No track selected")
                                .foregroundColor(.red)
                        }
                        
                        if let selectedCar = viewModel.selectedCar {
                            Image(selectedCar.ImageFileName)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 30)
                                .opacity(0.5)
                                .cornerRadius(8)
                            
                        } else {
                            Text("No car selected")
                                .foregroundColor(.red)
                            
                        }
                        
                    }
                    
                    Button(action: {
                        if viewModel.isPlacementValid {
                            viewModel.placeCar()
                            viewModel.isPlaying = true
                        } else {
                            viewModel.placementMessage = "Cannot place items. Try again."
                        }
                    }) {
                        Text("Place")
                            .frame(width: 100, height: 50)
                            .background(viewModel.isPlacementValid ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 10)
                    .disabled(!viewModel.isPlacementValid)
                }
            }
            
            if viewModel.isPlaying {
                VStack {
                    
                    HStack{
                        Text("Lap \(viewModel.currentLap) / \(totalLaps)").font(.title2).bold(true)
                    }
                    
                    HStack{
                        Text("Previous Lap: \(String(format: "%.3f", viewModel.lastLapTime))").font(.title2).bold(true)
                    }
                    
                    Spacer()
                    HStack {
                        Button(action: {
                            // Optional, for on button release actions
                        }) {
                            Image("brakeImage")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .contentShape(Rectangle())
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            viewModel.applyBrake()
                                        }
                                        .onEnded { _ in
                                            viewModel.coasting()
                                        }
                                )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Optional, for on button release actions
                        }) {
                            Image("throttleImage")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                        }
                        .contentShape(Rectangle())
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    viewModel.applyThrottle()
                                }
                                .onEnded { _ in
                                    viewModel.coasting()
                                }
                        )
                        
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle(viewModel.isPlaying ? "Gameplay" : viewModel.showResultsView ? "": "Place Your Car")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.isPlaying {
                    Button("End Race") {
                        showQuitConfirmation = true
                    }
                    
                } else {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing){
                if viewModel.isPlaying {
                    Button("Reset") {
                        viewModel.resetCarPosition()
                    }
                    
                }
            }
            
            // DONT DELETE DONT DELETE DONT DELETE DONT DELETE DONT DELETE
            //              USED TO GET CHECKPOINT LOCATIONS
            
            //            ToolbarItem(placement: .navigationBarTrailing){
            //                if viewModel.isPlaying {
            //                    Button("Position") {
            //                        viewModel.printCarLocation()
            //                    }
            //
            //                }
            //            }
            
        }
        .onAppear {
            
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                viewModel.updateOrientation()
            }
            
            viewModel.updateOrientation()
            viewModel.startMonitoringDeviceTilt()
            Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                if viewModel.isPlaying {
                    viewModel.updateCarRotation()
                }
            }
        }
        .onDisappear {
            viewModel.motionManager.stopDeviceMotionUpdates()
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            viewModel.arView.scene.anchors.removeAll()
            viewModel.isPlaying = false
            viewModel.isPlacementValid = false
            viewModel.throttleTimer?.invalidate()
            viewModel.throttleTimer = nil
        }
        .confirmationDialog("Are you sure you want to quit?", isPresented: $showQuitConfirmation) {
            Button("Confirm", role: .destructive) {
                viewModel.quitGame()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: viewModel.shouldDismissView) {
            if viewModel.shouldDismissView {
                dismiss()
            }
        }
    }
    
}

