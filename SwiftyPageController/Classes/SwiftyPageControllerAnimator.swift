//
//  PagesViewControllerAnimator.swift
//  ContainerControllerTest
//
//  Created by Alexander on 8/3/17.
//  Copyright © 2017 CryptoTicker. All rights reserved.
//

import Foundation
import UIKit

open class SwiftyPageControllerAnimator: SwiftyPageControllerAnimatorProtocol {
    
    public func willAnimate(fromController: UIViewController, toController: UIViewController, animationDirection: SwiftyPageController.AnimationDirection) {
        let delta: CGFloat = 150.0
        toController.view.frame.origin.x = animationDirection == .left ? delta : -delta
        toController.view.alpha = 0.0
    }
    
    public func animate(fromController: UIViewController, toController: UIViewController, animationDirection: SwiftyPageController.AnimationDirection) {
        let delta: CGFloat = 150.0
        fromController.view.frame.origin.x = animationDirection == .left ? -delta : delta
        toController.view.frame.origin.x = 0.0
        toController.view.alpha = 1.0
        fromController.view.alpha = 0.0
    }
    
}
