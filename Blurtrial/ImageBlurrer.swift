//
//  ImageBlurrer.swift
//  Blurtrial
//
//  Created by ekbana on 9/1/20.
//  Copyright © 2020 ekbana. All rights reserved.
//

import Vision
import CoreImage
import UIKit

final class ImageBlurrer {
    
    private static let hexagonalFilter = CIFilter(name: "CIPixellate")
    private static let filter = CIFilter(name: "CIPixellate")
    private static var sequenceHandler = VNSequenceRequestHandler()
    private static let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyLow])
    private static var context: CIContext!
    
    
    static func blurImage(imageToBlur: UIImage, completion: @escaping(UIImage) ->()) {
        
        
        let image = imageToBlur
        let ciImage = CIImage.init(image: image)!
        context = CIContext(options: [CIContextOption.useSoftwareRenderer: true, CIContextOption.highQualityDownsample: false, CIContextOption.priorityRequestLow: false])
        let firstOutput = blurUsingCI(inputCIImage: ciImage)
        self.findFaces(inputCIImage: firstOutput, inputUIImage: image) { (ciImageOutput) in
            
            let finalImage =  UIImage.init(cgImage: ImageBlurrer.context.createCGImage(ciImageOutput, from: ciImage.extent)!)
            context = nil
            completion(finalImage)
        }
       
    }
    
    static private func blurUsingCI(inputCIImage: CIImage) -> CIImage {
        var inputImage = inputCIImage
        if let faces = (faceDetector?.features(in: inputImage)) {
            if faces.count == 0 {
                return inputImage
            }
            for face in faces {
                let faceImage = inputImage.cropped(to: face.bounds)
                filter?.setValue(faceImage, forKey: kCIInputImageKey)
                filter?.setValue(CIVector(cgRect: face.bounds), forKey: kCIInputCenterKey)
                let pixeletedSize = face.bounds.width / 10
                filter?.setValue(pixeletedSize < 10 ? 10 : pixeletedSize, forKey: kCIInputScaleKey)
                let outputImage = filter?.outputImage
                inputImage = outputImage?.composited(over: inputImage) ?? inputCIImage
            }
            return inputImage
        }
        return inputImage
    }
    
    static private func findFaces(inputCIImage: CIImage, inputUIImage: UIImage, completion: @escaping (CIImage) -> ()) {
        var outputImage = inputCIImage
        let request = VNDetectFaceRectanglesRequest { (req, err) in
            if let err = err {
                debugPrint("Failed to detect faces", err)
                return
            }
            var inputImage = inputCIImage
            if req.results?.count == 0 {
                debugPrint("No faces")
            } else {
            req.results?.forEach{(res) in
                guard let faceObservation = res as? VNFaceObservation else { return }
                let facesPoint = self.convert(boundingBox: faceObservation.boundingBox, to: inputUIImage)
                let faceCenter = CIVector(cgRect: facesPoint)
                let faceImage = inputImage.cropped(to: facesPoint)
                ImageBlurrer.hexagonalFilter?.setValue(faceImage, forKey: kCIInputImageKey)
                ImageBlurrer.hexagonalFilter?.setValue(faceCenter, forKey: kCIInputCenterKey)
                let pixeletedSize = facesPoint.width / 10
                ImageBlurrer.hexagonalFilter?.setValue(pixeletedSize < 10 ? 10 : pixeletedSize, forKey: kCIInputScaleKey)
                let outputImage = ImageBlurrer.hexagonalFilter?.outputImage
                inputImage = outputImage?.composited(over: inputImage) ?? inputCIImage
            }
            outputImage = inputImage
            } }
        DispatchQueue.global(qos: .userInteractive).async {
            let handler = VNImageRequestHandler(ciImage: inputCIImage, options: [:])
            do {
                try handler.perform([request])
                completion(outputImage)
            } catch let reqError {
                debugPrint("Error is: ", reqError)
            }
        }
        
        
        
        
    }
    static private func convert(boundingBox: CGRect, to positionInImage: UIImage) -> CGRect {
        var rect = CGRect()
        let imageHeight = boundingBox.size.height * positionInImage.size.height
        let imageWidth = boundingBox.size.width * positionInImage.size.width
        let imageTopX = (boundingBox.origin.x) * positionInImage.size.width
        let imageTopY = (boundingBox.origin.y) * positionInImage.size.height
        
        rect.origin = CGPoint(x: imageTopX, y: imageTopY)
        rect.size = CGSize(width: imageWidth, height: imageHeight)
        
        return rect
    }
    
}
