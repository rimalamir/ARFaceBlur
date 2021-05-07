//
//  ViewController.swift
//  Blurtrial
//
//  Created by ekbana on 8/27/20.
//  Copyright © 2020 ekbana. All rights reserved.
//


import UIKit
import CoreImage
import Vision
class ViewController: UIViewController {
   
    var blurredImage: UIImage!
    
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = UIImage(named: "face")
        blurredImage = imageView.image!
        let startTIme = Date()
        ImageBlurrer.blurImage(imageToBlur: blurredImage) {[weak self] (finalImage) in
            guard let self = self else { return }
            DispatchQueue.main.async {[weak self] in
                guard let self = self else { return }
                self.imageView.image = finalImage
                debugPrint("Total time taken: ", Date().timeIntervalSince(startTIme))
            }
        }
    }
}
/*
    
    private func applyProcessing() {
        
        let overallStart = Date()
        let group = DispatchGroup()
        var blurredImages = [CIImage]()
        var overallUIImage = UIImage()
        let scale = imageView.bounds.height / imageView.image!.size.height
        let aspectRatio = imageView.image!.size.height / imageView.image!.size.width
        let scaledWidth = imageView.image!.size.width / scale * aspectRatio
        let scaledHeight = imageView.image!.size.height / scale * aspectRatio
        let croppedImage = resizeImage(image: imageView.image!, targetSize: CGSize(width: scaledWidth, height: scaledHeight))
//        blurredImage = croppedImage
        
        
        
        
     
//     let firstMethodStart = Date()
        let ciimage = CIImage.init(image: blurredImage)!
        let firstOutput = mySecondMethod(inputImageForBlur: ciimage)
        self.findFaces(inputImage: firstOutput) { (cimageFromOneMethod) in
            overallUIImage = UIImage.init(cgImage: self.context.createCGImage(cimageFromOneMethod, from: ciimage.extent)!)
              DispatchQueue.main.async {
                    self.imageView.image = overallUIImage
                }
            
        }
        
        
        
      /*  debugPrint("Vision method start time: ", Date())
        let _ = self.findFaces {[weak self] ciimage in
            guard let self = self else { return }
            let blurUdsa = ciimage
            debugPrint("1")
            debugPrint("First method completed in", Date().timeIntervalSince(firstMethodStart))
            blurredImages.append(blurUdsa)
            let overallCOmposite = self.mySecondMethod(outputOfFirstBlur: blurUdsa)
            overallUIImage = UIImage.init(cgImage: self.context.createCGImage(overallCOmposite, from: CIImage.init(image: self.blurredImage)!.extent)!)
            group.leave()
        } */
        
        
        
        
        /*     group.enter()
         let secondMethodStart = Date()
         debugPrint("CI method start time: ", Date())
         let secondImage = self.mySecondMethod(outputOfFirstBlur: <#CIImage#>)
         blurredImages.append(secondImage)
         debugPrint("2")
         debugPrint("Second method completed in", Date().timeIntervalSince(secondMethodStart))
         group.leave() */
        
        // notify the main thread when all task are completed
