//
//  SolitaireView.swift
//  Klondike_Solitaire
//
//  Created by Stephen Paul Brown on 4/13/17.
//  Copyright © 2017 Stephen Paul Brown. All rights reserved.
//

import UIKit

class CardLayer: CALayer {
    var card : Card
    
    var faceUp : Bool {
        didSet {
            if faceUp != oldValue {
                let image = faceUp ? frontImage : CardLayer.backImage
                self.contents = image?.cgImage
            }
        }
    }
    
    let frontImage : UIImage
    static let backImage = UIImage(named: "back-blue-150-4")
    
    init(card : Card) {
        self.card = card
        faceUp = true
        frontImage = imageForCard(card) // load associated image from main bundle
        super.init()
        self.contents = frontImage.cgImage
        self.contentsGravity = kCAGravityResizeAspect
    }
    
    //
    // Professor Cochran helped me solve the issue where the program would throw an error because I
    // wasn't handling the initializers properly
    //
    override init(layer: Any) {
        if let layer = layer as? Card {
            card = Card(suit: layer.suit, rank: layer.rank)
            faceUp = true
            frontImage = imageForCard(card)
        }
        else {
            card = Card(suit: Suit.spades, rank: ace)
            faceUp = true
            frontImage = imageForCard(card)
        }
        super.init(layer: layer)
        self.contents = frontImage.cgImage
        self.contentsGravity = kCAGravityResizeAspect
    }
    
    required init?(coder aDecoder: NSCoder) {
        card = Card(suit: Suit.spades, rank: ace)
        faceUp = true
        frontImage = imageForCard(card)
        super.init(coder: aDecoder)
    }
}

func imageForCard(_ card : Card) -> UIImage {
    
    let ranks = ["", "a", "2", "3", "4", "5", "6", "7", "8", "9", "10", "j", "q", "k"]
    let ranksIndex = Int(card.rank)
    
    let imageName = "\(card.suit)-\(ranks[ranksIndex])-150"
    
    return UIImage(named: imageName)!
}

class SolitaireView: UIView {
    

    var stockLayer : CALayer!
    var wasteLayer : CALayer!
    var foundationLayers : [CALayer]!  // four foundation layers
    var tableauLayers : [CALayer]!     // seven tableau layers
    
    var topZPosition : CGFloat = 0  // "highest" z-value of all card layers
    var cardToLayerDictionary : [Card : CardLayer]! // map card to it’s layer
    
    var draggingCardLayer : CardLayer? = nil // card layer dragged (nil => no drag)
    var draggingFan : [Card]? = nil          // fan of cards dragged
    var touchStartPoint : CGPoint = CGPoint.zero
    var touchStartLayerPosition : CGPoint = CGPoint.zero
    
    var cardCount : [Int] = [0]
    
    var canDropCard : Bool = false
    
    var FAN_OFFSET = CGFloat(0.3)
    
    var FAN_OFFSET_ARRAY : [CGFloat] = [CGFloat(0)]
    
    var deckForAnimating : [Card] = []
    
    lazy var solitaire : Solitaire!  = { // reference to model in app delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.solitaire
    }()
    
