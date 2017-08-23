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
    public var gestures: [UISwipeGestureRecognizer] = []
    public var isEnabledSwipeAction = true
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
    fileprivate var interactiveTransitionInProgress = false
    fileprivate var shouldCompleteInteractiveTransition = false
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
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanAction(_:)))
        view.addGestureRecognizer(panGesture)
        
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(_:)))
        swipeLeftGesture.direction = .left
        view.addGestureRecognizer(swipeLeftGesture)
        gestures.append(swipeLeftGesture)
        
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(_:)))
        swipeRightGesture.direction = .right
        view.addGestureRecognizer(swipeRightGesture)
        gestures.append(swipeRightGesture)
        
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
        
        selectController(atIndex: selectedIndex ?? 0)
        
        previousTopLayoutGuideLength = topLayoutGuide.length
    }
    
    // MARK: - Actions
    
    fileprivate func setupContentInsets(in controller: UIViewController) {
        if let scrollView = controller.view.subviews.first as? UIScrollView, controller.automaticallyAdjustsScrollViewInsets {
            customAdjustScrollViewInsets(in: scrollView)
        }
        if let scrollView = controller.view as? UIScrollView, controller.automaticallyAdjustsScrollViewInsets {
            customAdjustScrollViewInsets(in: scrollView)
        }
    }
    
    fileprivate func customAdjustScrollViewInsets(in scrollView: UIScrollView) {
        if let containerInsets = containerInsets {
            scrollView.contentInset = containerInsets
            scrollView.scrollIndicatorInsets = scrollView.contentInset
        } else {
            scrollView.contentInset = UIEdgeInsets(top: topLayoutGuide.length, left: 0.0, bottom: bottomLayoutGuide.length, right: 0.0)
            scrollView.scrollIndicatorInsets = scrollView.contentInset
        }
        
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
        isAnimating = true
        
        // setup frame
        toController.view.frame = containerView.bounds
        containerView.addSubview(toController.view) // new line
        
        setupContentInsets(in: toController)
        
        // setup animation
        
        let animation = CABasicAnimation(keyPath: "position.x")
        animation.beginTime = 0.0
        animation.duration = animator.animationDuration
        animation.fromValue = animationDirection == .left ? toController.view.frame.width * 1.5 : -toController.view.frame.width * 1.5
        animation.toValue = toController.view.frame.width / 2.0
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        
        toController.view.layer.speed = 0.0
        toController.view.layer.add(animation, forKey: "to.controller.animation.position.x")
        
        fromControllerInteractive = fromController
        toControllerInteractive = toController
    }
    
    fileprivate func transition(fromController: UIViewController, toController: UIViewController, animationDirection: AnimationDirection) {
        if fromController == toController {
            return
        }
        isAnimating = true
        
        // setup frame
        toController.view.frame = containerView.bounds
        containerView.addSubview(toController.view)
        
        // setup content insets
        setupContentInsets(in: toController)
        
        // call 'willMove' delegate method
        animator.willAnimate(fromController: fromController, toController: toController, animationDirection: animationDirection)
        
        UIView.animate(withDuration: animator.animationDuration, animations: {
            self.delegate?.swiftyPageController(self, alongSideTransitionToController: toController)
            self.animator.animate(fromController: fromController, toController: toController, animationDirection: animationDirection)
        }) { (finished) in
            self.animator.didFinishAnimation(fromController: fromController, toController: toController, animationDirection: animationDirection)
            
            // remove fromController from hierarchy
            fromController.didMove(toParentViewController: nil)
            fromController.view.removeFromSuperview()
            fromController.removeFromParentViewController()
            
            // present toController
            toController.didMove(toParentViewController: self)
            
            // change selectedIndex
            self.selectedIndex = self.viewControllers.index(of: toController)!
            
            // call 'didMove' delegate method
            self.delegate?.swiftyPageController(self, didMoveToController: toController)
            
            // logic for transition between child view controllers
            if let nextIndex = self.nextIndex {
                if self.viewControllers[nextIndex] == toController {
                    self.nextIndex = nil
                } else {
                    self.transitionToIndex(index: nextIndex)
                }
            }
            
            self.isAnimating = false
        }
    }
    
    fileprivate func transitionToIndex(index: Int) {
        if !isViewLoaded {
            return
        }
        
        self.delegate?.swiftyPageController(self, willMoveToController: viewControllers[index])
        let newController = viewControllers[index]
        let direction: AnimationDirection = index - selectedIndex! > 0 ? .left : .right
//        transition(fromController: self.viewControllers[selectedIndex!], toController: newController, animationDirection: direction)
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
        
        setupContentInsets(in: controller)
        
        self.delegate?.swiftyPageController(self, willMoveToController: controller)
        
        containerView.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
        
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
    
    func swipeAction(_ sender: UISwipeGestureRecognizer) {
        if isEnabledSwipeAction {
            if sender.direction == .right {
                let index = selectedIndex! - 1
                if index >= 0 {
                    selectController(atIndex: index, animated: isEnabledAnimation)
                }
            } else if sender.direction == .left {
                let index = selectedIndex! + 1
                if index <= viewControllers.count - 1 {
                    selectController(atIndex: index, animated: isEnabledAnimation)
                }
            }
        }
    }
    
    func handlePanAction(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        switch sender.state {
        case .changed:
            if !interactiveTransitionInProgress {
                if translation.x > 0 {
                    let index = selectedIndex! - 1
                    if index >= 0 {
                        selectController(atIndex: index, animated: isEnabledAnimation)
                    }
                } else {
                    let index = selectedIndex! + 1
                    if index <= viewControllers.count - 1 {
                        interactiveTransitionInProgress = true
                        selectController(atIndex: index, animated: isEnabledAnimation)
                    }
                }
            }
            
            let x = fmin(fmax(abs(translation.x) / containerView.bounds.width * 1.5, 0.0), 2.0)
            print(abs(translation.x))
            print(x)
            shouldCompleteInteractiveTransition = true
            toControllerInteractive?.view.layer.timeOffset = CFTimeInterval(x * CGFloat(animator.animationDuration))
        case .cancelled, .ended:
            interactiveTransitionInProgress = false
            if let fromControllerInteractive = fromControllerInteractive,
                let toControllerInteractive = toControllerInteractive {
                // remove fromController from hierarchy
                fromControllerInteractive.didMove(toParentViewController: nil)
                fromControllerInteractive.view.removeFromSuperview()
                fromControllerInteractive.removeFromParentViewController()
                
                // present toController
                toControllerInteractive.didMove(toParentViewController: self)
                
                // change selectedIndex
                selectedIndex = viewControllers.index(of: toControllerInteractive)!
                
                toControllerInteractive.view.layer.removeAnimation(forKey: "to.controller.animation.position.x")
                
                isAnimating = false
                shouldCompleteInteractiveTransition = false
                self.toControllerInteractive = nil
                self.fromControllerInteractive = nil
            }
        default:
            break
        }
    }


}
