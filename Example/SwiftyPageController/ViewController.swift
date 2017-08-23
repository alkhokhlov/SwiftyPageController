//
//  ViewController.swift
//  ContainerControllerTest
//
//  Created by Alexander on 8/2/17.
//  Copyright © 2017 CryptoTicker. All rights reserved.
//

import UIKit
import SwiftyPageController

class ViewController: UIViewController {

    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    var containerController: SwiftyPageController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        segmentControl.addTarget(self, action: #selector(segmentControlDidChange(_:)), for: .valueChanged)
    }
    
    func segmentControlDidChange(_ sender: UISegmentedControl) {
        containerController.selectController(atIndex: sender.selectedSegmentIndex, animated: true)
    }
    
    func setupContainerController(_ controller: SwiftyPageController) {
        containerController = controller
        
        containerController.isEnabledSwipeAction = false
        
        containerController.delegate = self
        
        let firstController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(FirstViewController.self)")
        let secondController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(SecondViewController.self)")
        let thirdController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(ThirdViewController.self)")
        containerController.viewControllers = [firstController, secondController, thirdController]
        
        containerController.selectController(atIndex: 0, animated: false)
    }

    @IBAction func shuffleButtonDidTap(_ sender: Any) {
        let firstController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(FirstViewController.self)")
        let secondController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(SecondViewController.self)")
        let thirdController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(ThirdViewController.self)")
        containerController.viewControllers = [firstController, secondController, thirdController].shuffled()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let containerController = segue.destination as? SwiftyPageController {
            setupContainerController(containerController)
        }
    }

}

// MARK: - PagesViewControllerDelegate

extension ViewController: SwiftyPageControllerDelegate {
    
    func swiftyPageController(_ controller: SwiftyPageController, alongSideTransitionToController toController: UIViewController) {
        
    }
    
    func swiftyPageController(_ controller: SwiftyPageController, didMoveToController toController: UIViewController) {
        segmentControl.selectedSegmentIndex = containerController.viewControllers.index(of: toController)!
    }
    
    func swiftyPageController(_ controller: SwiftyPageController, willMoveToController toController: UIViewController) {
        
    }
    
}
