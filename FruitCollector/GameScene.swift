//
//  GameScene.swift
//  FruitCollector
//
//  Created by Pei Yi Chiang on 4/24/22.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {

    var player:SKSpriteNode!

    var scoreLabel:SKLabelNode!
    var score:Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }

    var gameTimer:Timer!

    var possibleFruits = ["cherry", "orange"]

    let fruitCategory:UInt32 = 0x1 << 1     //2
    let bulletCategory:UInt32 = 0x1 << 0    //1

    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0

    override func didMove(to view: SKView) {
        // Create the player object (cart) and set its position
        player = SKSpriteNode(imageNamed: "cart")
        player.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 400)
        player.size = CGSize(width: 180, height: 180)
        // Bind to game scene
        self.addChild(player)

        // Initialize the player object's physics property
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self

        // Initialize the score label
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: self.frame.midX - 240, y: self.frame.midY + 480)
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = UIColor.black
        self.addChild(scoreLabel)

        // Set the initial score
        score = 0

        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addFruit), userInfo: nil, repeats: true)

        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error:Error?) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
            }
        }
    }

    @objc func addFruit() {
        // Randomize fruit category
        possibleFruits = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleFruits) as! [String]
        // Randomize fruit x position
        let randomFruitPosition = GKRandomDistribution(lowestValue: -300, highestValue: 300)
        let position = CGFloat(randomFruitPosition.nextInt())
        // Create fruit object and initialize its starting position and other properties
        let fruit = SKSpriteNode(imageNamed: possibleFruits[0])
        fruit.position = CGPoint(x: position, y: 600)
	fruit.zPosition = 1

        fruit.physicsBody = SKPhysicsBody(rectangleOf: fruit.size)
        fruit.physicsBody?.isDynamic = true

        fruit.physicsBody?.categoryBitMask = fruitCategory
        fruit.physicsBody?.contactTestBitMask = bulletCategory
        fruit.physicsBody?.collisionBitMask = 0

        // Add node to the game scene
        self.addChild(fruit)

        // How long it takes for the fruit to drop to the destined position
        let animationDuration:TimeInterval = 5

        var actionArray = [SKAction]()

        // Fruits drop to which position
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -550), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())

        fruit.run(SKAction.sequence(actionArray))
    }

    // Fires bullet at the end of clicks
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireBullet()
    }

    func fireBullet() {
        let bulletNode = SKSpriteNode(imageNamed: "bullet")
        bulletNode.position = player.position
        bulletNode.position.y += 5
        bulletNode.size = CGSize(width: 40, height: 40)

        bulletNode.physicsBody = SKPhysicsBody(circleOfRadius: bulletNode.size.width / 2 - 10)
        bulletNode.physicsBody?.isDynamic = true

        bulletNode.physicsBody?.categoryBitMask = bulletCategory
        bulletNode.physicsBody?.contactTestBitMask = fruitCategory
        bulletNode.physicsBody?.collisionBitMask = 0
        bulletNode.physicsBody?.usesPreciseCollisionDetection = true

        self.addChild(bulletNode)

        let animationDuration:TimeInterval = 0.4

        var actionArray = [SKAction]()

        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height + 10), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())

        bulletNode.run(SKAction.sequence(actionArray))
    }

    // Detects collision
    func didBegin( _ contact: SKPhysicsContact) {
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody

        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }

        if (firstBody.categoryBitMask & bulletCategory) != 0 && (secondBody.categoryBitMask & fruitCategory) != 0 {
            bulletDidCollideWithFruit(bulletNode: firstBody.node as! SKSpriteNode, fruitNode: secondBody.node as! SKSpriteNode)
        }
    }

    // When bullet hits a fruit
    func bulletDidCollideWithFruit(bulletNode: SKSpriteNode, fruitNode: SKSpriteNode) {
        // Delete node from the game scene
        bulletNode.removeFromParent()
        fruitNode.removeFromParent()
        score += 5
    }

    override func didSimulatePhysics() {
        player.position.x += xAcceleration * 40

        // If player goes out of the left boundary
        if player.position.x < -350 {
            player.position = CGPoint(x: self.size.width + 20, y: player.position.y)
        } else if player.position.x > self.size.width + 20 {
            player.position = CGPoint(x: -350, y: player.position.y)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}