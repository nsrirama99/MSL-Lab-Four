//
//  ViewController.swift
//  MSL-Lab-Four
//
//  Created by UbiComp on 10/22/21.
//


import UIKit
import AVFoundation

class ViewController: UIViewController   {

    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    let bridge = OpenCVBridge()
    
    //MARK: Size values for eyes & mouths
    //numbers were set to roughly outline the features
    let eyeSize = CGSize.init(width: 25.0, height: 25.0)
    let mouthSize = CGSize.init(width: 20.0, height: 50.0)
    
    // Variables to store the current status of facial features:
    var smiling = false
    var blink_left = false
    var blink_right = false
    
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
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
        if f.count == 0 {
            self.smiling = false
            self.blink_left = false
            self.blink_right = false
            return inputImage
        }
                
        var retImage = inputImage
        
        //where all faces and facial features are identified
        retImage = applyFiltersToFaces(inputImage: retImage, features: f)
        
        return retImage
    }
    
    //applies all filters and identifies all facial features we're interested in
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        var filterCenter = CGPoint()
        
        //for every face, apply filters and identify features
        for f in features {
            self.smiling = false
            self.blink_left = false
            self.blink_right = false
            //set where to apply basic face filter
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
            
            self.bridge.setTransforms(self.videoManager.transform)
            self.bridge.setImage(retImage,
                                 withBounds: f.bounds, // the first face bounds
                                 andContext: self.videoManager.getCIContext())
            
            self.bridge.processFace()
            retImage = self.bridge.getImageComposite()
            
            //process Mouths for face if it can be found
            //turns out, the image processing is REALLY GOOD at finding faces
            if(f.hasMouthPosition) {
                
                //check for smiling
                if (f.hasSmile) {
                    self.smiling = true
                }
                
                //identify position of face, and create a Rectangle with bounds roughly around it
                let loc = CGPoint.init(x: (f.mouthPosition.x-(mouthSize.width/2)), y: f.mouthPosition.y-(mouthSize.height/2)) //-(mouthSize.width/2) -(mouthSize.height/2)
                let rect = CGRect.init(origin: loc, size: mouthSize)
                
                //Process the image within the bounds of the mouth
                self.bridge.setImage(retImage,
                                     withBounds: rect, // the first face bounds
                                     andContext: self.videoManager.getCIContext())
                
                self.bridge.processMouth()
                retImage = self.bridge.getImageComposite()
                
            }
            
            //process each eye separately if they're found
            //left eye
            if(f.hasLeftEyePosition) {
                //check for left blink
                if (f.leftEyeClosed) {
                    self.blink_left = true
                }
                //identify position of left eye and create rectangle bounds for it
                let loc = CGPoint.init(x: f.leftEyePosition.x-(eyeSize.width/2), y: f.leftEyePosition.y-(eyeSize.height/2))
                let rect = CGRect.init(origin: loc, size: eyeSize)

                //process left eye around the bounds identified
                self.bridge.setImage(retImage,
                                     withBounds: rect,
                                     andContext: self.videoManager.getCIContext())
                
                self.bridge.processEyes()
                retImage = self.bridge.getImageComposite()
            }
            //right eye
            if(f.hasRightEyePosition) {
                //check for right blink
                if (f.rightEyeClosed) {
                    self.blink_right = true
                }

                //process right eye around the bounds identified
                let loc = CGPoint.init(x: f.rightEyePosition.x-(eyeSize.width/2), y: f.rightEyePosition.y-(eyeSize.height/2))
                let rect = CGRect.init(origin: loc, size: eyeSize)

                //process right eye around the bounds identified
                self.bridge.setImage(retImage,
                                     withBounds: rect,
                                     andContext: self.videoManager.getCIContext())
                
                self.bridge.processEyes()
                retImage = self.bridge.getImageComposite()
            }
            

            //Finally, process smiles/blinking after initial image processing has been completed
            self.bridge.setImage(retImage,
                                 withBounds: f.bounds, // the first face bounds
                                 andContext: self.videoManager.getCIContext())
            
            self.bridge.processFeatures(self.smiling, leftBlink: self.blink_left, rightBlink: self.blink_right)
            retImage = self.bridge.getImageComposite()
            
        }
        return retImage
    }
    
    //MARK: Setup Face Detection
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        // It also allows for smiling and blinking detection, that part's not really a mess though  :^)
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation,
                                   CIDetectorSmile:true,
                                CIDetectorEyeBlink:true] as [String : Any]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
   
}