    func resetGame() {
        solitaire.freshGame()
        
        // Quick delay that allows the cards to be consistently animated when a new game is selected
        DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(1), execute: {
            self.layoutCards()
        })
    }
    
    override func awakeFromNib() {
        self.layer.name = "background"
        
        stockLayer = CALayer()
        stockLayer.name = "stock"
        stockLayer.backgroundColor =
            UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 0.3).cgColor
        self.layer.addSublayer(stockLayer)
            
        //    ... create and add waste, foundation, and tableau sublayers ...
        wasteLayer = CALayer()
        wasteLayer.name = "waste"
        wasteLayer.backgroundColor =
            UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 0.3).cgColor
        self.layer.addSublayer(wasteLayer)
        
        tableauLayers = []
        FAN_OFFSET_ARRAY = []
        for i in 0 ..< 7 {
            FAN_OFFSET_ARRAY.append(CGFloat(FAN_OFFSET))
            cardCount.append(0)
            tableauLayers.append(CALayer())
            tableauLayers[i].name = "tableau"
            tableauLayers[i].backgroundColor =
                UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 0.3).cgColor
            self.layer.addSublayer(tableauLayers[i])
        }
        
        foundationLayers = []
        for i in 0 ..< 4 {
            foundationLayers.append(CALayer())
            foundationLayers[i].name = "foundation"
            foundationLayers[i].backgroundColor =
                UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 0.3).cgColor
            self.layer.addSublayer(foundationLayers[i])
        }
        
        let deck = Card.deck() // deck of poker cards
        cardToLayerDictionary = [:]
        for card in deck {
            let cardLayer = CardLayer(card: card)
            cardLayer.name = "card"
            self.layer.addSublayer(cardLayer)
            cardToLayerDictionary[card] = cardLayer
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        draggingCardLayer = nil // deactivate any dragging
        layoutTableAndCards()
    }
    
    func layoutTableAndCards() {
        let width = bounds.size.width
        let height = bounds.size.height
        let portrait = width < height
        let isIpad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        
        //... determine size and position of stock, waste, foundation and tableau layers ...
        
        // Is an iPhone and in portrait mode
        if portrait && !isIpad {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kOrientationChangedToPortrait), object: nil)
            
            let cardSize = (width: 150/3, height: 215/3)
            
            // Stock layer position
            stockLayer.bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
            stockLayer.position = CGPoint(x: 30, y: 50)
            
            // Waste layer position
            wasteLayer.bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
            wasteLayer.position = CGPoint(x: 88, y: 50)
            
            // Foundation layer positions
            var x = 204
            for i in 0 ..< 4 {
                foundationLayers[i].bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
                foundationLayers[i].position = CGPoint(x: x, y: 50)
                x += 58
            }
            
            // Tableau layer positions
            x = 30
            for i in 0 ..< 7 {
                tableauLayers[i].bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
                tableauLayers[i].position = CGPoint(x: x, y: 150)
                x += 58
            }
        }
        // Is an iPad and is in portrait mode
        else if portrait && isIpad {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kOrientationChangedToPortrait), object: nil)
            
            let cardSize = (width: 150/2, height: 215/2)
            
            // Stock layer position
            stockLayer.bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
            stockLayer.position = CGPoint(x: 80, y: 100)
            
            // Waste layer position
            wasteLayer.bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
            wasteLayer.position = CGPoint(x: 180, y: 100)
            
            // Foundation layer positions
            var x = 380
            for i in 0 ..< 4 {
                foundationLayers[i].bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
                foundationLayers[i].position = CGPoint(x: x, y: 100)
                x += 100
            }
            
            // Tableau layer positions
            x = 80
            for i in 0 ..< 7 {
                tableauLayers[i].bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
                tableauLayers[i].position = CGPoint(x: x, y: 250)
                x += 100
            }
        }
        // Is an iPad and is in landscape mode
        else if !portrait && isIpad {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kOrientationChangedToLandscape), object: nil)
            
            let cardSize = (width: 190/2, height: 265/2)
            
            // Stock layer position
            stockLayer.bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
            stockLayer.position = CGPoint(x: 100, y: 100)
            
            // Waste layer position
            wasteLayer.bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
            wasteLayer.position = CGPoint(x: 235, y: 100)
            
            // Foundation layer positions
            var x = 505
            for i in 0 ..< 4 {
                foundationLayers[i].bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
                foundationLayers[i].position = CGPoint(x: x, y: 100)
                x += 135
            }
            
            // Tableau layer positions
            x = 100
            for i in 0 ..< 7 {
                tableauLayers[i].bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
                tableauLayers[i].position = CGPoint(x: x, y: 270)
                x += 135
            }
        }
        // Is an iPhone and in landscape mode
        else
        {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kOrientationChangedToLandscape), object: nil)
            
            let cardSize = (width: 120/2, height: 175/2)
            
            // Stock layer position
            stockLayer.bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
            stockLayer.position = CGPoint(x: 70, y: 50)
            
            // Waste layer position
            wasteLayer.bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
            wasteLayer.position = CGPoint(x: 170, y: 50)
            
            // Foundation layer positions
            var x = 370
            for i in 0 ..< 4 {
                foundationLayers[i].bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
                foundationLayers[i].position = CGPoint(x: x, y: 50)
                x += 100
            }
            
            // Tableau layer positions
            x = 70
            for i in 0 ..< 7 {
                tableauLayers[i].bounds = CGRect(x: 0, y: 0, width: cardSize.width, height: cardSize.height)
                tableauLayers[i].position = CGPoint(x: x, y: 150)
                x += 100
            }
        }
        
        layoutCards()
    }
    
    // Layout the cards into their respective layers
    func layoutCards() {
        
        var z : CGFloat = 1.0
        //... layout cards in waste and foundation stacks ...
        let waste = solitaire.waste
        for card in waste {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.frame = wasteLayer.frame
            cardLayer.faceUp = solitaire.isCardFaceUp(card)
            cardLayer.zPosition = z
            z += 1.0
        }
        
        //z = 1.0
        let stock = solitaire.stock
        for card in stock {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.frame = stockLayer.frame
            cardLayer.faceUp = solitaire.isCardFaceUp(card)
            cardLayer.zPosition = z
            z += 1.0
        }
        
        //z = 1.0
        let cardSize = stockLayer.bounds.size
        for i in 0 ..< 4 {
            let foundation = solitaire.foundation[i]
            let foundationOrigin = foundationLayers[i].frame.origin
            for card in foundation {
                let cardLayer = cardToLayerDictionary[card]!
                cardLayer.frame =
                    CGRect(x: foundationOrigin.x, y: foundationOrigin.y,
                           width: cardSize.width, height: cardSize.height)
                cardLayer.faceUp = solitaire.isCardFaceUp(card)
                cardLayer.zPosition = z
                z += 1.0
            }
        }
        
        //z = 1.0
        //let fanOffset = FAN_OFFSET * cardSize.height
        for i in 0 ..< 7 {
            var fanOffset = FAN_OFFSET_ARRAY[i] * cardSize.height
            
            let tableau = solitaire.tableau[i]
            let lowestPointCard = tableau.last
            var lowestPointLayer = CALayer()
            var lowestPoint = CGFloat(0)
            let height = bounds.size.height
            
            if lowestPointCard != nil {
                lowestPointLayer = cardToLayerDictionary[lowestPointCard!]!
                lowestPoint = lowestPointLayer.position.y + cardSize.height
            }
            
            if lowestPoint > height {
                FAN_OFFSET_ARRAY[i] = CGFloat(0.2)
                fanOffset = FAN_OFFSET_ARRAY[i] * cardSize.height
                cardCount[i] = tableau.count
            }
            else if cardCount[i] > tableau.count {
                FAN_OFFSET_ARRAY[i] = CGFloat(0.3)
                fanOffset = FAN_OFFSET_ARRAY[i] * cardSize.height
                cardCount[i] = tableau.count
            }
            
            let tableauOrigin = tableauLayers[i].frame.origin
            var j : CGFloat = 0
            for card in tableau {
                let cardLayer = cardToLayerDictionary[card]!
                cardLayer.frame =
                    CGRect(x: tableauOrigin.x, y: tableauOrigin.y + j*fanOffset,
                           width: cardSize.width, height: cardSize.height)
                cardLayer.faceUp = solitaire.isCardFaceUp(card)
                cardLayer.zPosition = z
                z += 1.0
                j += 1.0
            }
        }
        topZPosition = z  // remember "highest position"
    }
    
    // Moves the card to the foundation with a double click
    func moveToFoundation(_ clayer : CALayer) {
        if let dragLayer = draggingCardLayer {
            canDropCard = false
            for i in 0 ..< 4 {
                let foundation = solitaire.foundation[i]
                
                // If the foundation is empty, checks to see if the card is an ace and can be dropped
                if foundation.isEmpty {
                    let didDropOnFoundation = dropCardOnFoundation(onFoundation: i)
                    
                    if didDropOnFoundation {
                        layoutCards()
                        break
                    }
                }
                // Otherwise checks to see if the cards collided are compatible
                else {
                    let didDropOnFoundation = dropCardOnFoundation(onFoundation: i)
                    
                    if didDropOnFoundation {
                        layoutCards()
                        break
                    }
                }
                if canDropCard {
                    break
                }
            }
            if !canDropCard {
                dragLayer.position = touchStartLayerPosition
                layoutCards()
            }
            draggingCardLayer = nil
        }
    }

    // A card was touched
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let touchPoint = touch.location(in: self)
        let hitTestPoint = self.layer.convert(touchPoint, to: self.layer.superlayer)

        if let layer = self.layer.hitTest(hitTestPoint) {
            if layer.name == "card" {
                let cardLayer = layer as! CardLayer
                let card = cardLayer.card
                if solitaire.isCardFaceUp(card) {
                    //...if tap count > 1 move to foundation if allowed...
                    if touch.tapCount > 1 {
                        touchStartPoint = touchPoint
                        touchStartLayerPosition = cardLayer.position
                        cardLayer.transform = CATransform3DIdentity
                        draggingCardLayer = cardLayer
                        draggingCardLayer!.zPosition = topZPosition
                        topZPosition += 1
                        moveToFoundation(cardLayer)
                        return
                    }
                    //...else initiate drag of card (or stack of cards) by setting
                    // draggingCardLayer, and (possibly) draggingFan...
                    else {
                        
                        touchStartPoint = touchPoint
                        touchStartLayerPosition = cardLayer.position
                        cardLayer.transform = CATransform3DIdentity
                        draggingCardLayer = cardLayer
                        
                        draggingFan = solitaire.fanBeginningWithCard(card)
                        
                        if draggingFan == nil {
                            draggingCardLayer!.zPosition = topZPosition
                            topZPosition += 1
                        }
                            
                        // Set the zPositioning of all the cards in the fan to be above the other cards
                        else {
                            for card in draggingFan! {
                                let cardLayer = cardToLayerDictionary[card]
                                cardLayer?.zPosition = topZPosition
                                topZPosition += 1
                            }
                        }
                    }
                    
                }
                else if solitaire.canFlipCard(card) {
                    flipCard(card, faceUp: true) // update model & view
                }
            }
            else if (layer.name == "stock") {
                solitaire.collectWasteCardsIntoStock()
                layoutCards()
            }
        }
    }
    
    //
    // Check to see if the card can be flipped
    //
    func flipCard(_ card : Card, faceUp : Bool) {
        
        if solitaire.stock.contains(card) {
            solitaire.stockToWaste(card)
        }
        else {
            for i in 0 ..< 7 {
                let tableau = solitaire.tableau[i]
                if tableau.last == card {
                    solitaire.flipTableauCard(card)
                }
            }
        }
        layoutCards()
    }
    
    // Drags a fan around the screen
    func dragCardsToPosition(position : CGPoint, animate : Bool) {
        if !animate {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
        }
        
        draggingCardLayer!.position = position
        if let draggingFan = draggingFan {
            let off = 0.4*draggingCardLayer!.bounds.size.height
            let n = draggingFan.count
            for i in 1 ..< n {
                let card = draggingFan[i]
                let cardLayer = cardToLayerDictionary[card]!
                cardLayer.position = CGPoint(x: position.x, y: position.y + CGFloat(i)*off)
            }
        }
        
        if !animate {
            CATransaction.commit()
        }
    }
    
    // Moves the cards around the screen
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touchLayer = draggingCardLayer {
            let touch = touches.first
            let touchPoint = touch!.location(in: self)
            let delta = CGPoint(x: touchPoint.x - touchStartPoint.x, y: touchPoint.y - touchStartPoint.y)
            let pos = CGPoint(x: touchStartLayerPosition.x + delta.x, y: touchStartLayerPosition.y + delta.y)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true) // Turn off animation
            touchLayer.position = pos
            CATransaction.commit()
            
            dragCardsToPosition(position: pos, animate: false)
        }
    }
    
    // Checks to see if a fan can be dropped and drops if it can
    func dropFan(onTableau i: Int) -> Bool {
        let topFanCard = draggingFan?.first
        canDropCard = solitaire.canDropCard(topFanCard!, onTableau: i)
        
        if canDropCard {
            let oldTableauPosition = solitaire.indexOfCardInTableau(topFanCard!)
            solitaire.didDropFan(draggingFan!, onTableau: i)
            
            // Check to see if the card is from a tableau and the card below it can be flipped
            if oldTableauPosition != -1 && !solitaire.tableau[oldTableauPosition].isEmpty {
                let tableau = solitaire.tableau[oldTableauPosition]
                
                let canFlipCard = solitaire.canFlipCard(tableau.last!)
                
                if canFlipCard {
                    solitaire.flipTableauCard(tableau.last!)
                }
            }
            return true
        }
        return false
    }
    
    // Checks to see if a single card can be dropped and drops it if it can
    func dropCard(onTableau i: Int) -> Bool {
        let card = draggingCardLayer?.card
        canDropCard = solitaire.canDropCard(card!, onTableau: i)
        
        if canDropCard {
            let oldTableauPosition = solitaire.indexOfCardInTableau(card!)
            solitaire.didDropCard(card!, onTableau: i)
            
            // Check to see if the card is from a tableau and the card below it can be flipped
            if oldTableauPosition != -1 && !solitaire.tableau[oldTableauPosition].isEmpty {
                let tableau = solitaire.tableau[oldTableauPosition]
                
                let canFlipCard = solitaire.canFlipCard(tableau.last!)
                
                if canFlipCard {
                    solitaire.flipTableauCard(tableau.last!)
                }
            }
            return true
        }
        return false
    }
    
    // Checks to see if a card can be dropped on a foundation and drops it if it can
    func dropCardOnFoundation(onFoundation i : Int) -> Bool {
        let card = draggingCardLayer?.card
        canDropCard = solitaire.canMoveCardToFoundation(card!, onFoundation: i)
        
        if canDropCard {
            let oldTableauPosition = solitaire.indexOfCardInTableau(card!)
            
            solitaire.moveCardToFoundation(card!, onFoundation: i)
            
            // Check to see if the card is from a tableau and the card below it can be flipped
            if oldTableauPosition != -1 && !solitaire.tableau[oldTableauPosition].isEmpty {
                let tableau = solitaire.tableau[oldTableauPosition]
                
                let canFlipCard = solitaire.canFlipCard(tableau.last!)
                
                if canFlipCard {
                    solitaire.flipTableauCard(tableau.last!)
                }
            }
            return true
        }
        
        return false
    }
    
    // Touch has ended
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let dragLayer = draggingCardLayer {
            canDropCard = false
            if draggingFan != nil { // fan of cards (can only drop on tableau stack)
                for i in 0 ..< 7 {
                    var tableau = solitaire.tableau[i]
                    
                    // Checks to see if the spot is empty and the card going on it is a king
                    if tableau.isEmpty {
                        let didDropFan = dropFan(onTableau: i)
                        
                        if didDropFan {
                            layoutCards()
                            break
                        }
                    }
                    
                    // If the spot isn't empty, then see if the top card can be dropped on it
                    if !tableau.isEmpty {
                        let topCard = tableau.last!
                        let cardLayer = cardToLayerDictionary[topCard]!
                        if cardLayer.frame.intersects(dragLayer.frame) {
                            let didDropFan = dropFan(onTableau: i)
                            
                            if didDropFan {
                                layoutCards()
                                break
                            }
                        }
                    }
                    
                    if canDropCard {
                        break
                    }
                }
            }
            else {
                //
                // Check to see if a card can be set into the foundation
                //
                for i in 0 ..< 4 {
                    let foundation = solitaire.foundation[i]
                    
                    // Checks to see if the spot is empty and that the ace intersects with an empty spot
                    if foundation.isEmpty && dragLayer.frame.intersects(foundationLayers[i].frame) {
                        let didDropOnFoundation = dropCardOnFoundation(onFoundation: i)
                        
                        if didDropOnFoundation {
                            layoutCards()
                            break
                        }
                        
                    }
                    
                    // If the foundation isn't empty, checks for collision with a card and then see if it can be moved
                    if !foundation.isEmpty {
                        let topCard = foundation.last!
                        let cardLayer = cardToLayerDictionary[topCard]!
                        
                        if cardLayer.frame.intersects(dragLayer.frame) {
                            let didDropOnFoundation = dropCardOnFoundation(onFoundation: i)
                            
                            if didDropOnFoundation {
                                layoutCards()
                                break
                            }
                        }
                    }
                }
                
                //
                // Check to see if the card can be set into the tableau
                //
                if !canDropCard {
                    for i in 0 ..< 7 {
                        var tableau = solitaire.tableau[i]
                        
                        // Checks to see if the spot is empty and that the king intersects with an empty spot
                        if tableau.isEmpty && dragLayer.card.rank == king {
                            let cardLayer = cardToLayerDictionary[dragLayer.card]!
                            
                            if cardLayer.frame.intersects(tableauLayers[i].frame) {
                                let didDropCard = dropCard(onTableau: i)
                                
                                if didDropCard {
                                    layoutCards()
                                    break
                                }
                            }
                        }
                        
                        // If the tableau spot isn't empty, it checks to see if two cards collided and checks if it can be moved
                        if !tableau.isEmpty {
                            let topCard = tableau.last!
                            let cardLayer = cardToLayerDictionary[topCard]!
                            if cardLayer.frame.intersects(dragLayer.frame) {
                                let didDropCard = dropCard(onTableau: i)
                                
                                if didDropCard {
                                    layoutCards()
                                    break
                                }
                            }
                        }
                        if canDropCard {
                            break
                        }
                    }
                }
            }
            //
            // If the card can't be dropped, move it back to its previous position
            //
            if !canDropCard {
                dragLayer.position = touchStartLayerPosition
                layoutCards()
            }
            draggingCardLayer = nil
        }
        
        // Funcation that scatters cards around the window when the player wins
        func scatterCardsAnimChain(_ i : Int) {
            if i >= 0 {
                let card = deckForAnimating[i]
                let clayer = cardToLayerDictionary[card]
                CATransaction.begin()
                
                CATransaction.setDisableActions(true)
                clayer?.zPosition = topZPosition
                CATransaction.commit()
                topZPosition += 1
                
                CATransaction.begin()
                CATransaction.setCompletionBlock { // Rescursive call
                    scatterCardsAnimChain(i - 1)
                }
                CATransaction.setAnimationDuration(0.095)
                let x = CGFloat(drand48())*bounds.width
                let y = CGFloat(drand48())*bounds.height
                clayer?.position = CGPoint(x: x, y: y)
                clayer?.transform = CATransform3DIdentity
                CATransaction.commit()
            }
        }
        
        func scatterCards() {
            scatterCardsAnimChain(51)
        }
        
        // Checks to see if the game has been won by checking if the foundation contains 52 cards
        if solitaire.gameWon() {
            let foundation = solitaire.foundation
            
            // Grabs all the cards from the foundation
            for i in 0 ..< 4 {
                for card in foundation[i] {
                    deckForAnimating.append(card)
                }
            }
            
            // Scatters those cards around the screen
            scatterCards()
 
            // Disable the user interface while the cards are scattering
            self.isUserInteractionEnabled = false
            
            // Creates a 5 second timer for the animation to finish before the user interface is enabled and a modal view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
                self.isUserInteractionEnabled = true
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: kGameWon), object: nil)
            })
        }
    }
    
    func undo() {
        undoManager?.undo()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        draggingCardLayer = nil
    }
}
