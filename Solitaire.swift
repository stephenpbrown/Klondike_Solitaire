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
        for r in 0 ..< 7 {
            tableau.append([])
            for c in 0 ... r {
                tableau[r].append(setRegions.last!)
                
                // Set bottom cards face up
                if r == c {
                    faceUpCards.insert(setRegions.last!)
                }
                setRegions.removeLast()
            }
        }
        
        for _ in 0 ..< 4 {
            foundation.append([])
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

    // All cards have successfully reached a foundation stack.
    func gameWon() -> Bool {
        return foundation.count == 52
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
    
    // Can the given card be legally dropped on the ith tableau?
    func canDropCard(_ card : Card, onTableau i : Int) -> Bool {
        
        // King on an empty layer
        if tableau[i].isEmpty && card.rank == 13 {
            return true
        }
        else if tableau[i].isEmpty && card.rank != 13 {
            return false
        }
        
        let lowerCard = tableau[i].last
        
        let val1 = lowerCard!.suit.hashValue
        let val2 = card.suit.hashValue
        let addition = val1 + val2
        
        // TODO: Fix why sometimes the lowerCard and card are the same card
        if ((lowerCard?.rank)! - 1) == card.rank {
            if addition > 1 && addition < 5 {
                return true
            }
        }
        
        return false
    }
    
    // The user did drop the card on the on the ith tableau.
    func didDropCard(_ card : Card, onTableau i : Int) {
        //tableau[i].append(card)
        
        for k in 0 ..< 7 {
            if tableau[k].last == card {
                tableau[k].removeLast()
            }
        }
        
        if waste.contains(card) {
            let index = waste.index(of: card)
            waste.remove(at: index!)
        }
        
        tableau[i].append(card)
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
        
        if card == stock.last {
            return true
        }
        
        for r in 0 ..< 7 {
            for c in 0 ... r {
                if card == tableau[r][c] {
                    return true
                }
            }
        }
        
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
    
    func flipTableauCard(_ card: Card) {
        faceUpCards.insert(card)
    }
    
    func stockToWaste(_ card: Card) {
        waste.append(card)
        faceUpCards.insert(card)
        stock.removeLast()
    }
    
    func indexOfCardInTableau(_ card: Card) -> Int {
        for i in 0 ..< 7 {
            if tableau[i].last == card {
                return i
            }
        }
        
        return -1
    }
    
    // Move all waste cards back to the stock (they’re all flipped over – order is maintained).
    func collectWasteCardsIntoStock() {
        for card in waste {
            stock.append(card)
            faceUpCards.remove(card)
            waste.removeFirst()
        }
        
        stock.reverse()
    }

}
