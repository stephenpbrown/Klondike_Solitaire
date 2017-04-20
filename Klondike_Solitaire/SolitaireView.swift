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
    
    let FAN_OFFSET = CGFloat(0.2)
    
    lazy var solitaire : Solitaire!  = { // reference to model in app delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.solitaire
    }()
    
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
        for i in 0 ..< 7 {
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
            let cardSize = (width: 150/4, height: 215/4)
            
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
                tableauLayers[i].position = CGPoint(x: x, y: 120)
                x += 58
            }
        }
        // Is an iPad and is in portrait mode
        else if portrait && isIpad {
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
            let cardSize = (width: 150/2, height: 215/2)
            
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
                tableauLayers[i].position = CGPoint(x: x, y: 250)
                x += 135
            }
        }
        // Is an iPhone and in landscape mode
        else
        {
            let cardSize = (width: 150/3, height: 215/3)
            
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
    
    func layoutCards() {
        var z : CGFloat = 1.0
        let stock = solitaire.stock
        for card in stock {
            z += 1.0
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.frame = stockLayer.frame
            cardLayer.faceUp = solitaire.isCardFaceUp(card)
            cardLayer.zPosition = z
            //z += 1.0
        }
        
        //... layout cards in waste and foundation stacks ...
        let waste = solitaire.waste
        z = 1.0
        for card in waste {
            z += 1.0
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.frame = wasteLayer.frame
            cardLayer.faceUp = solitaire.isCardFaceUp(card)
            cardLayer.zPosition = z
            //z += 1.0
        }
        
        let cardSize = stockLayer.bounds.size
        for i in 0 ..< 4 {
            let foundation = solitaire.foundation[i]
            let foundationOrigin = foundationLayers[i].frame.origin
            for card in foundation {
                z += 1.0
                let cardLayer = cardToLayerDictionary[card]!
                cardLayer.frame =
                    CGRect(x: foundationOrigin.x, y: foundationOrigin.y,
                           width: cardSize.width, height: cardSize.height)
                cardLayer.faceUp = solitaire.isCardFaceUp(card)
                cardLayer.zPosition = z
            }
        }

        let fanOffset = FAN_OFFSET * cardSize.height
        for i in 0 ..< 7 {
            let tableau = solitaire.tableau[i]
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
    
    func moveToFoundation(_ clayer : CALayer) {
        if let dragLayer = draggingCardLayer {
            var canDropCard : Bool = false
            for i in 0 ..< 4 {
                let foundation = solitaire.foundation[i]
                
                if foundation.isEmpty {
                    canDropCard = solitaire.canMoveCardToFoundation(dragLayer.card, onFoundation: i)
                    
                    if canDropCard {
                        let oldTableauPosition = solitaire.indexOfCardInTableau(dragLayer.card)
                        
                        solitaire.moveCardToFoundation(dragLayer.card, onFoundation: i)
                        
                        // Check to see if the card is from a tableau and the card below it can be flipped
                        if oldTableauPosition != -1 && !solitaire.tableau[oldTableauPosition].isEmpty {
                            let tableau = solitaire.tableau[oldTableauPosition]
                            
                            let canFlipCard = solitaire.canFlipCard(tableau.last!)
                            
                            if canFlipCard {
                                solitaire.flipTableauCard(tableau.last!)
                            }
                        }
                        
                        layoutCards()
                        break
                    }
                }
                
                for card in foundation {
                    let cardLayer = cardToLayerDictionary[card]!
                    
                    if cardLayer.frame.intersects(dragLayer.frame) {
                        
                        canDropCard = solitaire.canMoveCardToFoundation(dragLayer.card, onFoundation: i)
                        
                        if canDropCard {
                            let oldTableauPosition = solitaire.indexOfCardInTableau(dragLayer.card)
                            
                            solitaire.moveCardToFoundation(dragLayer.card, onFoundation: i)
                            
                            // Check to see if the card is from a tableau and the card below it can be flipped
                            if oldTableauPosition != -1 && !solitaire.tableau[oldTableauPosition].isEmpty {
                                let tableau = solitaire.tableau[oldTableauPosition]
                                
                                let canFlipCard = solitaire.canFlipCard(tableau.last!)
                                
                                if canFlipCard {
                                    solitaire.flipTableauCard(tableau.last!)
                                }
                            }
                            
                            layoutCards()
                            break
                        }
                    }
                }
            }
            if !canDropCard {
                dragLayer.position = touchStartLayerPosition
            }
            draggingCardLayer = nil
        }
    }

    
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
                        draggingCardLayer!.zPosition = topZPosition
                        topZPosition += 1
                        
                        // TODO: Check for draggingFan
                    }
                    
                } else if solitaire.canFlipCard(card) {
                    flipCard(card, faceUp: true) // update model & view
                }
//                else if solitaire.stock.last == card {
//                    
//                }

            } else if (layer.name == "stock") {
                solitaire.collectWasteCardsIntoStock()
                layoutCards()
            }
        }
    }
    
    func flipCard(_ card : Card, faceUp : Bool) {
        
        if solitaire.stock.contains(card) {
            solitaire.stockToWaste(card)
        }
        else if solitaire.foundation.contains(where: { $0 == [card]}) {
            // XXX
        }
        else {
            solitaire.flipTableauCard(card)
        }
        
        layoutCards()
    }
    
    func dragCardsToPosition(position : CGPoint, animate : Bool) {
        if !animate {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
        }
        
        draggingCardLayer!.position = position
        if let draggingFan = draggingFan {
            let off = FAN_OFFSET*draggingCardLayer!.bounds.size.height
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
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let dragLayer = draggingCardLayer {
            var canDropCard : Bool = false
            
            //
            // Check to see if a card can be set into the foundation
            //
            for i in 0 ..< 4 {
                let foundation = solitaire.foundation[i]
                
                if foundation.isEmpty {
                    canDropCard = solitaire.canMoveCardToFoundation(dragLayer.card, onFoundation: i)
                    
                    if canDropCard {
                        let oldTableauPosition = solitaire.indexOfCardInTableau(dragLayer.card)
                        
                        solitaire.moveCardToFoundation(dragLayer.card, onFoundation: i)
                        
                        // Check to see if the card is from a tableau and the card below it can be flipped
                        if oldTableauPosition != -1 && !solitaire.tableau[oldTableauPosition].isEmpty {
                            let tableau = solitaire.tableau[oldTableauPosition]
                            
                            let canFlipCard = solitaire.canFlipCard(tableau.last!)
                            
                            if canFlipCard {
                                solitaire.flipTableauCard(tableau.last!)
                            }
                        }
                        layoutCards()
                        
                        // XXXXXXXX
                        // canDropCard gets reset back to false which is causing an error
                        // XXXXXXXX
                        break
                    }
                }
                
                for card in foundation {
                    let cardLayer = cardToLayerDictionary[card]!
                    
                    if cardLayer.frame.intersects(dragLayer.frame) {
                        
                        canDropCard = solitaire.canMoveCardToFoundation(dragLayer.card, onFoundation: i)
                        
                        if canDropCard {
                            let oldTableauPosition = solitaire.indexOfCardInTableau(dragLayer.card)
                            
                            solitaire.moveCardToFoundation(dragLayer.card, onFoundation: i)
                            
                            // Check to see if the card is from a tableau and the card below it can be flipped
                            if oldTableauPosition != -1 && !solitaire.tableau[oldTableauPosition].isEmpty {
                                let tableau = solitaire.tableau[oldTableauPosition]
                                
                                let canFlipCard = solitaire.canFlipCard(tableau.last!)
                                
                                if canFlipCard {
                                    solitaire.flipTableauCard(tableau.last!)
                                }
                            }
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
                    
                    if tableau.isEmpty {
                        canDropCard = solitaire.canDropCard(dragLayer.card, onTableau: i)
                        
                        if canDropCard {
                            let oldTableauPosition = solitaire.indexOfCardInTableau(dragLayer.card)
                            solitaire.didDropCard(dragLayer.card, onTableau: i)
                            
                            // Check to see if the card is from a tableau and the card below it can be flipped
                            if oldTableauPosition != -1 && !solitaire.tableau[oldTableauPosition].isEmpty {
                                tableau = solitaire.tableau[oldTableauPosition]
                                
                                let canFlipCard = solitaire.canFlipCard(tableau.last!)
                                
                                if canFlipCard {
                                    solitaire.flipTableauCard(tableau.last!)
                                }
                            }
                            layoutCards()
                            break
                        }
                    }
                    
                    for card in tableau {
                        let cardLayer = cardToLayerDictionary[card]!
                        if cardLayer.frame.intersects(dragLayer.frame) {
                            canDropCard = solitaire.canDropCard(dragLayer.card, onTableau: i)
                            
                            if canDropCard {
                                let oldTableauPosition = solitaire.indexOfCardInTableau(dragLayer.card)
                                solitaire.didDropCard(dragLayer.card, onTableau: i)
                                
                                // Check to see if the card is from a tableau and the card below it can be flipped
                                if oldTableauPosition != -1 && !solitaire.tableau[oldTableauPosition].isEmpty {
                                    
                                    tableau = solitaire.tableau[oldTableauPosition]
                                    let canFlipCard = solitaire.canFlipCard(tableau.last!)
                                    
                                    if canFlipCard {
                                        solitaire.flipTableauCard(tableau.last!)
                                    }
                                }
                                layoutCards()
                                break
                            }
                        }
                    }
                }
            }
            //
            // If the card can't be dropped, move it back to its previous position
            //
            if !canDropCard {
                dragLayer.position = touchStartLayerPosition
            }
//                ... determine where the user is trying to drop the card
//                ... determine if this is a valid/legal drop
//                ... if so, update model and view
//                ... else put card back from whence it came
//            } else { // fan of cards (can only drop on tableau stack)
//                ... determine if valid/legal drop
//                ... if so, update model and view
//                ... else put cards back from whence they came
//            }
            draggingCardLayer = nil
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        draggingCardLayer = nil
    }
}
