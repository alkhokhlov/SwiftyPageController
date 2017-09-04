//
//  ViewController.swift
//  ContainerControllerTest
//
//  Created by Alexander on 8/1/17.
//  Copyright © 2017 CryptoTicker. All rights reserved.
//

import UIKit

public protocol SwiftyPageControllerDelegate: class {
    
    func swiftyPageController(_ controller: SwiftyPageController, willMoveToController toController: UIViewController)
    
    func swiftyPageController(_ controller: SwiftyPageController, didMoveToController toController: UIViewController)
    
    func swiftyPageController(_ controller: SwiftyPageController, alongSideTransitionToController toController: UIViewController)
    
}

public protocol SwiftyPageControllerAnimatorProtocol {
    
    var animationDuration: TimeInterval { get }
    
    var animationProgress: Float { get set }
    
    var animationSpeed: Float { get set }
    
    func setupAnimation(fromController: UIViewController, toController: UIViewController, panGesture: UIPanGestureRecognizer, animationDirection: SwiftyPageController.AnimationDirection)
    
    func didFinishAnimation(fromController: UIViewController, toController: UIViewController)
    
}

extension SwiftyPageControllerAnimatorProtocol {
    
    public var animationDuration: TimeInterval {
        return 1.0
    }
    
}

open class SwiftyPageController: UIViewController {
    
    // MARK: - Types
    
    public enum AnimatorType {
        case `default`
        case parallax
        case custom(SwiftyPageControllerAnimatorProtocol)
        
        var controller: SwiftyPageControllerAnimatorProtocol {
            get {
                switch self {
                case .`default`:
                    return AnimatorControllers.default
                case .parallax:
                    return AnimatorControllers.parallax
                case .custom(let controller):
                    if AnimatorControllers.custom == nil {
                        AnimatorControllers.custom = controller
                    }
                    return AnimatorControllers.custom!
                }
            }
            
            set {
                switch self {
                case .`default`:
                    AnimatorControllers.default = newValue as! SwiftyPageControllerAnimatorDefault
                case .parallax:
                    AnimatorControllers.parallax = newValue as! SwiftyPageControllerAnimatorParallax
                case .custom(_):
                    AnimatorControllers.custom = newValue
                }
            }
        }
    }
    
    public enum AnimationDirection {
        case left
        case right
    }
    
    // MARK: - Variables
    
    public weak var delegate: SwiftyPageControllerDelegate?
    public private(set) var selectedIndex: Int?
    public var panGesture: UIPanGestureRecognizer!
    public var isEnabledAnimation = true
    public var animator: AnimatorType = .default
    public var containerPaddings: UIEdgeInsets? {
        didSet {
            topContainerConstraint.constant = containerPaddings?.top ?? 0
            bottompContainerConstraint.constant = -(containerPaddings?.bottom ?? 0.0)
            leadingContainerConstraint.constant = containerPaddings?.left ?? 0
            trailingContainerConstraint.constant = -(containerPaddings?.right ?? 0.0)
            view.setNeedsLayout()
        }
    }
    public var selectedController: UIViewController {
        return viewControllers[selectedIndex ?? 0]
    }
    public var containerInsets: UIEdgeInsets? {
        didSet {
            for viewController in viewControllers {
                setupContentInsets(in: viewController)
            }
        }
    }
    public var viewControllers: [UIViewController] = [] {
        willSet {
            for viewController in viewControllers {
                if (viewController.viewIfLoaded != nil) {
                    viewController.view.removeFromSuperview()
                }
                viewController.removeFromParentViewController()
            }
        }
        
        didSet {
            if viewIfLoaded != nil {
                selectController(atIndex: viewControllers.index(of: selectedController)!, animated: false)
            }
        }
    }
    
    fileprivate var nextIndex: Int?
    fileprivate var isAnimating = false
    fileprivate var previousTopLayoutGuideLength: CGFloat!
    
    fileprivate enum AnimatorControllers {
        static var `default` = SwiftyPageControllerAnimatorDefault()
        static var parallax = SwiftyPageControllerAnimatorParallax()
        static var custom: SwiftyPageControllerAnimatorProtocol?
    }
    
