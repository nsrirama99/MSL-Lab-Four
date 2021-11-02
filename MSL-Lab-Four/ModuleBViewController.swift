//
//  ModuleBViewController.swift
//  MSL-Lab-Four
//
//  Created by UbiComp on 10/29/21.
//

import UIKit
import Metal

class ModuleBViewController: UIViewController {

    //MARK: Class Properties
       var filters : [CIFilter]! = nil
       var videoManager:VideoAnalgesic! = nil
       let pinchFilterIndex = 2
       var detector:CIDetector! = nil
       let bridge = OpenCVBridge()
    
        
    
        lazy var graph:MetalGraph? = {
            return MetalGraph(mainView: self.view)
        }()
    
    
    @IBOutlet weak var flashButton: UIButton!
    
       //MARK: ViewController Hierarchy
       override func viewDidLoad() {
           super.viewDidLoad()
           
           
    
//           graph?.addGraph(withName: "fft",
//                     shouldNormalize: true,
//                     numPointsInGraph: self.audio.fftZoom.count)
           
           self.view.backgroundColor = nil
           
           self.videoManager = VideoAnalgesic(mainView: self.view)
           self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back) //AVCaptureDevice.Position.front
           self.videoManager.toggleFlash()
           // create dictionary for face detection
           // HINT: you need to manipulate these properties for better face detection efficiency
           
           self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)
           
           if !videoManager.isRunning{
               videoManager.start()
           }
           
//           Timer.scheduledTimer(timeInterval: 0.05, target: self,
//                       selector: #selector(self.updateGraph),
//                       userInfo: nil,
//                       repeats: true)
       
       }
       
       //MARK: Process image output
       func processImageSwift(inputImage:CIImage) -> CIImage{
           
           // detect faces <-- we're not doing this anymore
   //        let f = getFaces(img: inputImage)
   //
   //        // if no faces, just return original image
   //        if f.count == 0 { return inputImage }
   //
           var retImage = inputImage
           
           // if you just want to process on separate queue use this code
           // this is a NON BLOCKING CALL, but any changes to the image in OpenCV cannot be displayed real time
   //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { () -> Void in
   //            self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
   //            self.bridge.processImage()
   //        }
           
           // use this code if you are using OpenCV and want to overwrite the displayed image via OpenCV
           // this is a BLOCKING CALL
   //        self.bridge.setTransforms(self.videoManager.transform)
   //        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
   //        self.bridge.processImage()
   //        retImage = self.bridge.getImage()
           
           //HINT: you can also send in the bounds of the face to ONLY process the face in OpenCV
           // or any bounds to only process a certain bounding region in OpenCV
           self.bridge.setTransforms(self.videoManager.transform)
           self.bridge.setImage(retImage,
                                withBounds: retImage.extent, //whole image, not bounds of a face
                                andContext: self.videoManager.getCIContext())
           
           //self.bridge.processImage()
           self.bridge.processFinger()
           
           
           retImage = self.bridge.getImageComposite() // get back opencv processed part of the image (overlayed on original)
           
           return retImage
       }
       
       //MARK: Setup Face Detection

       
    @IBAction func flash(_ sender: Any) {
        self.videoManager.toggleFlash()
    }
    
              
       //MARK: Convenience Methods for UI Flash and Camera Toggle
    
//    @objc
//       func updateGraph(){
//           self.graph?.updateGraph(
//               data: self.audio.fftZoom,
//               forKey: "fft"
//           )
//
//       }
       

}
