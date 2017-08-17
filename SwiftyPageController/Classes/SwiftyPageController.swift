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
    
}

public protocol SwiftyPageControllerAnimatorProtocol {
    
    func willAnimate(fromController: UIViewController, toController: UIViewController, animationDirection: SwiftyPageController.AnimationDirection)
    
    func animate(fromController: UIViewController, toController: UIViewController, animationDirection: SwiftyPageController.AnimationDirection)
    
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
    public var isEnabledSwipeAction = true
    public var animationDuration: TimeInterval = 0.25
    public var animator: SwiftyPageControllerAnimatorProtocol = SwiftyPageControllerAnimator()
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
    
    // MARK: - Setup
    
    fileprivate func setupController() {
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(_:)))
        swipeLeftGesture.direction = .left
        view.addGestureRecognizer(swipeLeftGesture)
        
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(_:)))
        swipeRightGesture.direction = .right
        view.addGestureRecognizer(swipeRightGesture)
        
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
        
        if selectedIndex != nil {
            selectFirstController(atIndex: selectedIndex!)
        } else {
            selectFirstController(atIndex: 0)
        }
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
        
        transition(from: fromController, to: toController, duration: animationDuration, options: .curveEaseInOut, animations: {
            self.animator.animate(fromController: fromController, toController: toController, animationDirection: animationDirection)
        }) { (finished) in
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
    
    public func setContainerPadding(padding: UIEdgeInsets) {
        topContainerConstraint.constant = padding.top
        bottompContainerConstraint.constant = -padding.bottom
        leadingContainerConstraint.constant = padding.left
        trailingContainerConstraint.constant = -padding.right
        view.layoutIfNeeded()
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
