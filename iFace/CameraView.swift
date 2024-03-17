//
//  CameraView.swift
//  iFace
//
//  Created by Zsombor Szenyán on 15/03/2024.
//

//import Foundation
import AVFoundation
import SwiftUI
import UIKit

struct CameraView: UIViewRepresentable {
    let view = PreviewView()
    
    func makeUIView(context: Context) -> UIView {
        view.previewLayer.frame = view.bounds
        view.previewLayer.videoGravity = .resizeAspectFill
        view.contentMode = UIView.ContentMode.scaleAspectFit
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        view.previewLayer.frame = view.bounds
    }
    
    typealias UIViewType = UIView
}

class PreviewView: UIView {
    // Use a capture video preview layer as the view's backing layer.
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    // Connect the layer to a capture session.
    var session: AVCaptureSession? {
        get { previewLayer.session }
        set { previewLayer.session = newValue }
    }
}
