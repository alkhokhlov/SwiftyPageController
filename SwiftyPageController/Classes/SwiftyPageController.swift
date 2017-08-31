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
    
    func willAnimate(fromController: UIViewController, toController: UIViewController, animationDirection: SwiftyPageController.AnimationDirection)
    
    func animate(fromController: UIViewController, toController: UIViewController, animationDirection: SwiftyPageController.AnimationDirection)
    
    func didFinishAnimation(fromController: UIViewController, toController: UIViewController, animationDirection: SwiftyPageController.AnimationDirection)
    
}

extension SwiftyPageControllerAnimatorProtocol {
    
    public var animationDuration: TimeInterval {
        return 1.0
    }
    
}

open class SwiftyPageController: UIViewController {
    
    // MARK: - Types
    
    public enum AnimationDirection {
        case left
        case right
    }
    
    // MARK: - Variables
    
    public weak var delegate: SwiftyPageControllerDelegate?
    public private(set) var selectedIndex: Int?
    public var panGesture: UIPanGestureRecognizer!
    public var isEnabledAnimation = true
    public var animator: SwiftyPageControllerAnimatorProtocol = SwiftyPageControllerAnimator()
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
            for viewController in viewControllers {
                addChildViewController(viewController)
            }
            if viewIfLoaded != nil {
                selectController(atIndex: viewControllers.index(of: selectedController)!, animated: false)
            }
        }
    }
    
    fileprivate var nextIndex: Int?
    fileprivate var isAnimating = false
    fileprivate var previousTopLayoutGuideLength: CGFloat!
    
    // container view
    fileprivate var containerView = UIView(frame: CGRect.zero)
    fileprivate var leadingContainerConstraint: NSLayoutConstraint!
    fileprivate var trailingContainerConstraint: NSLayoutConstraint!
    fileprivate var topContainerConstraint: NSLayoutConstraint!
    fileprivate var bottompContainerConstraint: NSLayoutConstraint!
    
    // interactive
    fileprivate var fromControllerAnimationIdentifier = "from.controller.animation.position.x"
    fileprivate var toControllerAnimationIdentifier = "to.controller.animation.position.x"
    fileprivate var timerForInteractiveTransition: Timer?
    fileprivate var interactiveTransitionInProgress = false
    fileprivate var toControllerInteractive: UIViewController?
    fileprivate var fromControllerInteractive: UIViewController?
    
    
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
        
        // select controller
        selectController(atIndex: selectedIndex ?? 0)
        
        // assignment variable
        previousTopLayoutGuideLength = topLayoutGuide.length
    }
    
    fileprivate func setupContentInsets(in controller: UIViewController) {
        if let scrollView = controller.view.subviews.first as? UIScrollView, controller.automaticallyAdjustsScrollViewInsets {
            customAdjustScrollViewInsets(in: scrollView)
        }
        if let scrollView = controller.view as? UIScrollView, controller.automaticallyAdjustsScrollViewInsets {
            customAdjustScrollViewInsets(in: scrollView)
        }
    }
    
    // MARK: - Actions
    
    fileprivate func customAdjustScrollViewInsets(in scrollView: UIScrollView) {
        if let containerInsets = containerInsets {
            scrollView.contentInset = containerInsets
            scrollView.scrollIndicatorInsets = scrollView.contentInset
        } else {
            scrollView.contentInset = UIEdgeInsets(top: topLayoutGuide.length, left: 0.0, bottom: bottomLayoutGuide.length, right: 0.0)
            scrollView.scrollIndicatorInsets = scrollView.contentInset
        }
        
        // restore content offset
        if abs(scrollView.contentOffset.y) == scrollView.contentInset.top {
            previousTopLayoutGuideLength = scrollView.contentInset.top
        }

        scrollView.contentOffset.y += previousTopLayoutGuideLength - scrollView.contentInset.top
        previousTopLayoutGuideLength = scrollView.contentInset.top
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
        
        let kAnimation: Float = 2.0
        
        let animationPositionToController = CABasicAnimation(keyPath: "position.x")
        animationPositionToController.duration = animator.animationDuration
        animationPositionToController.fromValue = animationDirection == .left ? (toController.view.frame.width * 1.5) : (-toController.view.frame.width / 2.0)
        animationPositionToController.toValue = toController.view.frame.width / 2.0
        animationPositionToController.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        
        toController.view.layer.speed = panGesture.state != .changed ? kAnimation : 0.0
        toController.view.layer.add(animationPositionToController, forKey: toControllerAnimationIdentifier)
        
        let animationPositionFromController = animationPositionToController
        animationPositionFromController.fromValue = fromController.view.layer.position.x
        animationPositionFromController.toValue = animationDirection == .left ? (-toController.view.frame.width / 2.0) : (toController.view.frame.width * 1.5)
        animationPositionFromController.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        
        fromController.view.layer.speed = panGesture.state != .changed ? kAnimation : 0.0
        fromController.view.layer.add(animationPositionFromController, forKey: fromControllerAnimationIdentifier)
        
        // call delegate 'willMoveToController' method
        delegate?.swiftyPageController(self, willMoveToController: toController)
        
        // assignment variables
        fromControllerInteractive = fromController
        toControllerInteractive = toController
        
        // handle end of transition in case no pan gesture
        if panGesture.state != .changed {
            DispatchQueue.main.asyncAfter(deadline: .now() + animator.animationDuration / Double(kAnimation), execute: {
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
            
            // remove animations
            toController.view.layer.removeAnimation(forKey: toControllerAnimationIdentifier)
            fromController.view.layer.removeAnimation(forKey: fromControllerAnimationIdentifier)
            
            // clear variables
            isAnimating = false
            toControllerInteractive = nil
            fromControllerInteractive = nil
            
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
    
    fileprivate func startTimerForInteractiveTransition() {
        isAnimating = true
        let timeInterval = 0.001
        timerForInteractiveTransition = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(finishAnimationTransition), userInfo: nil, repeats: true)
    }
    
    func finishAnimationTransition() {
        if let fromController = fromControllerInteractive,
            let toController = toControllerInteractive
        {
            let timeOffset: Double = Double(animator.animationProgress) * Double(animator.animationDuration)
            let delta: Float = 0.002
            animator.animationProgress += delta
            
            toController.view.layer.timeOffset = CFTimeInterval(timeOffset)
            fromController.view.layer.timeOffset = CFTimeInterval(timeOffset)
            if animator.animationProgress > 1.0 {
                finishTransition()
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
            
            // interactive animation
            animator.animationProgress = fmin(fmax(Float(abs(translation.x) / containerView.bounds.width), 0.0), 2.0)
            let timeOffset = animator.animationProgress * Float(animator.animationDuration)
            toControllerInteractive?.view.layer.timeOffset = CFTimeInterval(timeOffset)
            fromControllerInteractive?.view.layer.timeOffset = CFTimeInterval(timeOffset)
        case .cancelled, .ended:
            interactiveTransitionInProgress = false
            if fromControllerInteractive != nil, toControllerInteractive != nil {
                startTimerForInteractiveTransition()
            }
        default:
            break
        }
    }


}
