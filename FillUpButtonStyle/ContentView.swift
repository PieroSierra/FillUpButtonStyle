//
//  ContentView.swift
//  FillUpButtonStyle
//
//  Created by Piero Sierra on 03/01/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var buttonText = "Press and hold button"
    @State private var showRipple: Int = 0
    
    var body: some View {
        ZStack {
            /// Surface to demonstrate Ripple effect
            Rectangle()
                .fill(Color.blue.opacity(0.8))
                .cornerRadius(50)
            
            VStack {
    
                Text("Simple button with press effect:").padding()
                
                /// Simple grow button
                Button (action: {
                    /// Define action here
                }) {
                    HStack {
                        Image(systemName: "hand.thumbsup.circle.fill")
                            .font(.title)
                        Text("Simple grow button!")
                    }
                }
                .buttonStyle(GrowingButtonStyle())
                
                Text("Button with press-and-hold effect:").padding().padding(.top, 50)
                
                /// Fill Up Button that fills as you press-and-hold
                Button(action: {
                    /// Define action here
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                        Text(buttonText)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(FillUpButtonStyle(
                    buttonText: $buttonText,
                    onComplete: { _, textBinding in
                        showRipple += 1
                        textBinding.wrappedValue = "Button complete!"
                    } ))
            }
        }
        .padding()
        .foregroundColor(.white)
        /// Ripple modifer.  Can be applied to any view. The CGPoint defines the center of the waves
        .modifier(RippleEffect(at: CGPoint(
            x: UIScreen.main.bounds.width / 2,
            y: UIScreen.main.bounds.height / 2 + 70), trigger: showRipple, amplitude: -22, frequency: 15, decay: 4, speed: 600))
    }
}

#Preview {
    ContentView()
}
