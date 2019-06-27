//
//  ViewController.swift
//  AR-Tower-Defence
//
//  Created by Hoffmann Mike on 03.01.19.
//  Copyright © 2019 Hoffmann Mike. All rights reserved.
//

import UIKit
import SceneKit
import ARKit


/**
 * Diese Erweiterung der Stringklasse ermöglicht das auslesen eines Teilstrings
 */
extension String {
    subscript(i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
}

/**
 * Die Klasse ViewController steuert das Interface und die Umgebungs- und Objekterkennungsfunktionen des ARKits.
 */
class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    // Outlets zum steuern des 2D-Interfaces
    @IBOutlet weak var TowerView: UIView!
    @IBOutlet weak var EnemyView: UIView!
    @IBOutlet weak var PlayerView: UIView!
    
    //Enemy Menu
    @IBOutlet weak var EnemyHPLabel: UILabel!
    @IBOutlet weak var EnemyHpSlider: UISlider!
    @IBOutlet weak var EnemyDmgSlider: UISlider!
    @IBOutlet weak var EnemyDmgLabel: UILabel!
    @IBOutlet weak var EnemySpeedSlider: UISlider!
    @IBOutlet weak var EnemySpeedLabel: UILabel!
    
    //Tower Menu
    @IBOutlet weak var TowerDmgLabel: UILabel!
    @IBOutlet weak var TowerSpeedLabel: UILabel!
    @IBOutlet weak var TowerRangeLabel: UILabel!
    
    @IBOutlet weak var TowerUpgradeCostDmgLabel: UILabel!
    @IBOutlet weak var TowerUpgradeCostSpeedLabel: UILabel!
    @IBOutlet weak var TowerUpgradeCostRangeLabel: UILabel!
    
    //Player Menu
    @IBOutlet weak var PlayerNumberLabel: UILabel!
    @IBOutlet weak var PlayerMoneyLabel: UILabel!
    @IBOutlet weak var PlayerIncomeLabel: UILabel!
    
    @IBOutlet weak var okayButton: UIButton!
    
    let configuration = ARWorldTrackingConfiguration()
    
    var nodeController = NodeController()
    var worldOriginNode = SCNNode()
    var gameProgressController = GameProgressController()
    
    // LAZY, da sonst keine Zuweisung des nodeControllers möglich ist
    lazy var gameObjects = GameObjectsController(passedNodeController: nodeController)
    

    
    var markedTower: Int = -1
    var myPlayerNumber: Int = 1

    var fieldRefreshTimer: Timer!
    let TIMER_INTERVAL: Double = 0.5
    
    /**
     * Diese Funktion wird regelmäßig (abhängig vom fieldRefreshTimer) aufgerufen.
     * Es wird überprüft, ob das Spielfeld erneuert werden muss.
     * Diese Funktion dient der verhinderung von Feldaktuallisierungen für jedes einzelne veränderte Objekt.
     * Das Einkommen des Spielers wird ebenfalls mit Hilfe dieses Timers geregelt.
     */
    @objc func refreshField(){
        if nodeController.getFieldIsReady(){
            if (gameObjects.needFieldRefresh()){
                let group = DispatchGroup()
                group.enter()
                gameObjects.linkOrientations(angle: worldOriginNode.eulerAngles)

                DispatchQueue.global(qos: .userInitiated).async{
                    self.gameObjects.sendFieldupdate()
                    group.leave()
                }
                
                group.wait()
                
                gameObjects.updatePaths()
                nodeController.showShortestPath(shortestPath: nodeController.getShortestPath(fromPos: (-1,-1)))
                //Feld wurde aktuallisiert
                
            }
        }
        
        gameObjects.applyIncome(interval: TIMER_INTERVAL)
        refreshPlayerStats()
        
      
    }

