//
//  SCImagePanViewController.swift
//  SubjectiveCImagePan
//
//  Created by Yichi on 6/03/2015.
//  Copyright (c) 2015 Sam Page. All rights reserved.
//

import Foundation
import CoreMotion

class SCImagePanViewController : UIViewController, UIScrollViewDelegate {
	
	var motionManager:CMMotionManager?
	var displayLink:CADisplayLink?
	
	lazy var panningScrollView:UIScrollView = {
		let v = UIScrollView(frame: self.view.bounds)
		v.autoresizingMask = .FlexibleWidth | .FlexibleHeight
		v.backgroundColor = UIColor.blackColor()
		v.delegate = self
		v.scrollEnabled = false
		v.alwaysBounceVertical = false
		v.maximumZoomScale = 2.0
		return v
		}()
	lazy var panningImageView:UIImageView = {
		let v = UIImageView(frame: self.view.bounds)
		v.autoresizingMask = .FlexibleWidth | .FlexibleHeight
		v.backgroundColor = UIColor.blackColor()
		v.contentMode = .ScaleAspectFit
		return v
		}()
	lazy var scrollBarView:SCImagePanScrollBarView = {
		let v = SCImagePanScrollBarView(frame: self.view.bounds, edgeInsets: UIEdgeInsets(top: 0, left: 10, bottom: 50, right: 10))
		v.autoresizingMask = .FlexibleWidth | .FlexibleHeight
		v.userInteractionEnabled = false
		return v
		}()
	
	var motionBasedPanEnabled:Bool = false
	
	let kMovementSmoothing:NSTimeInterval = 0.3
	let kAnimationDuration:NSTimeInterval = 0.3
	let kRotationMultiplier:CGFloat = 5.0
	
	// MARK: init / deinit
	init(motionManager: CMMotionManager!) {
		super.init(nibName: nil, bundle: nil)
		
		self.motionManager = motionManager
		self.motionBasedPanEnabled = true
	}

	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	deinit {
		displayLink?.invalidate()
		motionManager?.stopDeviceMotionUpdates()
	}
	
	// MARK: View lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		panningScrollView.pinchGestureRecognizer.addTarget(self, action: "pinchGestureRecognized:")
		view.addSubview(panningScrollView)
		
		panningScrollView.addSubview(panningImageView)
		
		view.addSubview(scrollBarView)
		
