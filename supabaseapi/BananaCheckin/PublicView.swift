//
//  PublicView.swift
//  cheakin
//
//  Created by Arnav Gupta on 9/29/25.
//

import SwiftUI

struct PublicView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Public")
                .font(.title)
        }
        .padding()
    }
}

#Preview {
    PublicView()
}
