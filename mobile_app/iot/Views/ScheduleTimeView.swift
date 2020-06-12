//
//  ScheduleTimeView.swift
//  iot
//
//  Created by Mark Randall on 6/12/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import SwiftUI

struct ScheduleRunTimeView: View {

    let title: String
    @State var selectedDate = Date(timeIntervalSinceNow: 60)

    var body: some View {
        NavigationView {
            DatePicker(selection: $selectedDate, in: Date()..., displayedComponents: .date) {
                Text("Select a date")
            }
            .navigationBarTitle(Text(title), displayMode: .inline)
        }
    }
}