		displayLink = CADisplayLink(target: self, selector: "displayLinkUpdate:")
		displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
		
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "toggleMotionBasedPan:")
		view.addGestureRecognizer(tapGestureRecognizer)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		panningScrollView.contentOffset = CGPoint(
			x: (panningScrollView.contentSize.width / 2 - panningScrollView.bounds.width / 2),
			y: (panningScrollView.contentSize.height / 2 - panningScrollView.bounds.height / 2)
		)
		
		motionManager?.startDeviceMotionUpdatesToQueue(
			NSOperationQueue.mainQueue(),
			withHandler: { (motion: CMDeviceMotion!, error: NSError?) -> Void in
			self.calculateRotationBasedOnDeviceMotionRotationRate(motion)
		})
	}
	
	// MARK: Status Bar
	override func prefersStatusBarHidden() -> Bool {
		return true
	}
	
	// MARK: Public
	// TODO: TEST WITH (#image:
	func configureWithImage(image: UIImage!) {
		panningImageView.image = image
		updateScrollViewZoomToMaximumFor(image: image)
	}
	
	// MARK: Private
	func calculateRotationBasedOnDeviceMotionRotationRate(motion:CMDeviceMotion) {
		if motionBasedPanEnabled {
			
			var rotationRate = (
				x: CGFloat(motion.rotationRate.x),
				y: CGFloat(motion.rotationRate.y),
				z: CGFloat(motion.rotationRate.z)
			)
			
			if abs(rotationRate.y) > abs(rotationRate.x) + abs(rotationRate.z) {
				let invertedYRotationRate = rotationRate.y * -1
				
				let zoomScale = maximumZoomScaleFor(image: panningImageView.image)
				let interpretedXOffset = panningScrollView.contentOffset.x + (invertedYRotationRate * zoomScale * kRotationMultiplier)
				
				let contentOffset = clampedContentOffsetFor(horizontalOffset: interpretedXOffset)
				
				UIView.animateWithDuration(
					kMovementSmoothing,
					delay: NSTimeInterval(0.0),
					options: UIViewAnimationOptions.BeginFromCurrentState | UIViewAnimationOptions.AllowUserInteraction | UIViewAnimationOptions.CurveEaseOut,
					animations: { () -> Void in
						self.panningScrollView.setContentOffset(contentOffset, animated: false)
						return
				}, completion: nil)
			}
		}
	}
	
	// MARK: CADisplayLink
	func displayLinkUpdate(displayLink:CADisplayLink) {
		let panningImageViewPresentationLayer = panningImageView.layer.presentationLayer() as CALayer
		let panningScrollViewPresentationLayer = panningScrollView.layer.presentationLayer() as CALayer
		
		let horizontalContentOffset = panningScrollViewPresentationLayer.bounds.minX
		
		let contentWidth = panningImageViewPresentationLayer.frame.width
		let visibleWidth = panningScrollView.bounds.width
		
		let clampedXOffsetAsPercentage = max(0.0, min(1.0, horizontalContentOffset / (contentWidth - visibleWidth) ) )
		
		let scrollBarWidthPercentage = visibleWidth / contentWidth
		let scrollableAreaPercentage = 1.0 - scrollBarWidthPercentage
		
		scrollBarView.updateWithScrollAmount(clampedXOffsetAsPercentage, forScrollableWidth: scrollBarWidthPercentage, inScrollableArea: scrollableAreaPercentage)
	}

	// MARK: Zooming
	func toggleMotionBasedPan(sender:AnyObject) {
		let motionBasedPanWasEnabled = motionBasedPanEnabled
		if motionBasedPanWasEnabled {
			motionBasedPanEnabled = false
		}
		
		UIView.animateWithDuration(
			kAnimationDuration,
			animations: { () -> Void in
				self.updateViews(motionBasedPanEnabled: !motionBasedPanWasEnabled)
			},
			completion: { (finished:Bool) -> Void in
				if motionBasedPanWasEnabled == false {
					self.motionBasedPanEnabled = true
				}
		})
	}
	
	func updateViews(#motionBasedPanEnabled:Bool) {
		if motionBasedPanEnabled {
			updateScrollViewZoomToMaximumFor(image: panningImageView.image)
			panningScrollView.scrollEnabled = false
		} else {
			panningScrollView.zoomScale = 1.0
			panningScrollView.scrollEnabled = true
		}
	}
	
	// MARK: Zoom toggling
	func maximumZoomScaleFor(#image:UIImage?) -> CGFloat {
		// TODO: See if it would work if I use For(#image
		var scale = CGFloat(1.0)
		if let image = image {
			scale =
			( panningScrollView.bounds.height / panningScrollView.bounds.width ) *
			( image.size.width / image.size.height )
		}
		return scale
	}
	
	func updateScrollViewZoomToMaximumFor(#image:UIImage?) {
		let zoomScale = maximumZoomScaleFor(image: image)
		
		panningScrollView.maximumZoomScale = zoomScale
		panningScrollView.zoomScale = zoomScale
	}
	
	// MARK: Helpers
	func clampedContentOffsetFor(#horizontalOffset:CGFloat) -> CGPoint {
		let xOffset = (
			min: CGFloat(0),
			max: panningScrollView.contentSize.width - panningScrollView.bounds.width
		)
		
		let clampedXOffset = max(xOffset.min, min(horizontalOffset, xOffset.max) )
		let centeredY = (panningScrollView.contentSize.height / 2) - (panningScrollView.bounds.height / 2)
		
		return CGPoint(x: clampedXOffset, y: centeredY)
	}
	
	// MARK: Pinch gesture
	func pinchGestureRecognized(sender:AnyObject) {
		motionBasedPanEnabled = false
		panningScrollView.scrollEnabled = true
	}
	
	// MARK: UIScrollViewDelegate
	func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
		return panningImageView
	}
	
	func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
		scrollView.setContentOffset(
			clampedContentOffsetFor(horizontalOffset: scrollView.contentOffset.x),
			animated: true
		)
	}
	
	func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if decelerate == false {
			scrollView.setContentOffset(
				clampedContentOffsetFor(horizontalOffset: scrollView.contentOffset.x),
				animated: true
			)
		}
	}
	
	func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
		scrollView.setContentOffset(
			clampedContentOffsetFor(horizontalOffset: scrollView.contentOffset.x),
			animated: true
		)
	}
}