//
//  ScheduleTimeView.swift
//  iot
//
//  Created by Mark Randall on 6/12/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import SwiftUI

struct ScheduleRunTimeView: View {

    @State private var selectedDate = Date(timeIntervalSinceNow: 60)
    let selected: (Date) -> Void
    let cancelled: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Select start time:")
                DatePicker(selection: $selectedDate, in: Date()...) {
                    EmptyView()
                    
                }
                .labelsHidden()
            }
            .navigationBarTitle(Text("Schedule"), displayMode: .inline)
            .navigationBarItems(leading:
                Button(action: { self.cancelled() }) {
                    Text("Cancel")
                }, trailing:
                Button(action: { self.selected(self.selectedDate) }) {
                    Text("Save")
                }
            )
        }
    }
}
