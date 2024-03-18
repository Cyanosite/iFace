//
//  Camera.swift
//  iFace
//
//  Created by Zsombor Szenyán on 15/03/2024.
//

import Foundation
import AVFoundation
import SwiftUI
import CoreML

final class DataModel: ObservableObject {
    let camera = AVCaptureVideoDataOutput()
    let delegate = VideoDataOutputDelegate()
    let queue: DispatchQueue
    let input: AVCaptureDeviceInput
    let capture_session = AVCaptureSession()
    
    init() {
        let settings: [String : Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA
                ]
        camera.videoSettings = settings
        
        input = try! AVCaptureDeviceInput(device: AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.front)!)
        
        queue = DispatchQueue(label: "ProcessCameraOutput")
        
        camera.automaticallyConfiguresOutputBufferDimensions = false
        camera.deliversPreviewSizedOutputBuffers = true
        camera.setSampleBufferDelegate(delegate, queue: queue)
        capture_session.sessionPreset = .photo
    }
    
    func startFlow(on previewLayer: AVCaptureVideoPreviewLayer) {
        delegate.previewLayer = previewLayer
        capture_session.addInput(input)
        capture_session.addOutput(camera)
        capture_session.startRunning()
    }
}

final class VideoDataOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var previewLayer = AVCaptureVideoPreviewLayer()
    let model = try! _90_7_accuracy()
    var view: ModelOutputDelegate?
    private var output = Set<String>()

    func captureOutput(_: AVCaptureOutput, didOutput: CMSampleBuffer, from: AVCaptureConnection) {
        if let pixelBuffer = didOutput.imageBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

            guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
                fatalError("Failed to get base address of pixel buffer")
            }

            guard let context = CGContext(data: baseAddress,
                                          width: CVPixelBufferGetWidth(pixelBuffer),
                                          height: CVPixelBufferGetHeight(pixelBuffer),
                                          bitsPerComponent: 8,
                                          bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue).rawValue)
            else {
                fatalError("Failed to create CGContext")
            }
            let image = context.makeImage()!.cropping(to: CGRect(x: 410, y: 195, width: 900, height: 900))!
            let resizedImage = resizeImage(image, to: CGSize(width: 178, height: 178))
            var rawPixelData = extractRGBPixels(from: resizedImage)
            // Now you have raw pixel data in the rawPixelData array
            // You can manipulate or process this data as needed
            let pointer = rawPixelData.withUnsafeMutableBufferPointer { pointer in
                return pointer.baseAddress!
            }
            let input = try! MLMultiArray(dataPointer: pointer, shape: [1, 3, 178, 178],dataType: .float32, strides: [95052, 31684, 178, 1]) { pointer in
            }

            /*for i in 0..<input.count {
                print(input[i].floatValue, terminator: ", ")
            }*/
            
            let labels = ["Attractive", "Blurry", "Chubby", "Heavy Makeup", "Male", "Oval Face", "Pale Skin", "Smiling", "Young", "Bald", "Bangs", "Black Hair", "Blond Hair", "Brown Hair", "Gray Hair", "Receding Hairline", "Straight Hair", "Wavy Hair", "Wearing Hat", "Arched Eyebrows", "Bags Under Eyes", "Bushy Eyebrows", "Eyeglasses", "Narrow_Eyes", "Big Nose", "Pointy Nose", "5 o'Clock Shadow", "Big Lips", "Double Chin", "Goatee", "Mouth Slightly Open", "Mustache", "No Beard", "Sideburns", "Wearing Lipstick", "High Cheekbones", "Rosy Cheeks", "Wearing Earrings", "Wearing Necklace", "Wearing Necktie"]
            let mlInput = _90_7_accuracyInput(x_1: input)
            let predictions = try! model.predictions(inputs: [mlInput])
            output = Set<String>()
            for i in 0..<labels.count {
                if predictions[0].var_2314[i].floatValue > 0.5 {
                    output.insert(labels[i])
                }
            }
            
            view?.updateView(with: output)
            
            // Unlock the base address of the pixel buffer
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        }
    }
    
    func resizeImage(_ image: CGImage, to newSize: CGSize) -> [UInt8] {
        let width = Int(newSize.width)
        let height = Int(newSize.height)
        var data = [UInt8](repeating: 0, count: width*height*4)
        guard let context = CGContext(data: &data,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: width * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            fatalError("Unable to create CGContext")
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: newSize))

        return data
    }
    
    func extractRGBPixels(from image: [UInt8]) -> [Float32] {
        let width = 178

        var rgbPixels = [Float32](repeating: 0, count: 3*178*178)
        
        var pixel: Int = 0
        for y in 0..<width {
            for x in 0..<width {
                let blue = image[pixel]
                let green = image[pixel + 1]
                let red = image[pixel + 2]

                rgbPixels[x*178+y]  = Float32(red) / 255.0 * 2.0
                rgbPixels[1*31684+x*178+y] = Float32(green) / 255.0 * 2.0
                rgbPixels[2*31684+x*178+y] = Float32(blue) / 255.0 * 2.0
                pixel += 4
            }
        }

        return rgbPixels
    }
}
