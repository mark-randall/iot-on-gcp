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
    
    var data: StatusAttributeData
    
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
            VStack {
                viewModel.state.map { state in
                    VStack {
                        Spacer(minLength: 100)
                        Button(action: { self.viewModel.apply(.runningStatusButtonTapped) }) {
                            Text(state.runningStatus.label)
                        }
                        Spacer(minLength: 100)
                        Divider()
                        List {
                            ForEach(state.attributes, content: StatusAttributeView.init(data:))
                        }
                    }
                }
            }
            .navigationBarTitle(Text("IoT"), displayMode: .inline)
            .sheet(item: $viewModel.sheetNavigation) { self.navigationItem($0) }
        }
        .onAppear(perform: { self.viewModel.apply(.onAppear) })
    }
    
    init() {
        // TODO: support in a non global manner
        UITableView.appearance().tableFooterView = UIView()
    }

    // Return View for Navigation
    private func navigationItem(_ navigation: Navigation) -> some View {
        switch navigation {
        case .auth:
            return AuthView()
        }
    }
}

// MARK: - PreviewProvider

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        StatusView()
    }
}
