//
//  DustSprite.swift
//  Lira
//
//  Created by Nadiia Iva on 27/08/2025.
//


import SpriteKit

class DustSprite: SKSpriteNode {
    init() {
        let texture = SKTexture(imageNamed: "dust_1")
        super.init(texture: texture, color: .clear, size: texture.size())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimation() {
        let textures = [
            SKTexture(imageNamed: "dust_1"),
            SKTexture(imageNamed: "dust_2")
        ]
        let animation = SKAction.animate(with: textures, timePerFrame: 0.5)
        let repeatAction = SKAction.repeatForever(animation)
        self.run(repeatAction, withKey: "dustAnimation")
    }
    
    
    func setHeight(_ targetHeight: CGFloat) {
        let scale = targetHeight / size.height
        self.setScale(scale)
    }
}
