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
        return 0.25
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
        }
    }
    
    fileprivate var nextIndex: Int?
    fileprivate var isAnimating = false
    fileprivate var containerView = UIView(frame: CGRect.zero)
    fileprivate var leadingContainerConstraint: NSLayoutConstraint!
    fileprivate var trailingContainerConstraint: NSLayoutConstraint!
    fileprivate var topContainerConstraint: NSLayoutConstraint!
    fileprivate var bottompContainerConstraint: NSLayoutConstraint!
    
    
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
        
        selectFirstController(atIndex: selectedIndex ?? 0)
    }
    
    // MARK: - Actions
    
    fileprivate func setupContentInsets(in controller: UIViewController) {
        if let containerInsets = containerInsets {
            if let scrollView = controller.view.subviews.first as? UIScrollView {
                scrollView.contentInset = containerInsets
                scrollView.scrollIndicatorInsets = scrollView.contentInset
            }
            if let scrollView = controller.view as? UIScrollView {
                scrollView.contentInset = containerInsets
                scrollView.scrollIndicatorInsets = scrollView.contentInset
            }
        } else {
            if let scrollView = controller.view.subviews.first as? UIScrollView, controller.automaticallyAdjustsScrollViewInsets {
                scrollView.contentInset = UIEdgeInsets(top: topLayoutGuide.length, left: 0.0, bottom: bottomLayoutGuide.length, right: 0.0)
                scrollView.scrollIndicatorInsets = scrollView.contentInset
            }
            if let scrollView = controller.view as? UIScrollView, controller.automaticallyAdjustsScrollViewInsets {
                scrollView.contentInset = UIEdgeInsets(top: topLayoutGuide.length, left: 0.0, bottom: bottomLayoutGuide.length, right: 0.0)
                scrollView.scrollIndicatorInsets = scrollView.contentInset
            }
        }
    }
    
    fileprivate func transition(fromController: UIViewController, toController: UIViewController, animationDirection: AnimationDirection) {
        if fromController == toController {
            return
        }
        isAnimating = true
        
        // setup frame
        toController.view.frame = containerView.bounds
        
        setupContentInsets(in: toController)
        
        animator.willAnimate(fromController: fromController, toController: toController, animationDirection: animationDirection)
        
        transition(from: fromController, to: toController, duration: animator.animationDuration, options: .curveEaseInOut, animations: {
            self.delegate?.swiftyPageController(self, alongSideTransitionToController: toController)
            self.animator.animate(fromController: fromController, toController: toController, animationDirection: animationDirection)
        }) { (finished) in
            self.animator.didFinishAnimation(fromController: fromController, toController: toController, animationDirection: animationDirection)
            self.containerView.addSubview(toController.view)
            toController.didMove(toParentViewController: self)
            
            self.selectedIndex = self.viewControllers.index(of: toController)!
            self.delegate?.swiftyPageController(self, didMoveToController: toController)
     
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
        transition(fromController: self.viewControllers[selectedIndex!], toController: newController, animationDirection: direction)
    }
    
    fileprivate func selectFirstController(atIndex index: Int) {
        selectedIndex = index
        
        if !isViewLoaded {
            return
        }
        
        // setup first controller
        let controller = viewControllers[index]
        
        // setup frame
        controller.view.frame = containerView.bounds
        
        setupContentInsets(in: controller)
        
        containerView.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
    }
    
    public func selectController(atIndex index: Int) {
        assert(viewControllers.count != 0, "Array 'viewControllers' count couldn't be 0")
        
        if selectedIndex == nil {
            selectFirstController(atIndex: index)
        } else {
            if isAnimating {
                nextIndex = index
            } else {
                transitionToIndex(index: index)
            }
        }
    }
    
    func swipeAction(_ sender: UISwipeGestureRecognizer) {
        if isEnabledSwipeAction {
            if sender.direction == .right {
                let index = selectedIndex! - 1
                if index >= 0 {
                    selectController(atIndex: index)
                }
            } else if sender.direction == .left {
                let index = selectedIndex! + 1
                if index <= viewControllers.count - 1 {
                    selectController(atIndex: index)
                }
            }
        }
    }


}
