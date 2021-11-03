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
       var ppg = [Float] (repeating :0.0, count:600)
       var pos = 0
       var detector:CIDetector! = nil
       let bridge = OpenCVBridge()
    
    // to store the cameraView
    @IBOutlet weak var graphView: UIImageView!
    
        lazy var graph:MetalGraph? = {
            return MetalGraph(mainView: self.view)
        }()
    
    
    
    
       //MARK: ViewController Hierarchy
       override func viewDidLoad() {
           super.viewDidLoad()
           
           
           //Adding graph to display PPG signal
           graph?.addGraph(withName: "ppg",
                     shouldNormalize: false,
                     numPointsInGraph: 600)
           
           self.view.backgroundColor = nil
           
           //init Video Analgesic and display camera on screen
           self.videoManager = VideoAnalgesic(mainView: self.graphView)
           self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
           
           //start video processing
           self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)
           
           if !videoManager.isRunning{
               videoManager.start()
           }
           
           Timer.scheduledTimer(timeInterval: 0.05, target: self,
                       selector: #selector(self.updateGraph),
                       userInfo: nil,
                       repeats: true)
       
       }
       
       //MARK: Process image output
       func processImageSwift(inputImage:CIImage) -> CIImage{
           
       
   
           var retImage = inputImage
           
           
           self.bridge.setTransforms(self.videoManager.transform)
           self.bridge.setImage(retImage,
                                withBounds: retImage.extent, //whole image, not bounds of a face
                                andContext: self.videoManager.getCIContext())
           
           self.ppg[pos] = Float(self.bridge.processFinger())
           self.pos = (self.pos + 1) % 600
           
           
           
           retImage = self.bridge.getImageComposite()
           //processBool will store the bool to know if there is a finger over the light
           let processBool = self.bridge.fingerOverLight()
           
           //if the finger is over the light, turn on the light
           if(processBool == true){
               self.videoManager.toggleFlash()
           }
 
           return retImage
       }
       
       //MARK: Setup Face Detection

       
    @IBAction func flash(_ sender: Any) {
        self.videoManager.toggleFlash()
    }
    
              
       //MARK: Convenience Methods for UI Flash and Camera Toggle
    //function to update graph for PPG signal
    @objc
       func updateGraph(){
           self.graph?.updateGraph(
            data: self.ppg,
               forKey: "ppg"
           )

       }
       

}
