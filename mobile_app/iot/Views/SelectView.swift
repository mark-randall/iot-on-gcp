//
//  SelectView.swift
//  iot
//
//  Created by Mark Randall on 6/10/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import SwiftUI

struct SelectView: View {

    let title: String
    let options: [String]
    var value: String? = nil
    let selected: (String) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(options) { option in
                    Button(action: { self.selected(option) }) {
                        HStack {
                            Text(option)
                            if option == self.value {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text(title), displayMode: .inline)
        }
    }
}

extension String: Identifiable {
    public var id: String { self }
}
