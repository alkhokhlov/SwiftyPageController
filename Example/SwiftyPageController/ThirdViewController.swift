//
//  SecondViewController.swift
//  ContainerControllerTest
//
//  Created by Alexander on 8/1/17.
//  Copyright © 2017 CryptoTicker. All rights reserved.
//

import UIKit

private let identifier = "cell"

class ThirdViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var items: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(ThirdViewController.self) view did load")
                
        for i in 0...100 {
            items.append(i)
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("\(ThirdViewController.self) view will appear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("\(ThirdViewController.self) view did appear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("\(ThirdViewController.self) view will disappear")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("\(ThirdViewController.self) view did disappear")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ThirdViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        cell.textLabel?.text = "\(items[indexPath.row])"
        return cell
    }
    
}
