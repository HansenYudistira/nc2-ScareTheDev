//
//  GameScene.swift
//  game_2d
//
//  Created by Hansen Yudistira on 19/05/24.
//

import Foundation
import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    var ghost = SKSpriteNode()
    var ghostTexture = SKTexture(imageNamed: "ghost")
    
    var human = SKSpriteNode()
    var humanTexture = SKTexture(imageNamed: "human")
    
    var playerMovedRight = false
    var playerMovedLeft = false
    var playerLookRight = true
    var playerLookLeft = false
    var isGhostControlled = true
    var isGameOver = false
    
    var startPoint = CGPoint()
    var touchPoint = CGPoint()
    
    let humanFrameNames = ["humanIdle", "humanConfused", "humanCaught", "humanSurprised", "humanFall"]
    var humanFrames = [SKTexture]()
    var textureAtlasHuman = SKTextureAtlas(named: "humanAnimation")
    
    var audioPlayer: AVAudioPlayer?
    let humanSounds = ["humanSound1", "humanSound2", "humanSound3"]
    
    enum bitMasks: UInt32 {
        case ghost = 0b1
        case ground = 0b10
        case human = 0b100
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        for node in self.children {
            if(node.name == "PhysicsMap") {
                if let someTileMap: SKTileMapNode = node as? SKTileMapNode {
                    tileMapPhysicsBody(map: someTileMap)
                    
                    someTileMap.removeFromParent()
                }
            }
        }
        
        for frameName in humanFrameNames {
            let texture = textureAtlasHuman.textureNamed(frameName)
            humanFrames.append(texture)
        }
        
        addGhost()
        addHuman()
        animateHumanRandomlyWithSound()
    }
    
    func addGhost() {
        ghost = childNode(withName: "ghost") as! SKSpriteNode
        ghost.physicsBody = SKPhysicsBody(texture: ghost.texture!, size: ghost.size)
        ghost.physicsBody?.allowsRotation = false
        ghost.physicsBody?.categoryBitMask = bitMasks.ghost.rawValue
        ghost.physicsBody?.contactTestBitMask = bitMasks.ground.rawValue
        ghost.physicsBody?.collisionBitMask = bitMasks.ground.rawValue
        ghost.alpha = 0.5
    }
    
    func addHuman() {
        human = childNode(withName: "human") as! SKSpriteNode
        human.physicsBody = SKPhysicsBody(texture: humanTexture, size: human.size)
        human.physicsBody?.allowsRotation = false
        human.physicsBody?.categoryBitMask = bitMasks.human.rawValue
        human.physicsBody?.contactTestBitMask = bitMasks.ground.rawValue | bitMasks.ghost.rawValue
        human.physicsBody?.collisionBitMask = bitMasks.ground.rawValue | bitMasks.ghost.rawValue
    }
    
    func animateHumanRandomlyWithSound() {
        let lookRightAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            human.texture = humanFrames[0]
            self.human.xScale = abs(self.human.xScale)
        }
        
        let lookLeftAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            human.texture = humanFrames[0]
            self.human.xScale = -abs(self.human.xScale)
        }
        
        let waitAction = SKAction.wait(forDuration: TimeInterval(arc4random_uniform(5) + 1))
        let wait2Seconds = SKAction.wait(forDuration: 2.0)

        let playSoundAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            playRandomHumanSound()
        }
        
        let sequence = SKAction.sequence([
            waitAction,
            lookRightAction,
            playSoundAction,
            wait2Seconds,
            lookLeftAction,
            wait2Seconds,
            lookRightAction,
        ])
        
        human.run(SKAction.repeatForever(sequence))
    }
    
    func playRandomHumanSound() {
        guard let randomSoundName = humanSounds.randomElement() else {
            return
        }
        
        guard let soundURL = Bundle.main.url(forResource: randomSoundName, withExtension: "mp3") else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            human.texture = humanFrames[1]
        } catch {
            print("Could not load sound file: \(error)")
        }
    }
    
    func tileMapPhysicsBody(map: SKTileMapNode) {
        let tileMap = map
        let tileSize = tileMap.tileSize
        
        for col in 0..<tileMap.numberOfColumns {
            for row in 0..<tileMap.numberOfRows {
                if let tileDefinition = tileMap.tileDefinition(atColumn: col, row: row) {
                    let tileArray = tileDefinition.textures
                    let tileTextures = tileArray[0]
                    let x = CGFloat(col) * tileSize.width
                    let y = CGFloat(row) * tileSize.height
                    let tilePosition = CGPoint(x: x, y: y)
                    let tileNode = SKSpriteNode(texture: tileTextures)
                    
                    tileNode.position = tilePosition
                    tileNode.physicsBody = SKPhysicsBody(texture: tileTextures, size: CGSize(width: tileTextures.size().width, height: tileTextures.size().height))
                    tileNode.physicsBody?.categoryBitMask = bitMasks.ground.rawValue
                    tileNode.physicsBody?.collisionBitMask = bitMasks.ghost.rawValue | bitMasks.human.rawValue
                    tileNode.physicsBody?.contactTestBitMask = bitMasks.ghost.rawValue | bitMasks.human.rawValue
                    tileNode.physicsBody?.affectedByGravity = false
                    tileNode.physicsBody?.isDynamic = false
                    tileNode.physicsBody?.friction = 1
                    tileNode.zPosition = 20
                    
                    tileNode.position = CGPoint(x: tileNode.position.x, y: tileNode.position.y)
                    self.addChild(tileNode)
                }
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        if (bodyA.categoryBitMask == bitMasks.ghost.rawValue && bodyB.categoryBitMask == bitMasks.human.rawValue) ||
            (bodyB.categoryBitMask == bitMasks.ghost.rawValue && bodyA.categoryBitMask == bitMasks.human.rawValue) {
            isGhostControlled = false
            human.removeAllActions()
            
            guard let soundURL = Bundle.main.url(forResource: "humanSoundSurprised", withExtension: "mp3") else {
                return
            }
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("Could not load sound file: \(error)")
            }
            
            isGameOver = true
            self.human.xScale = -abs(self.human.xScale)
            human.texture = humanFrames[3]
            human.physicsBody?.affectedByGravity = false
            
            let waitAction1 = SKAction.wait(forDuration: 1.0)
            let moveAction = SKAction.moveBy(x: 120, y: 0, duration: 1.0)
            let changeTextureAction = SKAction.run { [weak self] in
                self?.human.texture = self?.humanFrames[4]
            }
            let waitAction2 = SKAction.wait(forDuration: 2.0)
            let enableGravityAction = SKAction.run { [weak self] in
                self?.human.physicsBody?.affectedByGravity = true
            }
            
            let sequence = SKAction.sequence([
                waitAction1,
                moveAction,
                changeTextureAction,
                waitAction2,
                enableGravityAction
            ])
            human.run(sequence)
        }
    }
    
    func showGameOverModal() {
        let gameOverLabel = SKLabelNode(text: "You Lose")
        gameOverLabel.fontSize = 45
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 + 50)
        gameOverLabel.zPosition = 100
        self.addChild(gameOverLabel)
        
        let restartLabel = SKLabelNode(text: "Tap to Restart")
        restartLabel.fontSize = 30
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 - 50)
        restartLabel.zPosition = 100
        restartLabel.name = "restartLabel"
        self.addChild(restartLabel)
    }
    
    func restartGame() {
        if let scene = GameScene(fileNamed: "LevelOneScene") {
            scene.scaleMode = .aspectFill
            self.view?.presentScene(scene, transition: SKTransition.crossFade(withDuration: 1.0))
        }
    }

    override func keyDown(with event: NSEvent) {
        if !isGhostControlled { return }
        
        for codeUnit in event.characters!.utf16 {
            
            if codeUnit == 100 {
                playerMovedRight = true
                ghost.alpha = 1
                
                if playerMovedRight == true && playerLookLeft == true {
                    ghost.xScale = -ghost.xScale
                }
                
                playerLookRight = true
                playerLookLeft = false
            }
            
            if codeUnit == 97 {
                playerMovedLeft = true
                ghost.alpha = 1
                if playerMovedLeft == true && playerLookRight == true {
                    ghost.xScale = -ghost.xScale
                }
                
                playerLookRight = false
                playerLookLeft = true
            }
        }
    }
    
    override func keyUp(with event: NSEvent) {
        if !isGhostControlled { return }
        
        for codeUnit in event.characters!.utf16 {
            if codeUnit == 100 {
                playerMovedRight = false
                ghost.removeAllActions()
                ghost.alpha = 0.5
            }
            
            if codeUnit == 97 {
                playerMovedLeft = false
                ghost.removeAllActions()
                ghost.alpha = 0.5
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if ghost.alpha > 0.5 && self.human.xScale == -abs(self.human.xScale) && !isGameOver{
            isGameOver = true
            human.texture = humanFrames[2]
            human.removeAllActions()
            isGhostControlled = false
            showGameOverModal()
        }

        if !isGhostControlled { return }
        if playerMovedRight == true {
            ghost.position.x += 2
        }
        
        if playerMovedLeft == true {
            ghost.position.x -= 2
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodesAtPoint = nodes(at: location)
        
        for node in nodesAtPoint {
            if node.name == "restartLabel" {
                restartGame()
            }
        }
    }
    
    
    override func pressureChange(with event: NSEvent) {
        super.pressureChange(with: event)
        handlePressureChange(with: event)
    }
    
    func handlePressureChange(with event: NSEvent) {
        if !isGhostControlled { return }
        let pressureLevel = event.pressure
        let stage = event.stage

        let movementDistance = CGFloat(pressureLevel) * CGFloat(stage)
        
        if playerLookRight == true {
            ghost.position.x += movementDistance
            ghost.alpha = 1
        } else {
            ghost.position.x -= movementDistance
            ghost.alpha = 1
        }
        
        if stage == 0 {
            ghost.alpha = 0.5
        }
    }
}
