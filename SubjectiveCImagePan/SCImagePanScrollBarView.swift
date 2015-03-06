//
//  SCImagePanScrollBarView.swift
//  SubjectiveCImagePan
//
//  Created by Yichi on 7/03/2015.
//  Copyright (c) 2015 Sam Page. All rights reserved.
//

import Foundation
import UIKit

class SCImagePanScrollBarView : UIView {
	private var scrollBarLayer = CAShapeLayer()
	
	init(frame: CGRect, edgeInsets: UIEdgeInsets) {
		super.init(frame: frame)
		
		let scrollBarPath = UIBezierPath()
		scrollBarPath.moveToPoint(CGPoint(x: edgeInsets.left, y: bounds.height - edgeInsets.bottom ))
		scrollBarPath.addLineToPoint(CGPoint(x: bounds.width - edgeInsets.right, y: bounds.height - edgeInsets.bottom ))
		
		let scrollBarBackgroundLayer = CAShapeLayer()
		scrollBarBackgroundLayer.path = scrollBarPath.CGPath
		scrollBarBackgroundLayer.lineWidth = 1
		scrollBarBackgroundLayer.strokeColor = UIColor.whiteColor().colorWithAlphaComponent(0.1).CGColor
		scrollBarBackgroundLayer.fillColor = UIColor.clearColor().CGColor
		
		layer.addSublayer(scrollBarBackgroundLayer)
		
		scrollBarLayer.path = scrollBarPath.CGPath
		scrollBarLayer.lineWidth = 1.0
		scrollBarLayer.strokeColor = UIColor.whiteColor().CGColor
		scrollBarLayer.fillColor = UIColor.clearColor().CGColor
		scrollBarLayer.actions = [
			"strokeStart" : NSNull(),
			"strokeEnd" : NSNull()
		]
		
		layer.addSublayer(scrollBarLayer)
	}

	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	func updateWithScrollAmount(scrollAmount: CGFloat, forScrollableWidth scrollableWidth: CGFloat, inScrollableArea scrollableArea: CGFloat) {
		scrollBarLayer.strokeStart = scrollAmount * scrollableArea
		scrollBarLayer.strokeEnd = (scrollAmount * scrollableArea) + scrollableWidth
	}
}