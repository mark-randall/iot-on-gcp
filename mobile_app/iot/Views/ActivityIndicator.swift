//
//  ActivityIndicator.swift
//  iot
//
//  Created by Mark Randall on 6/10/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
    
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct ActivityIndicatorOverlay: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ActivityIndicator(isAnimating: .constant(true), style: .large)
                Spacer()
            }
            Spacer()
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.secondary.colorInvert())
        .opacity(isVisible ? 1 : 0)
    }
}
