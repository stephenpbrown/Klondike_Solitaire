//
//  Solitaire.swift
//  Klondike_Solitaire
//
//  Created by Stephen Paul Brown on 4/17/17.
//  Copyright © 2017 Stephen Paul Brown. All rights reserved.
//

import Foundation

class Solitaire {
    
    var stock : [Card]
    var waste : [Card]
    var foundation : [[Card]]
    var tableau : [[Card]]
    private var faceUpCards : Set<Card>;
    
//    init(dictionary dict : [String : AnyObject]) { // for retrieving from plist
//        //... 
//    }
//    
//    func toDictionary() -> [String : AnyObject] {  // for storing in plist
//        //...
//    }
    
    // Create new Solitaire game model object.
    init() {
        stock = []
        waste = []
        foundation = [[]]
        tableau = [[]]
        faceUpCards = []
    }
    
    // Reshuffle and redeal cards to start a new game.
    func freshGame() {
        
    }

    // All cards have successfully reached a foundation stack. func isCardFaceUp(_ card : Card) -> Bool Is given card face up?
    func gameWon() -> Bool {
        return false
    }
    
    // Checks to see if the card is facing up
    func isCardFaceUp(_ card : Card) -> Bool {
        return true
    }
    
    // Array of face up cards found stacked on top of one of the tableau’s.
    func fanBeginningWithCard(_ card : Card) -> [Card]?
    {
        return []
    }
    
    // Can the given cards be legally dropped on the ith foundation?
    func canDropCard(_ card : Card, onFoundation i : Int) -> Bool {
        return false
    }
    
    // The user did drop the given card on on the ith foundation.
    func didDropCard(_ card : Card, onFoundation i : Int) {
        
    }
    
    // Can the given card be legally dropped on the ith tableau?
    func canDropCard(_ card : Card, onTableau i : Int) -> Bool {
        return false
    }
    
    // The user did drop the card on the on the ith tableau.
    func didDropCard(_ card : Card, onTableau i : Int) {
        
    }
    
    // Can the given stack of cards be legally dropped on the i tableau?
    func canDropFan(_ cards : [Card], onTableau i : Int) -> Bool {
        return false
    }
    
    // A stack of cards has been dropped in the ith tableau.
    func didDropFan(_ cards : [Card], onTableau i : Int) {
        
    }
    
    // Can user legally flip the card over?
    func canFlipCard(_ card : Card) -> Bool {
        return false
    }
    
    // The user did flip the card over.
    func didFlipCard(_ card : Card) {
        
    }
    
    // Can user move top card from stock to waste?
    func canDealCard() -> Bool {
        return false
    }
    
    // Uses did move the top stack card to the waste.
    func didDealCard() {
        
    }
    
    // Move all waste cards back to the stock (they’re all flipped over – order is maintained).
    func collectWasteCardsIntoStock() {
        
    }

}
