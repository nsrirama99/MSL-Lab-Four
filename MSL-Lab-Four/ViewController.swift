//
//  ViewController.swift
//  MSL-Lab-Four
//
//  Created by UbiComp on 10/29/21.
//


import UIKit
import AVFoundation

class ViewController: UIViewController   {

    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var mouthFilters : [CIFilter]! = nil
    var eyeFilters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    let bridge = OpenCVBridge()
    
    //MARK: Size values for locating eyes & mouths
    let eyeSize = CGSize.init(width: 25.0, height: 25.0)
    let mouthSize = CGSize.init(width: 20.0, height: 50.0)
    
    //MARK: Outlets in view
//    @IBOutlet weak var flashSlider: UISlider!
//    @IBOutlet weak var stageLabel: UILabel!
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
        self.setupFilters()
        
        // setup the OpenCV bridge nose detector, from file
        //self.bridge.loadHaarCascade(withFilename: "nose")
        
        self.videoManager = VideoAnalgesic(mainView: self.view)
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.front)
        
        // create dictionary for face detection
        // HINT: you need to manipulate these properties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyHigh,CIDetectorTracking:true] as [String : Any]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
    
    }
    
    //MARK: Process image output
    func processImageSwift(inputImage:CIImage) -> CIImage{
        
        // detect faces
        let f = getFaces(img: inputImage)
        
        // if no faces, just return original image
        if f.count == 0 { return inputImage }
        
        var retImage = inputImage
        
        
        retImage = applyFiltersToFaces(inputImage: retImage, features: f)
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
//        self.bridge.setTransforms(self.videoManager.transform)
//        self.bridge.setImage(retImage,
//                             withBounds: f[0].bounds, // the first face bounds
//                             andContext: self.videoManager.getCIContext())
//
//        self.bridge.processImage()
//        retImage = self.bridge.getImageComposite() // get back opencv processed part of the image (overlayed on original)
        
        return retImage
    }
    
    func setupFilters(){
        filters = []
        eyeFilters = []
        mouthFilters = []
        
        let filterPinch = CIFilter(name:"CIBumpDistortion")!
        filterPinch.setValue(1, forKey: "inputScale")
        filterPinch.setValue(75, forKey: "inputRadius")
        filters.append(filterPinch)
        
        
        let filterHole = CIFilter(name: "CIHoleDistortion")!
        filterHole.setValue(20, forKey: "inputRadius")
        eyeFilters.append(filterHole)
        
        let filterPoint = CIFilter(name: "CIVortexDistortion")!
        filterPoint.setValue(50, forKey: "inputRadius")
        mouthFilters.append(filterPoint)
    }
    
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        var filterCenter = CGPoint()
        
        for f in features {
            //set where to apply filter
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
            
//            self.bridge.setTransforms(self.videoManager.transform)
//            self.bridge.setImage(retImage,
//                                 withBounds: f.bounds, // the first face bounds
//                                 andContext: self.videoManager.getCIContext())
//
//            self.bridge.processFace()
//            retImage = self.bridge.getImageComposite()
//
            if(f.hasMouthPosition) {

                let loc = CGPoint.init(x: (f.mouthPosition.x), y: f.mouthPosition.y) //-(mouthSize.width/2) -(mouthSize.height/2)
                let rect = CGRect.init(origin: loc, size: mouthSize)

//                self.bridge.setImage(retImage,
//                                     withBounds: rect, // the first face bounds
//                                     andContext: self.videoManager.getCIContext())
//
//                self.bridge.processMouth()
//                retImage = self.bridge.getImageComposite()
                mouthFilters[0].setValue(retImage, forKey: kCIInputImageKey)
                mouthFilters[0].setValue(CIVector(cgPoint: loc), forKey: "inputCenter")
                retImage = mouthFilters[0].outputImage!
            }

            if(f.hasLeftEyePosition) {
                let loc = CGPoint.init(x: f.leftEyePosition.x, y: f.leftEyePosition.y)
                let rect = CGRect.init(origin: loc, size: eyeSize)

                eyeFilters[0].setValue(retImage, forKey: kCIInputImageKey)
                eyeFilters[0].setValue(CIVector(cgPoint: loc), forKey: "inputCenter")
                retImage = eyeFilters[0].outputImage!
//                self.bridge.setImage(retImage,
//                                     withBounds: rect,
//                                     andContext: self.videoManager.getCIContext())
//
//                self.bridge.processEyes()
//                retImage = self.bridge.getImageComposite()
            }

            if(f.hasRightEyePosition) {
                let loc = CGPoint.init(x: f.rightEyePosition.x, y: f.rightEyePosition.y)
                let rect = CGRect.init(origin: loc, size: eyeSize)

                eyeFilters[0].setValue(retImage, forKey: kCIInputImageKey)
                eyeFilters[0].setValue(CIVector(cgPoint: loc), forKey: "inputCenter")
                retImage = eyeFilters[0].outputImage!
//                self.bridge.setImage(retImage,
//                                     withBounds: rect,
//                                     andContext: self.videoManager.getCIContext())
//
//                self.bridge.processEyes()
//                retImage = self.bridge.getImageComposite()
            }
            
            
            filters[0].setValue(retImage, forKey: kCIInputImageKey)
            filters[0].setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
            retImage = filters[0].outputImage!
            //do for each filter (assumes all filters have property, "inputCenter")
//            for filt in filters{
//                let filterkeys = filt.inputKeys
//                filt.setValue(retImage, forKey: kCIInputImageKey)
//
//                if(filterkeys.contains(kCIInputCenterKey)) {filt.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")}
//                // could also manipulate the radius of the filter based on face size!
//                retImage = filt.outputImage!
//            }
        }
        return retImage
    }
    
    //MARK: Setup Face Detection
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    
//    // change the type of processing done in OpenCV
//    @IBAction func swipeRecognized(_ sender: UISwipeGestureRecognizer) {
////        switch sender.direction {
////        case .left:
////            self.bridge.processType += 1
////        case .right:
////            self.bridge.processType -= 1
////        default:
////            break
////
////        }
////
////        stageLabel.text = "Stage: \(self.bridge.processType)"
//
//    }
//
//    //MARK: Convenience Methods for UI Flash and Camera Toggle
//    @IBAction func flash(_ sender: AnyObject) {
//        if(self.videoManager.toggleFlash()){
//            self.flashSlider.value = 1.0
//        }
//        else{
//            self.flashSlider.value = 0.0
//        }
//    }
//
//    @IBAction func switchCamera(_ sender: AnyObject) {
//        self.videoManager.toggleCameraPosition()
//    }
//
//    @IBAction func setFlashLevel(_ sender: UISlider) {
//        if(sender.value>0.0){
//            let val = self.videoManager.turnOnFlashwithLevel(sender.value)
//            if val {
//                print("Flash return, no errors.")
//            }
//        }
//        else if(sender.value==0.0){
//            self.videoManager.turnOffFlash()
//        }
//    }

   
}


