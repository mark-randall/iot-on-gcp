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
    
    var data: StatusViewModelData.StatusAttributeData
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Text(data.label)
            Text(data.value)
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
                   viewModel.state.map { state in
                       VStack {
                           Spacer(minLength: 100)
                           Button(action: { self.viewModel.apply(.actionButtonTapped) }) {
                               Text(state.actionButtonStatus.label)
                           }
                           .disabled(!state.actionButtonStatus.isEnabled)
                           Spacer(minLength: 100)
                           Divider()
                           List {
                               ForEach(state.attributes, content: StatusAttributeView.init(data:))
                           }
                       }
                   }
                }
                ActivityIndicatorOverlay(isVisible: self.$viewModel.isLoading)
            }
            .navigationBarTitle(Text(viewModel.title), displayMode: .inline)
            .sheet(item: $viewModel.sheetNavigation) { self.navigation(for: $0) }
            .alert(item: $viewModel.alert) { self.alert(for: $0) }
        }
        .onAppear(perform: { self.viewModel.apply(.onAppear) })
    }
    
    init() {
        // TODO: support in a non global manner
        UITableView.appearance().tableFooterView = UIView()
    }

    // Return View for Screen
    private func navigation(for navigation: ScreenData) -> some View {
        switch navigation {
        case .auth:
            return AuthView()
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