    // container view
    fileprivate var containerView = UIView(frame: CGRect.zero)
    fileprivate var leadingContainerConstraint: NSLayoutConstraint!
    fileprivate var trailingContainerConstraint: NSLayoutConstraint!
    fileprivate var topContainerConstraint: NSLayoutConstraint!
    fileprivate var bottompContainerConstraint: NSLayoutConstraint!
    
    // interactive
    
    fileprivate var timerForInteractiveTransition: Timer?
    fileprivate var interactiveTransitionInProgress = false
    fileprivate var toControllerInteractive: UIViewController?
    fileprivate var fromControllerInteractive: UIViewController?
    fileprivate var animationDirectionInteractive: AnimationDirection!
    fileprivate var willFinishAnimationTransition = true
    fileprivate var timerVelocity = 1.0
    
    
    // MARK: - Life Cycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupController()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupContentInsets(in: selectedController)
    }
    
    // MARK: - Setup
    
    fileprivate func setupController() {
        // setup pan gesture
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanAction(_:)))
        view.addGestureRecognizer(panGesture)
        
        // setup container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        leadingContainerConstraint = containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        leadingContainerConstraint.isActive = true
        trailingContainerConstraint = containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        trailingContainerConstraint.isActive = true
        topContainerConstraint = containerView.topAnchor.constraint(equalTo: view.topAnchor)
        topContainerConstraint.isActive = true
        bottompContainerConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottompContainerConstraint.isActive = true
        view.layoutIfNeeded()
        
<<<<<<< HEAD
        selectController(atIndex: selectedIndex ?? 0, animated: false)
=======
        // select controller
        selectController(atIndex: selectedIndex ?? 0)
