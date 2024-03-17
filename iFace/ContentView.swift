//
//  ContentView.swift
//  iFace
//
//  Created by Zsombor Szenyán on 05/03/2024.
//

import SwiftUI
import PhotosUI

struct ContentView: View, ModelOutputDelegate {
    let dataModel = DataModel()
    let camera = CameraView()
    @State private var isRunning = true
    @State var text = "Hello"
    @State var attributes = Set<String>()
    var body: some View {
        camera.onAppear {
            self.startFlow()
        }.onTapGesture(count: 2, perform: toggleFlow)
            .clipShape(.circle)
        VStack {
            let attributes = attributes.sorted(by: <)
            HStack {
                ForEach(attributes[0..<attributes.count/3], id: \.self) { attribute in
                    Text(attribute).padding(.all, 5).background(Color(.blue)).clipShape(.capsule)
                }
            }
            HStack {
                ForEach(attributes[attributes.count/3..<2*attributes.count/3], id: \.self) { attribute in
                    Text(attribute).padding(.all, 5).background(Color(.blue)).clipShape(.capsule)
                }
            }
            HStack {
                ForEach(attributes[2*attributes.count/3..<attributes.count], id: \.self) { attribute in
                    Text(attribute).padding(.all, 5).background(Color(.blue)).clipShape(.capsule)
                }
            }
        }
        
    }
    
    func startFlow() {
        camera.view.session = dataModel.capture_session
        dataModel.startFlow(on: camera.view.previewLayer)
        dataModel.delegate.view = self
    }
    
    func toggleFlow() {
        if isRunning {
            dataModel.capture_session.stopRunning()
            isRunning = false
        } else {
            dataModel.capture_session.startRunning()
            isRunning = true
        }
    }
    
    func updateView(with attributes: Set<String>) {
        self.attributes = attributes
    }
}


#Preview {
    ContentView()
}
