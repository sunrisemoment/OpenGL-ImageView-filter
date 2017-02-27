//
//  ViewController.swift
//  GLImgView
//
//  Created by Daniel Suciu on 07/12/16.
//  Copyright © 2016 Daniel Suciu. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate , UINavigationControllerDelegate , UIScrollViewDelegate{

    var imagePicker = UIImagePickerController()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var plusbutton: UIButton!
    var originalImage : UIImage!
    let openglImageView = OpenGLImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self

        self.scrollView.autoresizingMask = [UIViewAutoresizing.flexibleWidth , UIViewAutoresizing.flexibleHeight]
        scrollView.clipsToBounds = false
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        setupGestureRecognizer()
        openglImageView.frame.size = view.bounds.size
        scrollView.addSubview(openglImageView)
        
        plusbutton.layer.cornerRadius = plusbutton.frame.size.width/2
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupGestureRecognizer() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(recognizer:)))
        doubleTap.numberOfTapsRequired = 2
        self.scrollView.addGestureRecognizer(doubleTap)
    }
    
    func rotated() {

        let size =  openglImageView.frame.size
        let ratio: CGFloat = min(scrollView.frame.size.width / size.width, scrollView.frame.size.height / size.height)
        let W: CGFloat = ratio * size.width * scrollView.zoomScale
        let H: CGFloat = ratio * size.height * scrollView.zoomScale
        self.openglImageView.frame.size = CGSize(width: W, height: H)
    

    }
    
    func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        
        let touchPoint = recognizer .location(in: self.view)
        
        if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale) {
            self.scrollView.setZoomScale(self.scrollView.minimumZoomScale, animated: true)
        } else {
            let x  = (touchPoint.x - view.center.x) * 2
            let y  = (touchPoint.y - view.center.y) * 2
            self.scrollView.setContentOffset(CGPoint(x: x, y: y), animated: true)
            self.scrollView.setZoomScale(self.scrollView.maximumZoomScale/2, animated: true)
        }
        
    }
    
    @IBAction func onPlusButtonClick(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.savedPhotosAlbum){
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.savedPhotosAlbum;
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true, completion: nil)
        }

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.originalImage = fitImageToImageCropContainerSize(pickedImage)
            let ciImage = CIImage(image:fitImageToImageCropContainerSize(originalImage))
            self.scrollView.autoresizingMask = [UIViewAutoresizing.flexibleWidth , UIViewAutoresizing.flexibleHeight]
            let filter = CarnivalMirror()
            filter.inputImage = ciImage
            openglImageView.image = filter.outputImage
            
        }
        
        self.dismiss(animated: true, completion: { () -> Void in
            
        })
    }
    
    
    //MARK -- UIScrollview delegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.openglImageView
    }

    
    func fitImageToImageCropContainerSize(_ image: UIImage) -> UIImage {
        let container_width = UIScreen.main.bounds.size.width
        let container_height = UIScreen.main.bounds.size.height
        let ratio: CGFloat = container_width / container_height
        var toSize: CGSize = CGSize(width: 0, height: 0)
        
        if image.size.height > 4000 {
            toSize.height = 4000
        }
        else {
            toSize.height = image.size.height
        }
        
        toSize.width = toSize.height * ratio
        
        return image.aspectFit(toSize)
    }
    
    override func viewDidLayoutSubviews()
    {
        openglImageView.frame = view.bounds.insetBy(dx: 0, dy: 0)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle
    {
        return .lightContent
    }


}

class CarnivalMirror: CIFilter
{
    var inputImage : CIImage?
    
    var inputHorizontalWavelength: CGFloat = 10
    var inputHorizontalAmount: CGFloat = 20
    
    var inputVerticalWavelength: CGFloat = 10
    var inputVerticalAmount: CGFloat = 20
    
    let carnivalMirrorKernel = CIWarpKernel(string:
        "kernel vec2 carnivalMirror(float xWavelength, float xAmount, float yWavelength, float yAmount)" +
            "{" +
            "   float y = destCoord().y + sin(destCoord().y / yWavelength) * yAmount; " +
            "   float x = destCoord().x + sin(destCoord().x / xWavelength) * xAmount; " +
            "   return vec2(x, y); " +
        "}"
    )
    
    override var outputImage : CIImage!
    {
        if let inputImage = inputImage,
            let kernel = carnivalMirrorKernel
        {
            let arguments = [
                inputHorizontalWavelength, inputHorizontalAmount,
                inputVerticalWavelength, inputVerticalAmount]
            
            let extent = inputImage.extent
            
            return kernel.apply(
                withExtent: extent,
                roiCallback:
                {
                    (index, rect) in
                    return rect
            },
                inputImage: inputImage,
                arguments: arguments)
        }
        return nil
    }
}