>>>>>>> interaction
        
        // assignment variable
        previousTopLayoutGuideLength = topLayoutGuide.length
    }
    
    fileprivate func setupContentInsets(in controller: UIViewController) {
<<<<<<< HEAD
        if let scrollView = controller.view.subviews.first as? UIScrollView {
            customAdjustScrollViewInsets(in: scrollView)
        }
        if let scrollView = controller.view as? UIScrollView {
            customAdjustScrollViewInsets(in: scrollView)
=======
        if controller.viewIfLoaded != nil {
            if let scrollView = controller.view.subviews.first as? UIScrollView {
                customAdjustScrollViewInsets(in: scrollView, isAutomaticallyAdjustsScrollViewInsets: controller.automaticallyAdjustsScrollViewInsets)
            }
            if let scrollView = controller.view as? UIScrollView {
                customAdjustScrollViewInsets(in: scrollView, isAutomaticallyAdjustsScrollViewInsets: controller.automaticallyAdjustsScrollViewInsets)
            }
>>>>>>> interaction
        }
    }
    
    // MARK: - Actions
    
    fileprivate func customAdjustScrollViewInsets(in scrollView: UIScrollView, isAutomaticallyAdjustsScrollViewInsets: Bool) {
        if let containerInsets = containerInsets {
            scrollView.contentInset = containerInsets
            scrollView.scrollIndicatorInsets = scrollView.contentInset
        } else if isAutomaticallyAdjustsScrollViewInsets {
            scrollView.contentInset = UIEdgeInsets(top: topLayoutGuide.length, left: 0.0, bottom: bottomLayoutGuide.length, right: 0.0)
            scrollView.scrollIndicatorInsets = scrollView.contentInset
        }
        
        // restore content offset
        if abs(scrollView.contentOffset.y) == topLayoutGuide.length {
            previousTopLayoutGuideLength = topLayoutGuide.length
        }
        
        scrollView.contentOffset.y += previousTopLayoutGuideLength - topLayoutGuide.length
        previousTopLayoutGuideLength = topLayoutGuide.length
    }
    
    fileprivate func interactiveTransition(fromController: UIViewController, toController: UIViewController, animationDirection: AnimationDirection) {
        if fromController == toController {
            return
        }
        
        // setup frame
        toController.view.frame = containerView.bounds
        containerView.addSubview(toController.view) // new line
        
        // setup insets
        setupContentInsets(in: toController)
        
        // setup animation
        animator.controller.setupAnimation(fromController: fromController, toController: toController, panGesture: panGesture, animationDirection: animationDirection)
        
        // call delegate 'willMoveToController' method
        delegate?.swiftyPageController(self, willMoveToController: toController)
        
        // assignment variables
        fromControllerInteractive = fromController
        toControllerInteractive = toController
        animationDirectionInteractive = animationDirection
        
        // handle end of transition in case no pan gesture
        if panGesture.state != .changed {
            willFinishAnimationTransition = true
            DispatchQueue.main.asyncAfter(deadline: .now() + animator.controller.animationDuration / Double(animator.controller.animationSpeed), execute: {
                self.finishTransition()
            })
        }
    }
    
    fileprivate func finishTransition() {
        if let fromController = fromControllerInteractive, let toController = toControllerInteractive {
            // drop timer
            timerForInteractiveTransition?.invalidate()
            timerForInteractiveTransition = nil
            
            // call delegate 'didMoveToController' method
            delegate?.swiftyPageController(self, didMoveToController: toController)
            
            // remove fromController from hierarchy
            fromController.didMove(toParentViewController: nil)
            fromController.view.removeFromSuperview()
            fromController.removeFromParentViewController()
            
            // present toController
            toController.didMove(toParentViewController: self)
            
            // change selectedIndex
            selectedIndex = viewControllers.index(of: toController)!
            
            // clear variables
            isAnimating = false
            toControllerInteractive = nil
            fromControllerInteractive = nil
            
            // call delegate 'didFinishAnimation' method
            animator.controller.didFinishAnimation(fromController: fromController, toController: toController)
            
            // logic for transition between child view controllers
            if let nextIndex = nextIndex {
                if viewControllers[nextIndex] == toController {
                    self.nextIndex = nil
                } else {
                    transitionToIndex(index: nextIndex)
                }
            }
        }
    }
    
    fileprivate func cancelTransition() {
        if let toController = toControllerInteractive, let fromController = fromControllerInteractive {
            // drop timer
            timerForInteractiveTransition?.invalidate()
            timerForInteractiveTransition = nil
            
            // remove toController from hierarchy
            toController.view.removeFromSuperview()
            toController.removeFromParentViewController()
            
            // change selectedIndex
            selectedIndex = viewControllers.index(of: fromController)!
            
            // clear variables
            isAnimating = false
            toControllerInteractive = nil
            fromControllerInteractive = nil
            
            animator.controller.didFinishAnimation(fromController: fromController, toController: toController)
        }
    }
    
    fileprivate func startTimerForInteractiveTransition() {
        isAnimating = true
        let timeInterval = 0.001
        
        if willFinishAnimationTransition {
            toControllerInteractive?.view.layer.position.x = UIScreen.main.bounds.width / 2.0
        } else {
            toControllerInteractive?.view.layer.position.x = animationDirectionInteractive == .left ? containerView.bounds.width * 2.0 : -containerView.bounds.width / 2.0
        }
        
        timerForInteractiveTransition = Timer.scheduledTimer(timeInterval: timeInterval / timerVelocity, target: self, selector: #selector(finishAnimationTransition), userInfo: nil, repeats: true)
    }
    
    func finishAnimationTransition() {
        if let fromController = fromControllerInteractive, let toController = toControllerInteractive {
            let timeOffset: Double = Double(animator.controller.animationProgress) * Double(animator.controller.animationDuration)
            let delta: Float = 0.002
            
            if willFinishAnimationTransition {
                animator.controller.animationProgress += delta
            } else {
                animator.controller.animationProgress -= delta
            }
            
            toController.view.layer.timeOffset = CFTimeInterval(timeOffset)
            fromController.view.layer.timeOffset = CFTimeInterval(timeOffset)
            if animator.controller.animationProgress >= 1.0 {
                finishTransition()
            } else if animator.controller.animationProgress <= 0.0 {
                cancelTransition()
            }
        }
    }
    
    fileprivate func transitionToIndex(index: Int) {
        if !isViewLoaded {
            return
        }
        
        self.delegate?.swiftyPageController(self, willMoveToController: viewControllers[index])
        let newController = viewControllers[index]
        let direction: AnimationDirection = index - selectedIndex! > 0 ? .left : .right
        interactiveTransition(fromController: self.viewControllers[selectedIndex!], toController: newController, animationDirection: direction) // new
    }
    
    fileprivate func selectController(atIndex index: Int) {
        selectedIndex = index
        
        if !isViewLoaded {
            return
        }
        
        // setup first controller
        let controller = viewControllers[index]
        
        // setup frame
        controller.view.frame = containerView.bounds
        
        // setup insets
        setupContentInsets(in: controller)
        
        // call delegate 'willMoveToController' method
        delegate?.swiftyPageController(self, willMoveToController: controller)
        
        // show controller
        containerView.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
        
        // call delegate 'didMoveToController' methode
        self.delegate?.swiftyPageController(self, didMoveToController: controller)
    }
    
    public func selectController(atIndex index: Int, animated: Bool) {
        assert(viewControllers.count != 0, "Array 'viewControllers' count couldn't be 0")
        
<<<<<<< HEAD
=======
        // add child view controller if it hasn't been added
>>>>>>> interaction
        if !childViewControllers.contains(viewControllers[index]) {
            addChildViewController(viewControllers[index])
        }
        
<<<<<<< HEAD
=======
        // select controller
>>>>>>> interaction
        if selectedIndex == nil {
            selectController(atIndex: index)
        } else {
            if animated && isEnabledAnimation {
                if isAnimating {
                    nextIndex = index
                } else {
                    transitionToIndex(index: index)
                }
            } else {
                selectController(atIndex: index)
            }
        }
    }
    
    func handlePanAction(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        switch sender.state {
        case .changed:
            if isAnimating {
                return
            }
            
            // select controller
            if !interactiveTransitionInProgress {
                if translation.x > 0 {
                    // select previous controller
                    let index = selectedIndex! - 1
                    if index >= 0 {
                        interactiveTransitionInProgress = true
                        selectController(atIndex: index, animated: isEnabledAnimation)
                    }
                } else {
                    // select next controller
                    let index = selectedIndex! + 1
                    if index <= viewControllers.count - 1 {
                        interactiveTransitionInProgress = true
                        selectController(atIndex: index, animated: isEnabledAnimation)
                    }
                }
            }
            
            // cancel transition in case of changing direction
            if (translation.x > 0 && animationDirectionInteractive != .right) || (translation.x < 0 && animationDirectionInteractive != .left) {
                interactiveTransitionInProgress = false
                cancelTransition()
            }
            
            // set layer position
            toControllerInteractive?.view.layer.position.x = translation.x > 0 ? containerView.bounds.width * 2.0 : -containerView.bounds.width / 2.0
            
            // interactive animation
            animator.controller.animationProgress = fmin(fmax(Float(abs(translation.x) / containerView.bounds.width), 0.0), 2.0)
            
            willFinishAnimationTransition = animator.controller.animationProgress > 0.4
            let timeOffset = animator.controller.animationProgress * Float(animator.controller.animationDuration)
            toControllerInteractive?.view.layer.timeOffset = CFTimeInterval(timeOffset)
            fromControllerInteractive?.view.layer.timeOffset = CFTimeInterval(timeOffset)
        case .cancelled, .ended:
            // finish animation relatively velocity
            let velocity = sender.velocity(in: view)
            if animationDirectionInteractive == .left ? (velocity.x > 0) : (velocity.x < 0) {
                timerVelocity = 1.0
                willFinishAnimationTransition = false
            } else {
                if abs(velocity.x) > 32.0 {
                    timerVelocity = 2.0
                    willFinishAnimationTransition = true
                } else {
                    timerVelocity = 1.0
                }
            }
            interactiveTransitionInProgress = false
            if fromControllerInteractive != nil, toControllerInteractive != nil {
                startTimerForInteractiveTransition()
            }
        default:
            break
        }
    }
    
    func swipeAction(direction: AnimationDirection) {
        if direction == .right {
            let index = selectedIndex! - 1
            if index >= 0 {
                selectController(atIndex: index, animated: isEnabledAnimation)
            }
        } else {
            let index = selectedIndex! + 1
            if index <= viewControllers.count - 1 {
                selectController(atIndex: index, animated: isEnabledAnimation)
            }
        }
    }


}