    /**
     * Diese Funktion wird einmalig aufgerufen, sobald die view eingerichtet wurde.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        //DEBUG (Weltstartpunkt und Knotenpunkte anzeigen lassen)
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        //2D-Erkennungs-Bilder Einbinden und auf Existenz Prüfen
        guard let storedImages = ARReferenceImage.referenceImages(inGroupNamed: "2DDetectionImages", bundle: nil)
            else {
            fatalError("2D Objekterkennungsbilder fehlen")
            }
        configuration.detectionImages = storedImages
        
        sceneView.session.run(configuration)
        //TIMER Timer mit regelmäßigen aufruf der refreshField-Funktion wird gestartet
        fieldRefreshTimer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(refreshField), userInfo: nil, repeats: true)
    }

    
//FUNCTIONS BEGIN -----------------------------------------------------------------------------------------------
    
    /**
     * Überschreibt die touchesBegan-Funktion des UIKits.
     * Es wird von der Touchposition ein Raycast (hittest) gestartet. Dieser gibt eine Liste an getroffenen featurepoints zurück.
     * Die Position des letzten getroffenen Ergebnisses wird verwendet.
     * Der nächstgelegene Turm wird ausgewählt und das Upgrademenü für diesen Turm gestartet.
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let result = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint])
        guard let hitResult = result.last else {return}
        let hitTransform = hitResult.worldTransform
        let hitVector = SCNVector3(hitTransform.columns.3.x,hitTransform.columns.3.y,hitTransform.columns.3.z)
        let newNode = SCNNode()
        newNode.position = hitVector
        
        // Urspüngliche Funktion: Wechsel des Feldknotenstatus
        //nodeController.addMarker(rootNode: sceneView.scene.rootNode, node: newNode)              <-
        //nodeController.swapBlockedStateOfNearNodes(position: hitVector)                          <-   Optional Function (Add Wall by touch)
        
        // Positionsvergleich und Turmmenüaufruf
        let towerPosInArray = gameObjects.getTowerAt(pos: hitVector)
        for i in 0 ..< gameObjects.towers.count{
            gameObjects.towers[i].removeRangeIndicator()
        }
        if (towerPosInArray >= 0) {
            markedTower = towerPosInArray
            refreshTowerStats()
            TowerView.isHidden = false
            gameObjects.towers[towerPosInArray].addRangeIndicator()
        }else{
            TowerView.isHidden = true
        }
    }
    
    func createMarker(position: SCNVector3){
        
    }
    
    
    
// ------------------ 2D Bild Erkennung ---------------------------
    
    /**
     * Diese Funktion wird aufgerufen, sobald ein Ankerpunkt hinzugefügt wurde. Möglicher Ansatzpunkt zum Indentifizieren von ARImageAnchors.
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor){
        if anchor is ARImageAnchor{
            //Möglicher Einstiegspunkt Referenzbilderkennung (Meldungsausgabe)
        }
    }
    
    /**
     * Die renderer-Funktion wird verwendet, um Pointer auf die,bei der Objekterkennung entstehenden Knoten, zu setzen.
     * Diese Pointer sind wichtig um die Objektpositionen weiter verfolgen zu können.
     */
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let imageAnchor = anchor as? ARImageAnchor else{return nil}
        
        //Überprüfung, ob es sich um ein Mauer- oder Turmreferenz handelt
        var name: String = ""
        //Name des entdeckten Referenzbildes
        name = imageAnchor.referenceImage.name!
        if (name.contains("wall")){
            name = "wall"
        }
        if (name.contains("tower")){
            name = "tower"
        }
        
        //Fallunterscheidung entsprechend dem Referenzbildnamens
        switch name {
        case "TopLeft": // Wird als position für WorldOrigin verwendet
            
            //indikator für den Nutzer, dass das Bild erkannt wurde
            //->
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            plane.firstMaterial?.diffuse.contents = "TLTexture"
            
            let planeNode = SCNNode()
            planeNode.geometry = plane
            
            let ninetyDegrees = GLKMathDegreesToRadians(-90)
            planeNode.eulerAngles = SCNVector3(ninetyDegrees,0,0)
            //<-
            
            let node = SCNNode()
            node.addChildNode(planeNode)
            worldOriginNode = node

            
            gameProgressController.setCornerTL()
            
            return node
            
        case "BottomRight": // Position zur Feldbegrenzung
            //print("BottomRight found")
            let planeBR = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            planeBR.firstMaterial?.diffuse.contents = "BRTexture"
            
            let planeNode = SCNNode()
            planeNode.geometry = planeBR
            
            let ninetyDegrees = GLKMathDegreesToRadians(-90)
            planeNode.eulerAngles = SCNVector3(ninetyDegrees,0,0)
            
            
            let node = SCNNode()
            node.addChildNode(planeNode)
            
            nodeController.addCorner(rootNode:sceneView.scene.rootNode, node: node)
            
            gameProgressController.setCornerBR()

            return node
            
        case "base": //Festungsknoten - SpielObjekt (weitergabe an gameObjectController)
            //print("BASE found")
            let node = SCNNode()
            let childNode = SCNNode()
            
            childNode.position = SCNVector3Make(0,nodeController.getNodeDistance()/2,0)
            
            childNode.geometry = nodeController.getGeometry(name: "baseBox")
            
            node.addChildNode(childNode)
            gameObjects.addGameObject(node: node, type: "base")
            gameObjects.addBase(node: node)
            return node
        case "spawn": //Gegnerstartposition -SpielObjekt (weitergabe an gameObjectController)
            //print("SPAWN found")
            let node = SCNNode()
            
            let childNode = SCNNode()
            
            childNode.position = SCNVector3Make(0,nodeController.getNodeDistance()/2,0)
            
            childNode.geometry = nodeController.getGeometry(name: "spawnBox")
            
            node.addChildNode(childNode)

            gameObjects.addGameObject(node: node, type: "spawn")
            
            
            return node
            
        case "wall": //Wand - SpielObjekt (weitergabe an gameObjectController)
            let node = SCNNode()
            let childNode = SCNNode()
            
            childNode.position = SCNVector3Make(0,nodeController.getNodeDistance()/2,0)
            
            childNode.geometry = nodeController.getGeometry(name: "wall")
            
            node.addChildNode(childNode)
            
            gameObjects.addGameObject(node: node, type: "wall")
            
            return node
            
        case "tower": //Turm - spezielles SpielObjekt (weitergabe an gameObjectController und Turmliste)
            let node = SCNNode()
            let childNode = SCNNode()
            
            childNode.position = SCNVector3Make(0,nodeController.getNodeDistance(),0)
            
            childNode.geometry = nodeController.getGeometry(name: "tower")
            
            node.addChildNode(childNode)
            
            gameObjects.addGameObject(node: node, type: "tower")
            gameObjects.addTower(node: node)
            return node
            
            
        default:
            print("nothing found")
            
        }
        
