//
//  AppDelegate.swift
//  Klondike_Solitaire
//
//  Created by Stephen Paul Brown on 4/13/17.
//  Copyright © 2017 Stephen Paul Brown. All rights reserved.
//

// Icon used from: http://static.memrise.com/uploads/course_photos/8875791000150814162900.png

import UIKit

enum Suit : UInt8 {
    case spades = 0 // Black
    case clubs  = 1 // Black
    case diamonds = 2 // Red
    case hearts = 3 // Red
}

enum Rank : UInt8 {
    case a = 1
    case j = 11
    case q = 12
    case k = 13
}

//let ACE   : Character = "a"
let ace   : UInt8 = 1
let jack  : UInt8 = 11
let queen : UInt8 = 12
let king  : UInt8 = 13

func ==(left: Card, right: Card) -> Bool {
    return left.suit == right.suit && left.rank == right.rank
}

struct Card : Hashable {
    
    let suit : Suit  // .SPADES ... .HEARTS
    let rank : UInt8 // 1 ... 13
    
    init(dictionary dict : [String : AnyObject]) { // to retrieve from plist
        suit = Suit(rawValue: (dict["suit"] as! NSNumber).uint8Value)!
        rank = (dict["rank"] as! NSNumber).uint8Value
    }
    
    func toDictionary() -> [String : AnyObject] { // to store in plist
        return [
            "suit" : NSNumber(value: suit.rawValue as UInt8),
            "rank" : NSNumber(value: rank as UInt8)
        ]
    }
    
    var hashValue: Int {
        return Int(suit.rawValue*13 + rank - 1) // perfect hash to 0 ... 51
    }
    
    init(suit s : Suit, rank r : UInt8) {
        suit = s;
        rank = r
    }
    
    static func deck() -> [Card] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return (appDelegate.solitaire?.dealCards())!
    }
    
}

let kGameWon = "GameWon"

func sandboxArchivePath() -> String {
    let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
    return dir.appendingPathComponent("savedSolitaire.plist")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var solitaire : Solitaire?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        solitaire = Solitaire()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
//        var storedSolitaire = solitaire?.toDictionary()
//        let archiveName = sandboxArchivePath()
//        storedSolitaire.write(toFile: archiveName, atomically: true)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

