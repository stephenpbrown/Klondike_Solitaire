//
//  ViewController.swift
//  Klondike_Solitaire
//
//  Created by Stephen Paul Brown on 4/20/17.
//  Copyright © 2017 Stephen Paul Brown. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var solitaireView: SolitaireView!
    
    @IBOutlet weak var newGameToolBar: UIToolbar!
    
    @IBAction func newGame(_ sender: Any) {
        
        let secondaryAlertController = UIAlertController(
            title: "Start a new game?",
            message: "",
            preferredStyle: .alert
        )
        secondaryAlertController.addAction(UIKit.UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
        secondaryAlertController.addAction(UIKit.UIAlertAction(
            title: "Yes",
            style: .default,
            handler: { (UIAlertAction) -> Void in
                self.solitaireView.resetGame()
        }))
        self.present(secondaryAlertController, animated: true, completion: nil)
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: kOrientationChangedToLandscape),
            object: nil,
            queue: nil) { (note: Notification) -> Void in
                self.newGameToolBar.isHidden = true
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: kOrientationChangedToPortrait),
            object: nil,
            queue: nil) { (note: Notification) -> Void in
                self.newGameToolBar.isHidden = false
        }
    }
}