//
//        group.notify(queue: .main) {
//            print("All Tasks are done")
//            //            let combinedImage = blurredImages.last!.composited(over: blurredImages.first!)
//            /*       let firstImage = UIImage(ciImage: blurredImages.first!)
//             let lastImage = UIImage(ciImage: blurredImages.last!)
//             let totoalOutput = UIImage.init(cgImage: self.context.createCGImage(combinedImage, from: CIImage.init(image: self.blurredImage)!.extent)!) */
//            /*     self.blendFilter?.setValue(blurredImages.first!, forKey: kCIInputImageKey)
//             self.blendFilter?.setValue(blurredImages.last, forKey: kCIInputBackgroundImageKey)
//             let overallOutputBlend = self.blendFilter?.outputImage
//             let overallOutputUIImage = UIImage(ciImage: overallOutputBlend!)
//             let combinedUIImage = UIImage.init(cgImage: self.context.createCGImage(overallOutputBlend!, from: CIImage.init(image: self.blurredImage)!.extent)!)
//             overallUIImage = combinedUIImage */
//            debugPrint("OVerall time taken", Date().timeIntervalSince(overallStart))
//            self.context = nil
//
//            DispatchQueue.main.async {
//                self.imageView.image = overallUIImage
//            }
//
//        }
//
        
    /*
            let concurrentQueue = DispatchQueue(label: "com.some.concurrentQueue", attributes: .concurrent)
         
         concurrentQueue.async {[weak self] in
         guard let self = self else { return}
         let startTime = Date()
         //executable code
         self.findFaces { image in
         let secondImage = image
         debugPrint(secondImage)
         debugPrint("First method taken time: ", Date().timeIntervalSince(startTime))
         }
         }
         
         concurrentQueue.async {[weak self] in
         guard let self = self else { return}
         //executable code
         let startTime = Date()
            self.mySecondMethod(outputOfFirstBlur: CIImage.init(image: self.blurredImage)!)
            debugPrint("Second method time taken: ", Date().timeIntervalSince(startTime))
         }
         
         
         */
        
    }
    
    
    func mySecondMethod(inputImageForBlur: CIImage) -> CIImage  {
        let startTime = Date()
        var inputImage = inputImageForBlur
        guard let img = blurredImage, let ciImg = img.ciImage ?? img.cgImage.map({CIImage(cgImage: $0)}) else {
            print("no image")
            return CIImage.init(image: blurredImage)!
        }
        
        _ = ciImg
        if let faces = (faceDetector?.features(in: inputImage)){
            for face in faces {
                debugPrint("First method called")
                let faceImage = inputImage.cropped(to: face.bounds)
                
                filter?.setValue(faceImage, forKey: kCIInputImageKey)
                filter?.setValue(CIVector(cgRect: face.bounds), forKey: kCIInputCenterKey)
                let blurSize = face.bounds.width / 10
                filter?.setValue(blurSize < 10 ? 10 : blurSize, forKey: kCIInputScaleKey)
                let outputImage = filter?.outputImage
                inputImage = outputImage!.composited(over: inputImage)
            }
            debugPrint("Second method completed in: ", Date().timeIntervalSince(startTime))
            return inputImage
        } else {
            return CIImage.init(image: blurredImage)!
        }
    }
    
    func findFaces(inputImage: CIImage, completion: @escaping (CIImage) -> ()) -> UIImage {
        
        var outputImage = blurredImage
        
        
        let request = VNDetectFaceRectanglesRequest { [weak self ](req, err) in
            guard let self = self else { return }
            if let err = err {
                print("Failed to detect faces", err)
                return
            }
            print(req)
            
            
            
//            guard let img = inputImage, let ciImg = img.ciImage ?? img.cgImage.map({CIImage(cgImage: $0)}) else { return }
            var ciImage = inputImage
            req.results?.forEach({ (res) in
                debugPrint("Second method called")
                guard let faceObservation = res as? VNFaceObservation else { return }
                let facesPoint = self.convert(boundingBox: faceObservation.boundingBox, to: self.blurredImage)
                let faceCenter = CIVector(cgRect: facesPoint)//CGPoint(x: facesPoint.midX, y: facesPoint.midY)
                
                let faceImage = ciImage.cropped(to: facesPoint)
                
                /*    self.blurFilter?.setValue(faceImage, forKey: kCIInputImageKey)
                 
                 self.blurFilter?.setValue(10, forKey: kCIInputRadiusKey)
                 let outputImage = self.blurFilter?.outputImage */
                
                self.hexagonalFilter?.setValue(faceImage, forKey: kCIInputImageKey)
                
                self.hexagonalFilter?.setValue(faceCenter, forKey: kCIInputCenterKey)
                let blurSize = facesPoint.width / 10
                self.hexagonalFilter?.setValue(blurSize < 10 ? 10 : blurSize, forKey: kCIInputScaleKey)
                let finalOutputImage = self.hexagonalFilter?.outputImage
                
                ciImage = finalOutputImage!.composited(over: ciImage)
                }
                
            )
            outputImage = UIImage.init(cgImage: self.context.createCGImage(ciImage, from: CIImage.init(image: self.blurredImage)!.extent)!)
            completion(ciImage)
            
            
        }
        
        DispatchQueue.global(qos: .background).async {[weak self] in
            guard let self = self else { return }
            
            let handler = VNImageRequestHandler(ciImage: inputImage, options: [:])
            
            do {
                let startTime = Date()
                try handler.perform([request])
                debugPrint("Elapsed time-----",Date().timeIntervalSince(startTime))
                
            } catch let reqError {
                print("error is ", reqError)
            }
        }
        
        return outputImage  ?? blurredImage
        
    }
    
    private func convert(boundingBox: CGRect, to positionInImage: UIImage) -> CGRect {
        var rect = CGRect()
        let scalingFactor: CGFloat = 1 //imageView.bounds.height / (imageView.image?.size.height)!
        let imageHeight = boundingBox.size.height * positionInImage.size.height * scalingFactor
        let imageWidth = boundingBox.size.width * positionInImage.size.width * scalingFactor
        let imageTopX = (boundingBox.origin.x) * positionInImage.size.width * scalingFactor
        let imageTopY = (boundingBox.origin.y) * positionInImage.size.height * scalingFactor
        
        rect.origin = CGPoint(x: imageTopX, y: imageTopY)
        rect.size = CGSize(width: imageWidth, height: imageHeight)
        
        return rect
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
            
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    /*
     
     func processPixels(in image: UIImage, within rect: CGRect) -> UIImage? {
     var averageColor = UIColor()
     guard let inputCGImage = image.cgImage else {
     print("unable to get cgImage")
     return nil
     }
     let colorSpace       = CGColorSpaceCreateDeviceRGB()
     let width            = inputCGImage.width
     let height           = inputCGImage.height
     let bytesPerPixel    = 4
     let bitsPerComponent = 8
     let bytesPerRow      = bytesPerPixel * width
     let bitmapInfo       = RGBA32.bitmapInfo
     
     guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
     print("unable to create context")
     return nil
     }
     context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
     
     guard let buffer = context.data else {
     print("unable to get context data")
     return nil
     }
     
     let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: width * height)
     let anotherPixelBuffer = pixelBuffer
     
     /*  for row in stride(from: 0, to: height - 1, by: 10) {
     for column in stride(from: 0, to: width - 1, by: 10) {
     let offset = row * width + column
     let topdownOffset = column * height + row
     
     if row >= Int(rect.origin.y) && row <= Int(rect.origin.y + rect.height) {
     if column >= Int(rect.origin.x) && column <= Int(rect.origin.x + rect.width) {
     for i in 0 ... 10 {
     if !(offset + i < width) {
     break }
     pixelBuffer[offset + i] = addColor(leftColor: anotherPixelBuffer[offset - 1], rightColor: anotherPixelBuffer[offset + 1], topColor: anotherPixelBuffer[topdownOffset - 1], bottomColor: anotherPixelBuffer[topdownOffset + 1] )
     }
     }
     
     }
     }
     } */
     
     for row in 0 ..< Int(height) {
     for column in 0 ..< Int(width) {
     let offset = row * width + column
     let topdownOffset = column * height + row
     /* if pixels fall within the rect range*/
     if row >= Int(rect.origin.y) && row <= Int(rect.origin.y + rect.height) {
     if column >= Int(rect.origin.x) && column <= Int(rect.origin.x + rect.width) {
     
     pixelBuffer[offset] = addColor(leftColor: anotherPixelBuffer[offset - 1], rightColor: anotherPixelBuffer[offset + 1], topColor: anotherPixelBuffer[topdownOffset - 1], bottomColor: anotherPixelBuffer[topdownOffset + 1] )
     
     
     }
     
     }
     
     }
     }
     
     let outputCGImage = context.makeImage()!
     let outputImage = UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
     
     return outputImage
     } */
    /*
     
     /// Returns average color within small box
     /// - Parameters:
     ///   - buffer: buffer
     ///   - verticalOffset: boxheight
     ///   - horizontalOffset: boxwidth
     func averageColor(buffer: UnsafeMutablePointer<ViewController.RGBA32>, verticalOffset: Int, horizontalOffset: Int) {
     var red = UInt8()
     var green = UInt8()
     var blue = UInt8()
     var alpha = UInt8()
     
     for i in 0 ..< verticalOffset {
     red += buffer[i].redComponent
     green += buffer[i].greenComponent
     blue += buffer[i].blueComponent
     alpha += buffer[i].alphaComponent
     for j in 0 ..< horizontalOffset {
     red += buffer[j].redComponent
     green += buffer[j].greenComponent
     blue += buffer[j].blueComponent
     alpha += buffer[j].alphaComponent
     }
     }
     } */
    /*
     
     
     func addColor(leftColor: RGBA32, rightColor: RGBA32, topColor: RGBA32, bottomColor: RGBA32) -> RGBA32 {
     let addedRed = (leftColor.redComponent / 5 + topColor.redComponent / 5 + bottomColor.redComponent / 5 + rightColor.redComponent / 5 )
     let addedBlue = (leftColor.blueComponent / 4 + topColor.blueComponent / 4 + bottomColor.blueComponent / 4 + rightColor.blueComponent / 4)
     let addedGreen = (leftColor.greenComponent / 4 + topColor.greenComponent / 4 + bottomColor.greenComponent / 4 + rightColor.greenComponent / 4)
     let addedAlpha:UInt8 = 189 //(leftColor.alphaComponent / 4 + topColor.alphaComponent / 4 + bottomColor.alphaComponent / 4 + rightColor.alphaComponent / 4)
     let color = RGBA32(red: addedRed, green: addedGreen, blue: addedBlue, alpha: addedAlpha)
     return color
     }
     
     
     
     struct RGBA32: Equatable {
     
     private var color: UInt32
     
     var redComponent: UInt8 {
     return UInt8((color >> 24) & 255)
     }
     
     var greenComponent: UInt8 {
     return UInt8((color >> 16) & 255)
     }
     
     var blueComponent: UInt8 {
     return UInt8((color >> 8) & 255)
     }
     
     var alphaComponent: UInt8 {
     return UInt8((color >> 0) & 255)
     }
     
     init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
     let red   = UInt32(red)
     let green = UInt32(green)
     let blue  = UInt32(blue)
     let alpha = UInt32(alpha)
     color = (red << 24) | (green << 16) | (blue << 8) | (alpha << 0)
     }
     
     
     
     static let red     = RGBA32(red: 255, green: 0,   blue: 0,   alpha: 255)
     static let green   = RGBA32(red: 0,   green: 255, blue: 0,   alpha: 255)
     static let blue    = RGBA32(red: 0,   green: 0,   blue: 255, alpha: 255)
     static let white   = RGBA32(red: 255, green: 255, blue: 255, alpha: 255)
     static let black   = RGBA32(red: 0,   green: 0,   blue: 0,   alpha: 255)
     static let magenta = RGBA32(red: 255, green: 0,   blue: 255, alpha: 255)
     static let yellow  = RGBA32(red: 255, green: 255, blue: 0,   alpha: 255)
     static let cyan    = RGBA32(red: 0,   green: 255, blue: 255, alpha: 255)
     
     static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
     
     static func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
     return lhs.color == rhs.color
     }
     }
     */
}

*/