        return nil
    }
    
//FUNCTIONS END
//INTERFACE BEGIN
    
    /**
     * Multifunktionsknopf
     * BUTTON: Dient nurnoch als Puffer nachdem alle Referenzobjekte zur Felderstellung erkannt wurden.
     * Fehlerumgehung bezüglich positionsänderung des WorldOrigin.
     */
    @IBAction func multiFunctionButtonPressed(_ sender: Any) {
        tryBuildField()
    }
    
// ------ TOWER UPGRADE BUTTONS ----------
    /**
     * Aktuallisiert die Daten im Interface für die Towerstats.
     */
    func refreshTowerStats(){
        TowerDmgLabel.text = String(gameObjects.towers[markedTower].getDmg())
        TowerSpeedLabel.text = String(gameObjects.towers[markedTower].getSpeed())
        TowerRangeLabel.text = String(gameObjects.towers[markedTower].getRangeUpgrade())
        
        TowerUpgradeCostDmgLabel.text = String(gameObjects.towers[markedTower].getUpgradeCostsDmg())
        TowerUpgradeCostSpeedLabel.text = String(gameObjects.towers[markedTower].getUpgradeCostsSpeed())
        TowerUpgradeCostRangeLabel.text = String(gameObjects.towers[markedTower].getUpgradeCostsRange())
    }
    
    /**
     * BUTTON: Dient der Upgradeverwaltung des Turmschadens.
     */
    @IBAction func TowerDamageButton(_ sender: Any) {
        if (gameObjects.players[gameObjects.getPlayerPos(playerNumber: myPlayerNumber)].getMoney() >= gameObjects.towers[markedTower].getUpgradeCostsDmg()){
            gameObjects.players[gameObjects.getPlayerPos(playerNumber: myPlayerNumber)].subMoney(value: gameObjects.towers[markedTower].getUpgradeCostsDmg())
            gameObjects.towers[markedTower].addDamage()
            refreshTowerStats()
        }

    }
    
    /**
     * BUTTON: Dient der Upgradeverwaltung der Angriffsgeschwindigkeit des ausgewählten Turms.
     */
    @IBAction func TowerSpeedButton(_ sender: Any) {
        if (gameObjects.players[gameObjects.getPlayerPos(playerNumber: myPlayerNumber)].getMoney() >= gameObjects.towers[markedTower].getUpgradeCostsSpeed()){
            gameObjects.players[gameObjects.getPlayerPos(playerNumber: myPlayerNumber)].subMoney(value: gameObjects.towers[markedTower].getUpgradeCostsSpeed())
            gameObjects.towers[markedTower].addSpeed()
            refreshTowerStats()
        }
    }
    
    /**
     * BUTTON: Dient der Upgradeverwaltung der Angriffsreichweite des ausgewählten Turms.
     */
    @IBAction func TowerRangeButton(_ sender: Any) {
        if (gameObjects.players[gameObjects.getPlayerPos(playerNumber: myPlayerNumber)].getMoney() >= gameObjects.towers[markedTower].getUpgradeCostsRange()){
            gameObjects.players[gameObjects.getPlayerPos(playerNumber: myPlayerNumber)].subMoney(value: gameObjects.towers[markedTower].getUpgradeCostsRange())
            gameObjects.towers[markedTower].addRange()
            refreshTowerStats()
            gameObjects.towers[markedTower].addRangeIndicator()
        }
    }
    
    
    /**
     * SANDBOX ENEMY
     * BUTTON: Dient der aussendung eines Gegners.
     */
    @IBAction func runEnemy(_ sender: Any) {
        var calcSpeed: Double = 0.0
        calcSpeed = Double(Int(EnemySpeedSlider.maximumValue)-Int(EnemySpeedSlider.value)+1)/10
        gameObjects.addEnemy(rootNode: sceneView.scene.rootNode,health: Int(EnemyHpSlider.value), dmg: Int(EnemyDmgSlider.value), speed: calcSpeed)
        
        gameObjects.sendEnemy()
        
    }
    
    
    /**
     * ## FEHLERQUELLE ##
     * Nach dem Umsetzen des Weltursprungs wird weitere Zeit benötigt, bis die anderen Knoten umpositioniert wurden.
     * Es ist keine Funktion im ARKit vorhanden, um eine Rückmeldung hierfür zu erhalten.
     * Deshalb wird die Spielfelderstellung nicht automatisch gestartet und muss vom Anwender durch einen Knopfdruck bestätigt werden.
     *
     * BUTTON: Dient der Umpositionierung des Weltursprungs (WorldOrigin).
     */
    @IBAction func resetWorldOrigin(_ sender: Any) {
        self.sceneView.session.setWorldOrigin(relativeTransform: worldOriginNode.simdTransform)
    }
    
