//
//  BurgerDetailViewController.swift
//  BurgerMap
//
//  Created by Nicolas Ameghino on 9/16/15.
//
//

import UIKit

class BurgerDetailInfo: NSObject {
    let backgroundImage: UIImage
    let burgerWrapper: BurgerWrapper
    
    init(backgroundImage: UIImage, burgerWrapper: BurgerWrapper) {
        self.backgroundImage = backgroundImage
        self.burgerWrapper = burgerWrapper
    }
}

class BurgerDetailViewController: UIViewController {
    @IBOutlet weak var closeButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let info = sender as? BurgerDetailInfo else { return }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}