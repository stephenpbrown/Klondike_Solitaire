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
    fileprivate var faceUpCards : Set<Card>;
    
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
        foundation = [[]] //Array(repeating: [Card](), count: 52)
        
        self.tableau = [[]] //Array(repeating: [Card](), count: 52)
        
        faceUpCards = []
    }
    
    // Takes deck of cards and then randomly reorders (shuffles) them
    func dealCards() -> [Card] {
        var deckOfCards = [Card]()
        
        for s in 0 ..< 4 {
            for r in 1 ... 13 {
                deckOfCards.append(Card(suit: Suit(rawValue: UInt8(s))!, rank: UInt8(r)))
            }
        }
        
        var shuffledDeck = [Card]()
        var randomIndex = 0
        
        // Shuffles the deck of cards
        for _ in 0 ..< 52 {
            randomIndex = Int(arc4random_uniform(UInt32(deckOfCards.count)))
            shuffledDeck.append(deckOfCards[randomIndex])
            deckOfCards.remove(at: randomIndex)
        }
        
        var setRegions = shuffledDeck
        
        // TODO: Figure out why these contain an empty object on initialization
        tableau.remove(at: 0)
        foundation.remove(at: 0)
        
        // Figure out which cards go into the tableau
        for c in 0 ..< 7 {
            for r in 0 ... c {
                randomIndex = Int(arc4random_uniform(UInt32(setRegions.count)))
                
                // http://stackoverflow.com/questions/28163034/how-to-properly-declare-array-of-custom-objects-in-swift
                tableau.append([])
                tableau[c].append(setRegions[randomIndex])
                
                // Set bottom cards face up
                if r == c {
                    faceUpCards.insert(setRegions[randomIndex])
                }
                setRegions.remove(at: randomIndex)
            }
        }
        
        // The rest of the cards go into the stock
        for card in setRegions {
            stock.append(card)
        }
        
        return shuffledDeck
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
        return faceUpCards.contains(card)
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