// -----------------------SLIDER ENEMY MENU INTERFACE -------------------------------
    
    /**
     * SLIDER: Stellt einen Wert zur Einstellung der Anzahl der Gegnerlebenspunkten zur Verfügung.
     */
    @IBAction func SliderHPEnemy(_ sender: Any) {
        var labelText: String = ""
        labelText = "Enemy HP: "
        labelText.append(String(Int(EnemyHpSlider.value)))
        EnemyHPLabel.text = labelText
        
    }
    
    /**
     * SLIDER: Stellt einen Wert zur Einstellung des Gegnerschadens zur Verfügung.
     */
    @IBAction func SliderDmgEnemy(_ sender: Any) {
        var labelText: String = ""
        labelText = "Enemy DMG: "
        labelText.append(String(Int(EnemyDmgSlider.value)))
        EnemyDmgLabel.text = labelText
        
    }
    
    /**
     * SLIDER: Stellt einen Wert zur Einstellung der Gegnergeschwindigkeit zur Verfügung.
     */
    @IBAction func SliderSpeedEnemy(_ sender: Any) {
        var labelText: String = ""
        labelText = "Enemy Speed: "
        labelText.append(String(Int(EnemySpeedSlider.value)))
        EnemySpeedLabel.text = labelText
    }
    
// ------ PLAYERINTERFACE --------------
    
    
    /**
     * Diese Funktion erneuert die Spieleranzeige.
     */
    func refreshPlayerStats(){
        self.PlayerMoneyLabel.text = String(gameObjects.players[gameObjects.getPlayerPos(playerNumber: myPlayerNumber)].getMoney())
        self.PlayerIncomeLabel.text = String(gameObjects.players[gameObjects.getPlayerPos(playerNumber: myPlayerNumber)].getIncome())
    }
    
    /**
     * Diese Funktion setzt die Spielernummer fest.
     *
     * - Parameter number: Die Festzulegende Spielernummer.
     */
    func setMyPlayerNumber(number: Int){
        self.myPlayerNumber = number
    }

    
    
    /**
     * ## FEHLERQUELLE ##
     * Nach dem Umsetzen des Weltursprungs wird weitere Zeit benötigt, bis die anderen Knoten umpositioniert wurden.
     * Es ist keine Funktion im ARKit vorhanden, um eine Rückmeldung hierfür zu erhalten.
     * Deshalb wird die Spielfelderstellung nicht automatisch gestartet und muss vom Anwender durch einen Knopfdruck bestätigt werden
     *
     * Diese Funktion zeigt, dass die Funktion "setWorldOrigin" zu früh als abgeschlossen gilt. Hier wurden Methoden verwendet um einen Festen Funktionsablauf sicher zu stellen.
     */
    func finishSetWorldFirst(completion: () -> ()){
        //sceneView.session.pause()
        self.sceneView.session.setWorldOrigin(relativeTransform: worldOriginNode.simdTransform)
        //sceneView.session.run(configuration)
        
        completion()
    }
    
    func tryBuildField(){
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.global(qos: .userInitiated).async{
            self.sceneView.session.setWorldOrigin(relativeTransform: self.worldOriginNode.simdTransform)
            group.leave()
        }
        
        group.wait()
        
        
        
            if ((gameProgressController.getCornerTLIsSet())&&(gameProgressController.getCornerBRIsSet())){
                nodeController.setUpField(rootNode: sceneView.scene.rootNode)
                EnemyView.isHidden = false
                okayButton.isHidden = true
                
            }else{
                print("requirements not met")
            }
    }
    
    
    
//INTERFACE END
    

    

}

