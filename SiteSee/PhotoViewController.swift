//
//  PhotoViewController.swift
//  SiteSee
//
//  Created by Tom Lai on 3/26/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import UIKit
import SafariServices
class PhotoViewController: UIViewController {
    var image : Image!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var effectView: UIVisualEffectView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var attributionLabel: UILabel!
    @IBOutlet weak var attribution: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    func attributionStr(flickrLicense: Int, ownerName: String)->String {
        let licenseName = Flickr.Constants.licenseName(flickrLicense)
        if flickrLicense == 7 || flickrLicense == 8 {
            return "\(licenseName)."
        } else {
        return "This photo is made available under a \(licenseName!) license."
        }
    }
    
    @IBAction func tapped(sender: UITapGestureRecognizer) {
        let sfv = SFSafariViewController(URL: NSURL(string:image.flickrPageUrl!)!)
        navigationController?.pushViewController(sfv, animated: true)
    }
    override func viewDidLoad() {

        super.viewDidLoad()
        
        guard let uuid = image.uuid else {
            print("image has no uuid")
            return
        }
        
        imageView.image = UIImage(contentsOfFile: Image.imgPath(uuid))
        
        scrollView.delegate = self;
        setupAttributions()
        loadFullSizeImage()
    }
    
    override func viewDidLayoutSubviews() {
        updateMinZoomScaleFor(scrollView.bounds.size)
    }
    private func updateConstraintsForSize(size: CGSize) {
        
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
        
        view.layoutIfNeeded()
    }
    func updateMinZoomScaleFor(size: CGSize) -> Void {
        let minXScale = size.width / imageView.bounds.width
        let minYScale = size.height / imageView.bounds.height
        scrollView.minimumZoomScale = min(minXScale,minYScale)
        scrollView.zoomScale = scrollView.minimumZoomScale
    }
    @IBAction func attributionTapped(sender: UIButton) {
        let sfv = SFSafariViewController(URL: NSURL(string: Flickr.Constants.licenseUrl(image.license!.integerValue)!)!)
        navigationController?.pushViewController(sfv, animated: true)
    }
    func setupAttributions() -> Void {
        attribution.setTitle(attributionStr(image.license!.integerValue, ownerName:image.ownerName!), forState: .Normal)
        attribution.titleLabel?.textAlignment = .Center
        attributionLabel.text = "Copyright © \(image.ownerName!). No changes were made."
        attributionLabel.textColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        attribution.titleLabel?.textColor = UIColor.blueColor().colorWithAlphaComponent(0.7)
        scrollView.scrollIndicatorInsets.bottom = effectView.frame.height;
    }
    func loadFullSizeImage() -> Void {
        guard image.origImageUrl != nil else {
            return
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        Flickr.sharedInstance().getCellImageConvenience(image.origImageUrl!, completion: { (data) -> Void in
            dispatch_async(dispatch_get_main_queue()){
                
                self.imageView.image = UIImage(data: data)!
                self.updateMinZoomScaleFor(self.imageView.bounds.size)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        })
    }
}
extension PhotoViewController: UIGestureRecognizerDelegate{
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if touch.view!.isDescendantOfView(attribution){
            return false
        }
        return true
    }
}

extension PhotoViewController: UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView;
    }
}
