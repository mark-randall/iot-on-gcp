//
//  ContentView.swift
//  iot
//
//  Created by Mark Randall on 6/8/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import SwiftUI

// MARK: - StatusAttributeView

struct StatusAttributeView: View {
    
    let data: StatusViewModelData.StatusAttributeData
    let editTapped: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Text(data.label)
            Text(data.value)
            Spacer()
            if data.isEditable {
                Button("Edit", action: editTapped)
                .accentColor(.blue)
            }
            if data.localUpdatePending {
                Button(action: {}) {
                    Image(systemName: "info.circle")
                }
                .accentColor(.red)
            }
        }
    }
}

// MARK: - StatusView

struct StatusView: View {
        
    // TODO: How can a @ObservedObject be a protocol
    @ObservedObject var viewModel: StatusViewModel = StatusViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    VStack {
                        Spacer(minLength: 100)
                        Button(action: { self.viewModel.apply(.actionButtonTapped(self.viewModel.state.actionButtonStatus)) }) {
                            Text(viewModel.state.actionButtonStatus.label)
                        }
                        .disabled(!viewModel.state.actionButtonStatus.isEnabled)
                        Spacer(minLength: 100)
                        List {
                            Section(header: Text("Status")) {
                                ForEach(viewModel.state.attributes) { attributedData in
                                    StatusAttributeView(data: attributedData) {
                                        self.viewModel.apply(.attributedEditTapped(attributedData))
                                    }
                                }
                            }
                            Section(header: Text("Schedule")) {
                                ForEach(viewModel.state.scheduledRunTimes) { scheduled in
                                    Text(scheduled.time)
                                }
                                Button(action: { self.viewModel.apply(.addScheduledRunTimeButtonTapped) }) {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text("Schedule to run")
                                    }
                                }
                            }
                       }
                   }
                }
                ActivityIndicatorOverlay(isVisible: self.$viewModel.isLoading)
            }
            .navigationBarTitle(Text(viewModel.title), displayMode: .inline)
            .navigationBarItems(trailing:
                HStack {
                    ForEach(viewModel.state.leftBarButtonItems) { navItem in
                        Button(navItem.label) {
                            self.viewModel.apply(.navBarItemTapped(navItem))
                        }
                    }
                }
            )
            .sheet(item: $viewModel.sheetNavigation) { self.navigation(for: $0) }
            .alert(item: $viewModel.alert) { self.alert(for: $0) }
        }
        .onAppear(perform: { self.viewModel.apply(.onAppear) })
    }
    
    init() {
        // TODO: support in a non global manner
        UITableView.appearance().tableFooterView = UIView()
    }

    @State private var selected: String?
    
    // Return View for Screen
    private func navigation(for navigation: ScreenData) -> AnyView {
        
        switch navigation {
        case .auth:
            return AnyView(AuthView())
        case .editAttribute(let attribute, let options):
            return AnyView(
                SelectView(title: attribute.label, options: options, value: attribute.value) {
                    self.viewModel.apply(.attributeUpdated(attribute, newValue: $0))
                }
            )
        case .scheduleRunTime:
            return AnyView(
                ScheduleRunTimeView(selected: { (date) in self.viewModel.apply(.scheduleRunTimeSelected(date)) }, cancelled: { self.viewModel.apply(.dismissSheet) })
            )
        }
    }
    
    // Return Alert for AlertData
    private func alert(for item: AlertData) -> Alert {
        Alert(title: Text(item.title ?? ""), message: Text(item.message))
    }
}

// MARK: - PreviewProvider

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        StatusView()
    }
}
