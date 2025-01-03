//
//  FillUpButtonStyle.swift
//  FillUpButtonStyle
//
//  Created by Piero Sierra on 03/01/2025.
//

import Foundation
import SwiftUI
//import WebKit
import AVFoundation
import SceneKit


/// HEX color code extension
extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

/// Define custom colors
extension Color {
    static let grayBackground: Color = Color(hex: 0xaaaaaa)
    static let accentColor: Color = Color(hex: 0x86fc1e)
}

/// Define button buildup and release sounds
enum SoundScape: String {
    case buildup = "Cinematic Riser Sound Effect"
    case release = "TikTok Boom Bling Sound Effect"
}

/// Simple growing button style (grows when pressed)
struct GrowingButtonStyle: ButtonStyle {
    @State private var scale: CGFloat = 0.6
    @State private var wasPressed: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .frame(minHeight: 30)
            .padding(EdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20))
            .background(Color.accentColor.mix(with: .white, by: wasPressed ? 0.5 : 0.0))
            .foregroundStyle(.black)
            .clipShape(Capsule())
            .scaleEffect(wasPressed ? 0.9 : scale)
            .animation(.spring(response: 0.2), value: wasPressed)
            .onAppear {
                scale = 0.6
                withAnimation(.bouncy) { scale = 1.15 }
                withAnimation(.bouncy.delay(0.25)) { scale = 1 }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        wasPressed = true
                    }
                    .onEnded { _ in
                        wasPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            wasPressed = false
                        }
                    }
            )
    }
}

struct ViewPositionKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

/// FillUp Buton Style - fills up when held, with haptic feedback and sound
struct FillUpButtonStyle: ButtonStyle {
    @Binding var buttonText:String
    var onComplete: ((CGPoint, Binding<String>) -> Void)? = nil
    
    @State private var fillAmount: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var isPressed: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @State private var isCompleted: Bool = false
    @State private var currentTimer: Timer?
    @State private var scheduledTasks: [DispatchWorkItem] = []
    @State private var completionTask: DispatchWorkItem?
    private let fillDuration: Double = 1.2
    private let maxScale: CGFloat = 1.2
    @State private var buttonPosition: CGPoint = .zero
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .frame(minHeight: 30)
            .padding(EdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20))
            .background(
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Base color
                        Color.white
                        // Fill color that animates
                        Color.accentColor.frame(width: geometry.size.width * fillAmount)
                    }
                }
            )
            .foregroundStyle(.black)
            .clipShape(Capsule())
            .scaleEffect(scale)
            .offset(x: shakeOffset)
            .background(
                GeometryReader { geometry in
                    Color.clear // Using clear color to not affect visuals
                        .preference(key: ViewPositionKey.self, value: geometry.frame(in: .global))
                        .onPreferenceChange(ViewPositionKey.self) { frame in
                            buttonPosition = CGPoint(
                                x: frame.midX,
                                y: frame.midY
                            )
                        }
                }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPressed && !isCompleted {
                            startFillAnimation()
                        }
                    }
                    .onEnded { value in
                        if !isCompleted {
                            cancelFillAnimation()
                        }
                    }
            )
    }
    
    private func startFillAnimation() {
        /// Cancel any existing tasks first
        cancelAllTasks()
        
        isPressed = true
        
        /// Play completion sound
        playSound(named: SoundScape.buildup.rawValue)
        
        /// Start with smaller scale
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
        }
        
        /// Gradually increase scale during fill
        withAnimation(.linear(duration: fillDuration)) {
            fillAmount = 1.0
            scale = 1.1
        }
        
        /// Start shake animation
        withAnimation(.linear(duration: 0.05).repeatForever()) {
            shakeOffset = 2
        }
        
        /// Alternate shake direction
        currentTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if !isPressed || isCompleted {
                timer.invalidate()
                return
            }
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = shakeOffset == 2 ? -2 : 2
            }
        }
        
        /// Schedule haptic feedback
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        
        /// Schedule multiple haptic pulses
        scheduledTasks = []
        for i in 0...30 {
            let task = DispatchWorkItem {
                if isPressed && !isCompleted {
                    let intensity = min(1.0, Double(i) / 20.0)
                    feedbackGenerator.impactOccurred(intensity: intensity)
                }
            }
            scheduledTasks.append(task)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * (fillDuration/30), execute: task)
        }
        
        /// Schedule completion events
        completionTask = DispatchWorkItem {
            if isPressed {
                finishButton()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + fillDuration, execute: completionTask!)
    }
    
    private func cancelAllTasks() {
        currentTimer?.invalidate()
        currentTimer = nil
        scheduledTasks.forEach { $0.cancel() }
        scheduledTasks.removeAll()
        completionTask?.cancel()
        completionTask = nil
        audioPlayer?.stop()
    }
    
    private func cancelFillAnimation() {
        isPressed = false
        cancelAllTasks()
        withAnimation(.spring(response: 0.3)) {
            fillAmount = 0
            scale = 1.0
            shakeOffset = 0
        }
    }
    
    private func finishButton() {
        isCompleted = true
        isPressed = false
        
        /// Play completion sound
        playSound(named: SoundScape.release.rawValue)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = maxScale
            shakeOffset = 0
            fillAmount = 1.0
        }
        
        /// Final success haptic
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)
        
        onComplete?(buttonPosition, $buttonText)  // Pass the binding back to caller, so the button text can be changed on completion
        
        /// Set final state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3)) {
                scale = 1.0
            }
        }
    }
}

private var audioPlayer: AVAudioPlayer?

func playSound(named soundName: String, fileExtension: String? = nil) {
    /// Try with provided extension first, then try common audio extensions
    let extensions = fileExtension.map { [$0] } ?? ["wav", "mp3"]
    
    /// Find first matching audio file
    let audioPath = extensions.lazy
        .compactMap { ext in
            Bundle.main.path(forResource: soundName, ofType: ext)
        }
        .first
    
    guard let path = audioPath else {
        print("❌ Sound file not found for \(soundName) with extensions: \(extensions)")
        return
    }
    
    let url = URL(fileURLWithPath: path)
    
    do {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
        
        guard let player = audioPlayer else {
            print("❌ audioPlayer is nil after creation")
            return
        }
        
        player.play()
        
    } catch {
        print("❌ Could not create audio player: \(error)")
    }
}
