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
        frontImage = UIImage(named: imageForCard(card))! // load associated image from main bundle
        super.init()
        self.contents = frontImage.cgImage
        self.contentsGravity = kCAGravityResizeAspect
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // fatalError("init(coder:) has not been implemented")
    }
}

func imageForCard(_ card : Card) -> String {
    
    let ranks = ["", "a", "2", "3", "4", "5", "6", "7", "8", "9", "10", "j", "q", "k"]
    let ranksIndex = Int(card.rank)
    
    let imageName = "\(card.suit)-\(ranks[ranksIndex])-150"
    
    return imageName
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
    
    let FAN_OFFSET = CGFloat(1)
    
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
        
        let deck = Card.deck() // deck of poker cards
        cardToLayerDictionary = [:]
        
        var x : CGFloat = 200
        var y : CGFloat = 100
        var z : CGFloat = 0
        for card in deck {
            let cardLayer = CardLayer(card: card)

            cardLayer.bounds = CGRect(x: 0, y: 0, width: 150/3, height: 215/3)
            cardLayer.position = CGPoint(x: x, y: y)
            cardLayer.zPosition = z
            z = z + 1
            
            cardLayer.name = "card"
            self.layer.addSublayer(cardLayer)
            cardToLayerDictionary[card] = cardLayer
            
            //x = x + 5
            y = y + 5
        }
        topZPosition = z
    }
    
    override func layoutSublayers(of layer: CALayer) {
        draggingCardLayer = nil // deactivate any dragging
        //layoutTableAndCards()
    }
    
//    func layoutSublayersOfLayer(layer: CALayer) {
//        draggingCardLayer = nil // deactivate any dragging
//        layoutTableAndCards()
//    }
    
    func layoutTableAndCards() {
        let width = bounds.size.width
        let height = bounds.size.height
        let portrait = width < height
        
        //... determine size and position of stock, waste, foundation and tableau layers ...
        
        layoutCards()
    }
    
    func layoutCards() {
        var z : CGFloat = 1.0
        let stock = solitaire.stock
        for card in stock {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.frame = stockLayer.frame
            cardLayer.faceUp = solitaire.isCardFaceUp(card)
            z += 1.0
            cardLayer.zPosition = z
        }
        
        //... layout cards in waste and foundation stacks ...
        
        let cardSize = stockLayer.bounds.size
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
                z += 1.0
                cardLayer.zPosition = z
                j = j + 1.0
            }
        }
        topZPosition = z  // remember "highest position"
    }
    
    func moveToUpperLeft(_ clayer : CALayer) {
        let moveAnimation = CABasicAnimation(keyPath: "position")
        moveAnimation.duration = 0.1
        moveAnimation.fromValue = NSValue(cgPoint: clayer.position)
        let pos = CGPoint(x: 50, y: 50)
        moveAnimation.toValue = NSValue(cgPoint: pos)
        clayer.position = pos
        clayer.add(moveAnimation, forKey: "don't care") // You can give animation a key in order to kill it, etc
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
                        moveToUpperLeft(cardLayer)
                        return
                    }
                    //...else initiate drag of card (or stack of cards) by setting
                    // draggingCardLayer, and (possibly) draggingFan...
                    else {
                        touchStartPoint = touchPoint
                        
                        // TODO: Fix z position error
//                        cardLayer.zPosition = topZPosition
//                        topZPosition = topZPosition + 1
                        
                        touchStartLayerPosition = cardLayer.position
                        cardLayer.transform = CATransform3DIdentity
                        draggingCardLayer = cardLayer
                        
                        // XXX
                        draggingCardLayer!.zPosition = topZPosition
                        topZPosition += 1
                        // XXX
                        
                    }
                    
                } else if solitaire.canFlipCard(card) {
                    // flipCard(card, faceUp: true) // update model & view
                } else if solitaire.stock.last == card {
                    // dealCardsFromStockToWaste();
                }
            } else if (layer.name == "stock") {
                // collectWasteCardsIntoStock()
            }
        }
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
            
            //dragCardsToPosition(position: pos, animate: false)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        draggingCardLayer = nil
//        if let dragLayer = draggingCardLayer {
            //if dragging only one card {
                //... determine where the user is trying to drop the card
                //... determine if this is a valid/legal drop
                //... if so, update model and view
                //... else put card back from whence it came
            //} else { // fan of cards (can only drop on tableau stack)
                //... determine if valid/legal drop
                //... if so, update model and view
                //... else put cards back from whence they came
            //}
//            draggingCardLayer = nil
//        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        draggingCardLayer = nil
    }
}
