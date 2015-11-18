//
//  AKScanViewController.swift
//  AKScanCodeViewController-Swift
//
//  Created by 张良 on 15/11/18.
//  Copyright © 2015年 Aston. All rights reserved.
//

import UIKit
import AVFoundation

let kScanAreadWidth : CGFloat = 300.0

class AKScanViewController: UIViewController , AVCaptureMetadataOutputObjectsDelegate{
    
    let device : AVCaptureDevice! =   AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    
    lazy var input  : AVCaptureDeviceInput! = {
        try! AVCaptureDeviceInput(device: self.device)
    }()
    
    let output : AVCaptureMetadataOutput! = AVCaptureMetadataOutput.init()
    
    let session : AVCaptureSession! = AVCaptureSession.init()
    
    lazy var preview : AVCaptureVideoPreviewLayer! = {
         let layer =   AVCaptureVideoPreviewLayer(session: self.session)
        layer.frame = self.view.bounds
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        return layer
    }()

    //扫描横线
    let line = UIImageView.init(image: UIImage(named: "line_scan"))
    
    //是否正在动画
    private var isAnimating = false
    
    //ImageViewFrame
    lazy  var imageViewFrame : CGRect = {
        let viewBounds = self.view.bounds
        let viewWidth = viewBounds.size.width
        
        let frame = CGRectMake(viewWidth/2.0 - kScanAreadWidth/2, self.view.center.y - 64/2.0 - kScanAreadWidth/2.0, kScanAreadWidth, kScanAreadWidth)
        
        return frame;
    }()
    
    //callback Block
    var  blockWithScanResult : (( txt : String? ) -> Void)?
    
    //MARK: - Life cycle
    
    /**didLoad*/
    override func viewDidLoad() {
        self.title = "二维码扫描"
        self.edgesForExtendedLayout = .None
        self.view.backgroundColor = UIColor.whiteColor()
        setupUI()
        setupCamera()
    }//End viewDidLoad
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        beginReading()
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        endReading()
    }
    
    deinit {
        print("scan VC farewel")
    }
    
    
    
    //MARK: - UISetup
    /**UIBuild*/
    func setupUI(){
        let maskColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        
        let blackView = UIView.init(frame: self.view.bounds)
        blackView.backgroundColor = maskColor
        blackView.userInteractionEnabled = false
        self.view.addSubview(blackView)
        

        
        let innerFrame = CGRectInset(self.imageViewFrame, 12, 12)
        let viewBounds = self.view.bounds

        let path = UIBezierPath(rect: viewBounds)
        let imageViewPath = UIBezierPath(roundedRect: innerFrame, cornerRadius: 5).bezierPathByReversingPath()
        path.appendPath(imageViewPath)
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.CGPath
        blackView.layer.mask = maskLayer
        

        

        let lbIntroduction = UILabel(frame: {
            var lbFrame = imageViewFrame
            lbFrame.origin.y += imageViewFrame.size.height + 10
            lbFrame.size.height = 20
            return lbFrame
        }())
        
        lbIntroduction.backgroundColor = UIColor.clearColor()
        lbIntroduction.numberOfLines = 2
        lbIntroduction.textColor = UIColor.whiteColor()
        lbIntroduction.textAlignment = .Center
        lbIntroduction.font = UIFont.systemFontOfSize(14)
        lbIntroduction.text = "将二维码放入框内，即可自动扫描"
        self.view.addSubview(lbIntroduction)
        
        let imageView = UIImageView(frame:imageViewFrame)
        imageView.image = UIImage(named: "pick_bg_scan")
        self.view.addSubview(imageView)
        
        line.frame = {
            let lineWid : CGFloat = 220;
            let  lineFrame = CGRectMake(kScanAreadWidth/2 - lineWid/2, 15, lineWid, 2.0)
            return lineFrame
            }();
        imageView.addSubview(line)
        
        
        
    }//End setupUI
    
    /**Buil Camera*/
    func setupCamera(){
        
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        
        let viewHeight : CGFloat = self.view.bounds.size.height
        let viewWidth : CGFloat = self.view.bounds.size.width
        
        let insets = CGRectMake(imageViewFrame.origin.y/viewHeight, imageViewFrame.origin.x/viewWidth, imageViewFrame.size.height/viewHeight, imageViewFrame.size.width/viewWidth)
        output.rectOfInterest = insets
        
        session.sessionPreset = AVCaptureSessionPresetHigh
        if session.canAddInput(self.input){
            session.addInput(self.input)
        }
        
        if session.canAddOutput(self.output){
            session.addOutput(self.output)
        }
        
        output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        self.view.layer .insertSublayer(self.preview, atIndex: 0)
        
//        beginReading()
        
        
    }//End setupCamera
    
    
    //MARK: - Animation Control
    
    /**startAnimating*/
    func startAnimating(){
        if isAnimating {return}
        isAnimating = true
        
        let UpDown = CABasicAnimation(keyPath: "transform.translation.y")
        UpDown.duration = 2.0
        UpDown.repeatCount = MAXFLOAT
        UpDown.removedOnCompletion = false
        UpDown.autoreverses = false
        UpDown.toValue = kScanAreadWidth - CGRectGetHeight(line.frame) - 25
        
        let scal = CABasicAnimation(keyPath: "transform.scale.x")
        scal.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        scal.duration = 0.5
        scal.repeatCount = MAXFLOAT
        scal.removedOnCompletion = false
        scal.autoreverses = true
        scal.fromValue = 0.55
        scal.toValue = 1.0
        
        let aniGroup = CAAnimationGroup()
        aniGroup.animations = [UpDown,scal]
        aniGroup.duration = 2.0
        aniGroup.repeatCount = MAXFLOAT
        line.layer .addAnimation(aniGroup, forKey: "groupAnimation")
        
    }//End startAnimating
    
    /**stopAnimation*/
    func stopAnimation(){
        if isAnimating == false { return }
        
        isAnimating = false
        line.layer.removeAllAnimations()
        line.layer.transform = CATransform3DIdentity
        
    }//End stopAnimation
    
    
    //MARK: - Session Control
    
    /**beginReading*/
    func beginReading(){
        self.startAnimating()
        if !self.session.running {
            session.startRunning()
        }
    }//End beginReading
    
    /**endReading*/
    func endReading(){
        stopAnimation()
        if session.running {
            session.stopRunning()
        }
    }//End endReading
    
    
    //MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    // captureOutput didOutputMetadataObjects
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        endReading()
        
        let metatata = metadataObjects.first
        let codeString : String? = metatata?.stringValue
        if  let nonNilString = codeString  {
            
            if let blockCallBackWithTxt = blockWithScanResult {
                blockCallBackWithTxt(txt: nonNilString)
                blockWithScanResult = nil
                self.navigationController?.popViewControllerAnimated(true)
            }
            
        }else {
            print("唔好意系，某法思别啦~ \(codeString)")
        }
    }//End captureOutput didOutputMetadataObjects
    
}
