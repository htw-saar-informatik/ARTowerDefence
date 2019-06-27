//
//  gameProgressController.swift
//  AR-Tower-Defence
//
//  Created by Hoffmann Mike on 04.01.19.
//  Copyright © 2019 Hoffmann Mike. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit

// ---------------------- ERWEITERUNGEN --------------------------

/**
 * Diese Erweiterung der SCNVector3-Klasse ermöglicht das Berechnen der zweidimensionalen Distanz der X und Z Koordinaten zwischen zwei Vector3 Koordinaten.
 */
extension SCNVector3{
    func distance(nodeB: SCNVector3) -> Float{
        var distance: Float = 0.0
        distance = sqrt(pow((self.x - nodeB.x), 2) + pow((self.z - nodeB.z),2))
        return distance
    }
}

/**
 * Diese Erweiterung dient dem gameObjectsController zur Notifikation, wenn ein Gegner sein Ziel erreicht hat.
 */
extension Notification.Name{
    static let targetReached = Notification.Name(rawValue: "targetReached")
}




// ------------------------- KLASSE GameProgressController -----------------------------------
/**
 * Diese Klasse dient Erkennung von Spielabschnitten.
 * Da bisher keine Spielmodi implementiert sind, werden lediglich die Platzierung der Spielfeldkanten kontrolliert.
 */
public class GameProgressController {
    
    var cornerTLIsSet = false
    var cornerBRIsSet = false
    
    var baseIsSet = false
    var spawnIsSet = false

//SETTER BEGIN
    /**
     * Diese Funktion setzt die Spielfeldbedingung für die obere linke Ecke fest.
     */
    func setCornerTL(){
        cornerTLIsSet = true
    }
    
    /**
     * Diese Funktion setzt die Spielfeldbedingung für die untere rechte Ecke fest.
     */
    func setCornerBR(){
        cornerBRIsSet = true
    }
//SETTER END
//GETTER BEGIN
    
    /**
     * - Returns: Gibt Informationen über die Setzung der oberen linken Spielfeldecke aus.
     */
    func getCornerTLIsSet() -> Bool{
        return cornerTLIsSet
    }
    
    /**
     * - Returns: Gibt Informationen über die Setzung der untere rechte Spielfeldecke aus.
     */
    func getCornerBRIsSet() -> Bool{
        return cornerBRIsSet
    }
//GETTER END
}





// ------------------------- KLASSE GameObjectsController -----------------------------------
/**
 * Diese Klasse dient der Steuerung und Positionierung von Spielobjekten.
 * Objekte der Untergeordneten Klassen Enemy, Tower und Player werden über diese Klasse erstellt.
 * Sämtliche Interaktionen mit diesen, müssen über den GameObjectsController Stattfinden.
 */
public class GameObjectsController {
    var nodeController: NodeController
    

    /**
     * Initialisierung eines gameObjectsControllers
     * ## passedNodeController ##
     * Es muss eine durch den ViewController erstellte Instanz des NodeControllers weiter gegeben werden.
     * Der GameObjectsController muss seine Objektdaten an den ViewController weiter geben und Pfade erhalten können.
     *
     * - Parameter passedNodeController: Die durch den ViewController erstelle Instanz des NodeControllers.
     */
    init(passedNodeController: NodeController){
        self.nodeController = passedNodeController
        //NOTIFICATIONCENTER
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(GameObjectsController.targetReached),name: .targetReached, object: nil)
        addPlayer(playerNumber: 1)
    }
    
    
    var gameObjects: [(node: SCNNode ,type: String)] = []
    var gameObjectsOldPositions: [SCNVector3] = []
    
    var players: [Player] = []
    var bases: [Base] = []
    var towers: [Tower] = []
    var enemys: [Enemy] = []
    
//FUNCTIONS BEGIN
    
    // Mögliche typen: spawn, base, wall, tower
    /**
     * Diese Funktion fügt dem gameObjectsArray ein weiteres Element hinzu.
     */
    func addGameObject(node: SCNNode, type: String){
        gameObjects.append((node: node, type: type))
        resetOldPositions()
    }
    
    /**
     * Diese Funktion ersetzt die Kontrollpositionen zurück. Das bedeutet, dass die Vergleichswerte an die aktuellen Werte angepasst werden.
     */
    func resetOldPositions(){
        gameObjectsOldPositions = []
        for i in 0..<gameObjects.count{
            gameObjectsOldPositions.append(gameObjects[i].node.position)
        }
    }
    
    /**
     * Diese Funktion passt die Rotation der Spielobjekte an die des Weltursprungs an.
     * Das Spielfeld sieht dadurch geordneter aus.
     */
    func linkOrientations(angle: SCNVector3){
        for i in 0..<gameObjects.count{
            gameObjects[i].node.eulerAngles = angle
        }
    }
    
    /**
     * Diese Funktion vergleicht die aktuellen Positionen der Objekte mit den Vergleichswerten. Werden unterschiede festgestellt, ist eine Spielfeldaktuallisierung notwendig.
     *
     * - Returns: Gibt zurück, ob das Spielfeld erneuert werden muss.
     */
    func needFieldRefresh() -> Bool{
        for i in 0..<gameObjects.count{
            if !SCNVector3EqualToVector3(gameObjects[i].node.position, gameObjectsOldPositions[i]){
                resetOldPositions()
                return true
            }
        }
        return false
    }
    
    /**
     * Diese Funktion wird vom ViewController bei Aktuallisierungsbedarf aufgerufen. Die Objektliste wird an den nodeController übertragen.
     */
    func sendFieldupdate(){
        nodeController.receiveFieldupdate(objList: gameObjects)
    }
    
    // ---------------------------------------- SPIELERVERWALTUNG -----------------------------------------------------------------
    
    /**
     * Die Funktion fügt der Spielerliste ein Objekt hinzu.
     */
    func addPlayer(playerNumber: Int){
        players.append(Player(playerNumber: (players.count + 1), money: 0.0))
    }
    
    /**
     * Diese Funktion wird regelmäßig durch den ViewController aufgerufen.
     * Das Einkommen der Spieler wird abhängig vom Aufrufintervall der verfügbaren Währung hinzugefügt.
     *
     * - Parameter interval: Gibt an, wie oft diese Funktion pro Sekunde aufgerufen wird.
     */
    func applyIncome(interval: Double){
        for i in 0 ..< players.count{
            players[i].applyIncome(modificator: interval)
        }
    }
    
    /**
     * Diese Funktion gibt die Position desSpielers innerhalb des Spielerarrays an.
     * Spielernummer ist als eine SpielerID zu verstehen und muss nicht mit der Position im Array übereinstimmen.
     *
     * - Parameter playerNumber: Die Spielernummer/SpielerID des zu bearbeitenden Spielers.
     *
     * - Returns: gibt die Position des SPielers im Spielerarray an.
     */
    func getPlayerPos(playerNumber: Int) -> Int{
        var playerPos: Int = -1
        for i in 0 ..< players.count{
            if players[i].getPlayerNumber() == playerNumber{
                playerPos = i
            }
            
        }
        return playerPos
    }


    
    // ---------------------------------------- BASESTEUERUNG ---------------------------------------------------------------------
    
    /**
     * Diese Funktion fügt ein neues Objekt dem Festungsarray (bases) hinzu.
     * Im Singleplayer wird dieses Array nur eine einzelne Festung enthalten.
     *
     * - Parameter node: Knotenpunkt der hinzuzufügenden Festung.
     */
    func addBase(node: SCNNode){
        let newBase = Base(node: node, health: 20)
        bases.append(newBase)
    }
    
    /**
     * Diese Funktion lässt die Festungslebenspunkte festlegen.
     *
     * - Parameter health: Die festzulegende Anzahl an Festungslebenspunkten.
     */
    func setBaseHealth(health: Int){
        for i in 0 ..< bases.count{
            bases[i].setHealth(health: health)
        }
    }
    
    
    // ---------------------------------------- TOWERSTEUERUNG -------------------------------------------------------------------
    
    
    /**
     * Diese Funktion fügt ein neues Objekt dem Turmarray (towers) hinzu. Die iterative Angriffsfunktion wird gestartet.
     *
     * - Parameter node: Der Knotenpunkt des hinzuzufügenden Turms.
     */
    func addTower(node: SCNNode){
        let newTower = Tower(node: node, dmg: 3, speed: 1.5)
        towers.append(newTower)
        startFire(towerNr: towers.count-1)
    }
    
    /**
     * Diese sich selbst aufrufende (iterative) Funktion, lässt die Türme abhängig von ihrer Angriffsgeschwindigkeit fortgehend angreifen.
     *
     * - Parameter towerNr: Diese Nummer entspricht der Position des Turms im towers-Array.
     */
    func startFire(towerNr: Int){
        towers[towerNr].fire(enemys: &enemys)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + towers[towerNr].speed, execute:{
            self.startFire(towerNr: towerNr)
        })
    }
    
    /**
     * Diese Funktion überprüft ob ein Turm im Bereich der vorgegebenen Koordinate ist.
     * Die Positionsnummer innerhalb des towers-Arrays wird zurückgegeben, wenn ein Turm innerhalb der Knotenabstandslänge gefunden wird.
     *
     * - Parameter node: Knotenpunkt der hinzuzufügenden Festung.
     *
     * - Returns: Rückgabe der Positionsnummer des gefundenen Turms innerhalb des towers-Arrays. Eine erfolglose Suche wird mit -1 quittiert.
     */

    func getTowerAt(pos: SCNVector3) -> Int {
        for i in 0 ..< towers.count{
            if (towers[i].getPosition().distance(nodeB: pos) < NodeController().getNodeDistance()){
                return i
            }
        }
        
        return -1
    }

    
    
    // ---------------------------------------- GEGNERSTEUERUNG ------------------------------------------------------------------
    
    
    /**
     * Diese Funktion erstellt, wenn ein Spawnpunkt vorhanden ist, ein Gegnerobjekt.
     * Ist ein "Toter" Gegner im Gegnerarray vorhanden, wird diese ersetzt. Ansonsten werden neue Gegner dem Array hinzugefügt.
     *
     * - Parameter rootNode: Wurzelknoten wird benötigt zum Anhängen weiterer Knoten.
     * - Parameter health: Lebenspunkte des Gegners.
     * - Parameter dmg: Schadenspunkte/Angriffsstärke des Gegners.
     * - Parameter speed: Geschwindigkeit des Gegners. (Entspricht die dauer, die der Gegner benötigen wird um von einem Feldknoten zum anderen zu laufen)
     */

    func addEnemy(rootNode: SCNNode, health: Int, dmg: Int, speed: Double) {
        let newNode = SCNNode()
        let newChildNode = SCNNode(geometry: nodeController.getGeometry(name: "magentaSphere"))
        newChildNode.position = SCNVector3Make(0,nodeController.getNodeDistance()/2,0)
        newNode.addChildNode(newChildNode)
        newNode.position = nodeController.getSpawnPosition()
        
        let targetPos = nodeController.getBasePostion()
        let newEnemy = Enemy(node: newNode, health: health, speed: speed,dmg: dmg,target: targetPos, targetPlayer: 1)
        if SCNVector3EqualToVector3(newNode.position, SCNVector3Make(-1,-1,-1)){   //überprüfen ob Spawn auf dem Spielfeld gesetzt ist.
            print("no spawnpoint")
        }else{
            var listOfDeadEnemysPos: [Int] = []
            for i in 0 ..< enemys.count{
                if enemys[i].getIsDead(){
                    listOfDeadEnemysPos.append(i)
                }
            }
            if listOfDeadEnemysPos.count > 0{   // überprüfen ob "Tote" Gegner im enemys-Array vorhanden sind und diese ersetzen
                enemys[listOfDeadEnemysPos[0]] = newEnemy
            }else{                              // sonst hinzufügen neuer Gegner
                enemys.append(newEnemy)
            }
            
            rootNode.addChildNode(newNode)
            
        }
    }
    
    /**
     * Diese Funktion sendet alle Gegner im enemy-Array los, die nicht losgelaufen sind. Diese Eigenschaft wird verwendet um viele Gegner gleichzeitig zu aktivieren.
     *
     */
    func sendEnemy(){
        if enemys.count > 0{
            for i in 0 ..< enemys.count{
                if !enemys[i].getIsRunning(){
                    enemys[i].setPath(newPath: nodeController.getShortestPathAsVectors(fromPos: (-1,-1)))
                    enemys[i].startRunning()
                }
            }
        }
    }
    
    /**
     * Diese Funktion lässt Gegner eine neue Pfade anfordern. Dies ist bei aktuallisierung des Spielfeldes nötig.
     *
     */
    func updatePaths(){
        if enemys.count > 0{
            for i in 0 ..< enemys.count{
                enemys[i].setTarget(pos: nodeController.getBasePostion())
                if (SCNVector3EqualToVector3(enemys[i].getCurrentTarget(), SCNVector3Make(-1,-1,-1))) && (!enemys[i].getIsStuck()){  //behandlung in kürze Feststeckender gegner
                    enemys[i].setPath(newPath: nodeController.getShortestPathAsVectors(fromPos: (-1,-1)))
                    enemys[i].setTarget(pos: nodeController.getBasePostion())
                }else if enemys[i].getIsStuck(){ //behandlung feststeckender Gegner
                    enemys[i].setPath(newPath: nodeController.getShortestPathAsVectors(fromPos: nodeController.getSimplePosition(pos: enemys[i].getPosition())))
                    enemys[i].setTarget(pos: nodeController.getBasePostion())
                }else{ //behandlung der restlichen Gegner
                    enemys[i].setPath(newPath: nodeController.getShortestPathAsVectors(fromPos: nodeController.getSimplePosition(pos: enemys[i].getCurrentTarget())))
                    enemys[i].setTarget(pos: nodeController.getBasePostion())
                    //print(nodeController.getShortestPathAsVectors())
                }
            }
        }
        
    }
    
    // Gegner dmg Handler
    /**
     * Diese Funktion wird durch Notifications aufgerufen. Sobald ein Gegner sein Ziel(die Festung) erreicht, wird die Schadensbehandlung aufgerufen.
     *
     * - Parameter _ notification: Notifikation durch den Gegner, der sein Ziel erreich hat.
     */
    @objc func targetReached(_ notification:Notification){
        for i in 0 ..< enemys.count{
            if enemys[i].getFinished(){
                if !(enemys[i].getIsDead()) {                     // ZUGRIFFSKONFLIKT => Lösung: Replace "dead" enemys statt löschen
                    for j in 0 ..< bases.count{
                        if (enemys[i].getTargetPlayer()-1) == j{
                            //print(enemys[i].getDmg(), "dmg done")
                            bases[j].incomingDmg(incDmg: enemys[i].getDmg())
                            enemys[i].delete()
                        }
                    }
                    
                    // FEHLER/THROW WENN KEINE BASE GEFUNDEN WURDE
                }
                
            }
        }
        
        
    }
    
//FUNCTIONS END

}


// ---------------------------------------------------- KLASSEN FUER GAMEOBJECTCONTROLLER ----------------------------------------------

// ------------------------------------------------------------ KLASSE PLAYER ----------------------------------------------------------
/**
 * Diese Klasse dient der Spielerunterschiedung und zum steuern des Geldes und dem Einkommen dieser Spieler.
 *
 */
class Player{
    var playerNumber: Int
    var money: Double
    var income: Double
    
    /**
     * Initialisierung eines Spieler-Objekts
     *
     * - Parameter playerNumber: Die Spielernummer. Diese Nummer entspricht einer SpielerID und muss nicht fortlaufend (Spieler: 1,2,3...) sein.
     * - Parameter money: Dieser Wert legt das Startkapital des Spielers fest.
     */
    init (playerNumber: Int, money: Double){
        self.playerNumber = playerNumber
        self.money = money
        self.income = 100.0
    }
//FUNCTIONS BEGIN

    /**
     * Diese Funktion fügt Geld entsprechend des Einkommens hinzu (abhängig vom Aufrufintervall).
     *
     * - Parameter modificator: Entspricht der Anzahl an Aufrufen pro Sekunde.
     */
    func applyIncome(modificator: Double){
        addMoney(value: (income * modificator))
    }
    
//FUNCTIONS END
//GETTER BEGIN
    
    /**
     * - Returns: Gibt die Spielernummer/SpielerID zurück.
     */
    func getPlayerNumber() -> Int{
        return playerNumber
    }
    
    /**
     * - Returns: Gibt das aktuell verfügbare Geld des Spielers zurück.
     */
    func getMoney() -> Double{
        return money
    }
    
    /**
     * - Returns: Gibt das Einkommen pro Sekunde des Spielers zurück.
     */
    func getIncome() -> Double{
        return income
    }
    
//GETTER END
//SETTER BEGIN
    
    /**
     * Diese Funktion legt die Spielernummer/SpielerID fest.
     *
     * - Parameter number: Die festzulegende Spielernummer/SpielerID.
     */
    func setPlayerNumber(number: Int){
        self.playerNumber = number
    }
    
    /**
     * Diese Funktion legt das Vermögen des Spielers fest.
     *
     * - Parameter value: Der festzulegende Währungsbetrag.
     */
    func setMoney(value: Double){
        self.money = value
        if self.money > 99999.0{
            self.money = 99999.0
        }
    }
    
    /**
     * Diese Funktion fügt dem aktuellen Guthaben des Spielers einen Betrag hinzu.
     *
     * - Parameter value: Der zu addierende Betrag.
     */
    func addMoney(value: Double){
        self.money = self.money + value
        if self.money > 99999.0{
            self.money = 99999.0
        }
    }
    
    /**
     * Diese Funktion zieht vom aktuellen Guthaben des Spielers einen Betrag ab.
     *
     * - Parameter value: Der zu subtrahierende Betrag.
     */
    func subMoney(value: Double){
        self.money = self.money - value
    }
    
    /**
     * Diese Funktion legt des Wert fest, den der Spieler pro Sekunde erhält.
     *
     * - Parameter value: Der Einkommensbetrag pro Sekunde.
     */
    func setIncome(value: Double){
        self.income = value
    }
    
    /**
     * Diese Funktion erhöht den Betrag, den der Spieler pro Sekunde erhält.
     *
     * - Parameter value: Die Erhöhungsumme für das Einkommen pro Sekunde.
     */
    func addIncome(value: Double){
        self.income = self.income + value
    }
    
    /**
     * Diese Funktion senkt den Betrag, den der Spieler pro Sekunde erhält.
     *
     * - Parameter value: Die Senkungssumme für das Einkommen pro Sekunde.
     */
    func subIncome(value: Double){
        self.income = self.income - value
    }
    
//SETTER END
}

// ------------------------------------------------------------- KLASSE BASE -----------------------------------------------------------
/**
 * Diese Klasse dient zum festlegen der Festungswerte und der Darstellung der Lebenspunkte.
 *
 */
class Base{
    var node: SCNNode
    var health: Int
    var healthbarNode = SCNNode()
    
    /**
     * Initialisierung eines Festungs-Objekts
     *
     * - Parameter node: Knoten der zur Festung werden soll.
     * - Parameter health: Die Lebenspunkte der Festung.
     */
    init (node: SCNNode, health: Int){
        self.node = node
        self.health = health
        
        addHealthbar()
    }
    
//FUNCTIONS BEGIN
    
    /**
     * Diese Funktion dient der Verrechnung des eingehenden Schadens.
     *
     * - Parameter incDmg: Der Wert der eingehenden Schadensmenge.
     */
    func incomingDmg(incDmg: Int){
        self.health = self.health - incDmg
        if self.health <= 0{
            print("GAME OVER")
        }
        refreshHealthbar()
        
    }
    
    /**
     * Diese Funktion fügt der Festung eine 3D-Text-Anzeige für die aktuellen Lebenspunkte hinzu.
     */
    func addHealthbar(){
        let healthText = SCNText(string: String(self.health), extrusionDepth: 0.1)
        healthText.firstMaterial?.diffuse.contents = UIColor.red
        healthText.font = UIFont.systemFont(ofSize: 1.0)
        
        let rotateNode = SCNNode()
        rotateNode.geometry = SCNSphere(radius: CGFloat(0.0001))
        
        let distance = NodeController().getNodeDistance()
        
        healthbarNode.geometry = healthText
        
        healthbarNode.position = SCNVector3(0-distance/4,distance-distance/2,0)
        //healthbarNode.eulerAngles.x = -90
        //healthbarNode.position.y = healthbarNode.position.y + (())
        //healthbarNode.position.z = healthbarNode.position.z + (0.022)
        //healthbarNode.position.x = healthbarNode.position.x - (0.01)
        healthbarNode.scale = SCNVector3(distance/2,distance/2,distance/2)
        
        node.addChildNode(healthbarNode)
        
    }
    
    /**
     * Diese Funktion dient der Aktuallisierung der Lebensanzeige.
     */
    func refreshHealthbar(){
        let healthText = SCNText(string: String(self.health), extrusionDepth: 0.1)
        healthText.firstMaterial?.diffuse.contents = UIColor.red
        healthText.font = UIFont.systemFont(ofSize: 1.0)
        
        self.healthbarNode.geometry = healthText
    }
    
//FUNCTIONS END
//GETTER BEGIN
    
    /**
     * - Returns: Gibt die Position des Knotens im Koordinatensystem zurück.
     */
    func getPosition() -> SCNVector3{
        return node.position
    }
    
//GETTER END
//SETTER BEGIN
    
    /**
     * Diese Funktion legt die Lebenspunkte der Festung (Base) fest.
     *
     * - Parameter health: Die festzulegende Menge an Lebenspunkten.
     */
    func setHealth(health: Int){
        self.health = health
    }
    
//SETTER END
}

// ------------------------------------------------------------- KLASSE TOWER ----------------------------------------------------------

/**
 * Diese Klasse dient der Erstellung von Turmobjekten. Die vorhanden Attribute können verändert und eine Reichweitenanzeige hinzugefügt werden.
 */
class Tower{
    var node: SCNNode
    var rangeIndicationNode: SCNNode
    var dmg: Int
    var range: Float
    var basicRange: Float
    var speed: Double

    var basicPriceDmg: Double = 20.0
    var basicPriceSpeed: Double = 50.0
    var basicPriceRange: Double = 50.0
    
    var dmgUpgrade: Int = 0
    var speedUpgrade: Int = 0
    var rangeUpgrade: Int = 0
    
    /**
     * Initialisierung eines Turm-Objekts
     *
     * - Parameter node: Knoten der zum Turm werden soll.
     * - Parameter dmg: Der Angriffsschaden des Turms.
     * - Parameter speed: Die Angriffsgeschwindigkeit des Turms. Entspricht der Anzahl an Angriffen pro Sekunde.
     */
    init (node: SCNNode, dmg: Int, speed: Double){
        self.node = node
        self.dmg = dmg
        self.basicRange = NodeController().getNodeDistance()*1.5
        self.range = basicRange
        
        self.speed = speed
        self.rangeIndicationNode = SCNNode()
        rangeIndicationNode.position = SCNVector3Make(0,0,0)

        self.node.addChildNode(rangeIndicationNode)
    }
    
    
    /**
     * Diese Funktion dient der verarbeitung der Gegnerliste um einem Gegner schaden zuzufügen.
     * Es wird ein Projektil erstellt, dass auf die aktuelle Position des gegner zufliegt.
     *
     * - Parameter enemys: Gegnerarray des GameObjectsControllers.
     */
    func fire(enemys: inout [Enemy]){
        //print("fire")
        var possibleEnemyList: [Int] = []
        var shortestPath: Float = 999.9
        var shortestPathPos: Int = -1
        
        for i in 0 ..< enemys.count{    //Gegnerliste erstellen. Gegner die nicht in Reichweite sind, tot sind oder feststecken, werden nciht hinzugefügt
            if enemys[i].getPosition().distance(nodeB: self.node.position) < self.range{
                if !enemys[i].getIsDead(){
                    if !enemys[i].getIsStuck(){
                        possibleEnemyList.append(i)
                    }
                }
                
            }
        }
        for i in 0 ..< possibleEnemyList.count{ //Die erstellte Liste wird abgearbeitet und der Gegner mit dem kürzesten Weg zum Ziel herausgefunden
            
            if (i == 0) {
                shortestPath = enemys[possibleEnemyList[i]].getDistanceOfPath()
                shortestPathPos = possibleEnemyList[i]
            }else{
                if (shortestPath > enemys[possibleEnemyList[i]].getDistanceOfPath()){
                    shortestPath = enemys[possibleEnemyList[i]].getDistanceOfPath()
                    shortestPathPos = possibleEnemyList[i]
                }
            }
        }
        if (shortestPathPos >= 0) { //Wurde ein Ziel gefunden, wird ein Projektil erstellt, dass auf die aktuelle Gegnerposition zufliegt. Diesem Gegner wird Schaden zugefügt.
            let projectile = SCNNode()
            projectile.geometry = NodeController().getGeometry(name: "projectile")
            projectile.position = node.position
            projectile.position.y = projectile.position.y + (NodeController().getNodeDistance()*2)
            (node.parent!).addChildNode(projectile)
            
            
            let move = SCNAction.move(to: enemys[shortestPathPos].getPosition(), duration: 0.2)
            
            projectile.runAction(move, completionHandler: { () in projectile.removeFromParentNode()})
            
            enemys[shortestPathPos].incomingDmg(incDmg: self.dmg)
        }
        
    }
    
    /**
     * Diese Funktion dient dem Upgraden des Turmschadens.
     */
    func addDamage(){
        dmg = dmg+1
        dmgUpgrade = dmgUpgrade + 1
    }
    
    /**
     * Diese Funktion dient dem Upgraden des Angriffsgeschwindigkeit des Turms.
     */
    func addSpeed(){
        if speed > 0.1{
            speed = Double((round( (speed - 0.1)*10) )/10)
            speedUpgrade = speedUpgrade + 1
        }
    }
    
    /**
     * Diese Funktion dient dem Upgraden der Angriffsreichweite des Turms.
     */
    func addRange(){
        rangeUpgrade = rangeUpgrade + 1
        range = basicRange + basicRange * (Float(rangeUpgrade)/5)
    }
    
    
    /**
     * Diese macht den Reichweitenindikator des Turms sichtbar.
     */
    func addRangeIndicator(){
        var rangeIndication = SCNSphere()
        rangeIndication = SCNSphere(radius: CGFloat(range))
        rangeIndication.firstMaterial?.diffuse.contents = UIColor(red: 0/255, green: 255/255, blue: 0/255, alpha:0.5)
        rangeIndicationNode.geometry = rangeIndication

    }
    
    /**
     * Diese Funktion entfernt den Reichweitenindikator des Turms. (Dieser wird 100% transparent)
     */
    func removeRangeIndicator(){
        var rangeIndication = SCNSphere()
        rangeIndication = SCNSphere(radius: CGFloat(range))
        rangeIndication.firstMaterial?.diffuse.contents = UIColor(red: 0/255, green: 255/255, blue: 0/255, alpha:0.0)
        rangeIndicationNode.geometry = rangeIndication
    }
    
//FUNCTIONS END
//GETTER BEGIN
  
    /**
     * - Returns: Gibt die Position des Turmknotens zurück.
     */
    func getPosition() -> SCNVector3{
        return node.position
    }
    
    /**
     * - Returns: Gibt den Angriffsschaden des Turms zurück.
     */
    func getDmg() -> Int{
        return self.dmg
    }
    
    /**
     * - Returns: Gibt die Angriffsgeschwindigkeit des Turms zurück.
     */
    func getSpeed() -> Double{
        return self.speed
    }
    
    /**
     * - Returns: Gibt die Angriffsreichweite des Turms zurück.
     */
    func getRange() -> Float{
        return self.range
    }
    
    /**
     * - Returns: Gibt die Anzahl an Reichweitenupgrades des Turms zurück.
     */
    func getRangeUpgrade() -> Int{
        return rangeUpgrade
    }
    
    //upgradekosten
    /**
     * - Returns: Gibt die Upgradekosten für den Angriff des Turms zurück.
     */
    func getUpgradeCostsDmg() -> Double{
        return (basicPriceDmg + (basicPriceDmg * (2 * Double(dmgUpgrade))))
    }
    
    /**
     * - Returns: Gibt die Upgradekosten für die Angriffsgeschwindigkeit des Turms zurück.
     */
    func getUpgradeCostsSpeed() -> Double{
        return (basicPriceSpeed + (basicPriceSpeed * Double(speedUpgrade) * Double(speedUpgrade)))
    }
    
    /**
     * - Returns: Gibt die Upgradekosten für die Reichweite des Turms zurück.
     */
    func getUpgradeCostsRange() -> Double{
        return (basicPriceRange + (basicPriceRange * Double(rangeUpgrade) * Double(rangeUpgrade)))
    }
    
//GETTER END
//SETTER BEGIN
    
    /**
     * ## BASISWERT ##
     * Dieser Wert wird mit den Upgrades modifiziert.
     *
     * Diese Funktion legt den Basiswert für Angriffsgeschwindigkeit des Turms fest.
     */
    func setSpeed(speed: Double){
        self.speed = speed
    }
    
    /**
     * ## BASISWERT ##
     * Dieser Wert wird mit den Upgrades modifiziert.
     *
     * Diese Funktion legt den Basiswerte für die Angriffsreichweite des Turms fest.
     */
    func setRange(range: Float){
        self.range = range
    }
    
    /**
     * ## BASISWERT ##
     * Dieser Wert wird mit den Upgrades modifiziert.
     *
     * Diese Funktion legt den Basiswert für den Angriffsschaden des Turms fest.
     */
    func setDmg(dmg: Int){
        self.dmg = dmg
    }

//SETTER END
    
}

// ------------------------------------------------------------- KLASSE ENEMY ----------------------------------------------------------

/**
 * Diese Klasse stellt Gegner-Objekte zur Verfügung. Gegner benötigen den Pfad zum Ziel als SCNVector3 Array.
 * Nach erreichen des Ziels wird mit Hilfe von Notifications der GameObjectsController darüber informiert.
 */
class Enemy{
    var health: Int
    var node: SCNNode
    var speed: Double     //Steps per Second
    var dmg: Int
    
    var isRunning: Bool
    var path: [SCNVector3]
    var target: SCNVector3
    var targetPlayer: Int
    var finished: Bool
    var dead: Bool
    var healthbarNode: SCNNode
    
    var isStuck = false
    
    /**
     * Initialisierung eines Enemy-Objekts.
     *
     * - Parameter node: Knoten der zum Gegner werden soll.
     * - Parameter health: Die Start-Lebenspunkte des Gegners.
     * - Parameter speed: Die Laufgeschwindigkeit des Gegners. Dieser Wert entspricht der Zeit, die dieses Objekt benötigt um von einem Knoten zum nächsten zu kommen.
     * - Parameter dmg: Der Angriffsschaden des Gegners. Entspricht dem Wert, der beim Erreichen des Ziels von der Festung abgezogen wird.
     * - Parameter target: Die Position des Feldknotens, auf dem die Ziel-Festung steht.
     * - Parameter targetPlayer: Die Spielernummer/SpielerID des anzugreifenden Spielers
     */
    init (node: SCNNode, health: Int, speed: Double, dmg: Int,target: SCNVector3,targetPlayer: Int){
        self.node = node
        self.health = health
        self.speed = speed
        self.dmg = dmg
        
        self.isRunning = false
        self.path = []
        self.target = target
        self.targetPlayer = targetPlayer
        self.finished = false
        self.dead = false
        self.healthbarNode = SCNNode()
        addHealthbar(healthTextNode: healthbarNode)
    }

//FUNCTIONS BEGIN
    
    /**
     * Diese Funktion teilt dem Gegner einen neuen Pfad zu. Solle er feststecken "isStuck", wird seine Lauf-/Bewegungsfunktion erneut gestartet.
     *
     * - Parameter newPath: Ein SCNVector3 Array, das die Koordinaten der Feldknoten enthält, welche den kürzesten Pfad zum Ziel darstellen.
     */
    func setPath(newPath: [SCNVector3]){
        self.path = newPath
        if ((path.count > 0) && !isRunning){
            node.position = path[0]
            self.path.remove(at: 0)
        }
        if isStuck {
            isStuck = false
            startRunning()
        }
    }
    
    /**
     * Diese Funktion gibt die Entfernung von der aktuellen Position bis zum Ziel an.
     *
     * - Returns: Gibt Distanz der gesamten Laufwegs zwischen Gegner und Festung an.
     */
    func getDistanceOfPath() -> Float{
        var distance: Float = 0.0
        if path.count>0{
            distance = abs(node.position.distance(nodeB: path[0]))
        }
        if (path.count - 1) > 0{
            for i in 0 ..< (path.count - 1){
                distance = distance + abs(path[i].distance(nodeB: path[i+1]))
            }
        }
        return distance
    }
    
    /**
     * Diese Funktion startet die iterative Bewegungsanimationsfunktion.
     */
    func startRunning(){
        if path.count > 0{
            let move = SCNAction.move(to: path[0], duration: speed)
            isRunning = true
            
            node.runAction(move, completionHandler: { () in if (self.path.count > 0) {self.path.remove(at: 0)};    //Bewege dich so lange, bis Pfad leer ist.
                self.startRunning();
                if SCNVector3EqualToVector3(self.node.position, self.target){
                    self.finished = true
                    NotificationCenter.default.post(name: .targetReached, object: self)
                }
                
            })
            
            
        }else{              // Wenn Pfad Leer ist, aber das Ziel nicht erreicht wurde, markiere als Feststeckend
            isStuck = true
        }
    }
    
    /**
     * Diese Funktion Wertet den einkommenden Schaden aus und zieht diesen von den Lebensüunkten ab.
     *
     * - Parameter incDmg: Der Wert, der dieser Einheit als Schaden zugefügt werden soll.
     */
    func incomingDmg(incDmg: Int){
        self.health = self.health - incDmg
        if self.health <= 0{
            self.delete()
        }
        refreshHealthbar()
        
    }
    
    /**
     * Diese Funktion Entfernt den Knoten aus der Baumstruktur der Szene.
     *
     * ## Speicherverwaltung ##
     * Das Objekt wird als Tot deklariert. Eine Entfernung aus dem Enemy-Array findet nicht statt.
     * Dieser Eintrag wird nur zum Überschreiben freigegeben.
     */
    func delete(){
        self.node.removeFromParentNode()
        setIsDead()
        self.finished = false
    }
    
    
    /**
     * Diese Funktion fügt der Festung eine 3D-Text-Anzeige für die aktuellen Lebenspunkte hinzu.
     */
    func addHealthbar(healthTextNode: SCNNode){
        let healthText = SCNText(string: String(self.health), extrusionDepth: 0.1)
        healthText.firstMaterial?.diffuse.contents = UIColor.red
        healthText.font = UIFont.systemFont(ofSize: 1.0)
        let distance = NodeController().getNodeDistance()
        
        healthTextNode.geometry = healthText
        
        healthbarNode.position = SCNVector3(0-distance/4,distance-distance/2,0)
        healthbarNode.scale = SCNVector3(distance/2,distance/2,distance/2)
        
        
        node.addChildNode(healthTextNode)
        
    }
    
    /**
     * Diese Funktion dient der Aktuallisierung der Lebensanzeige.
     */
    func refreshHealthbar(){
        let healthText = SCNText(string: String(self.health), extrusionDepth: 0.1)
        healthText.firstMaterial?.diffuse.contents = UIColor.red
        healthText.font = UIFont.systemFont(ofSize: 1.0)

        self.healthbarNode.geometry = healthText
    }
    
    
//FUNCTIONS END
//GETTER BEGIN
    
    /**
     * - Returns: Gibt die Position des Gegnerknotens zurück.
     */
    func getPosition() -> SCNVector3{
        return node.position
    }
    
    /**
     * - Returns: Gibt zurück, ob der Gegner aktiv auf dem Weg zum Ziel ist.
     */
    func getIsRunning() -> Bool{
        return isRunning
    }
    
    /**
     * - Returns: Gibt die Position des mit der gestarteten Bewegung angestrebten Ziels zurück.
     * Diese Position entspricht der Position eines Feldknotens.
     * Ist kein Ziel vorhanden, wird die Position (-1,-1,-1) als Fehlermarkierung zurückgegeben.
     */
    func getCurrentTarget() -> SCNVector3{
        if (path.count > 0){
            return path[0]
            
        }
        return SCNVector3Make(-1,-1,-1)
    }
    
    /**
     * - Returns: Gibt den Schadenswert des Gegnerknotens zurück.
     */
    func getDmg() -> Int{
        return dmg
    }
    
    /**
     * - Returns: Gibt zurück, ob der Gegner sein Zeil erreicht hat.
     */
    func getFinished() -> Bool{
        return finished
    }
    
    /**
     * - Returns: Gibt zurück, ob dieser Gegner feststeckt.
     */
    func getIsStuck() -> Bool{
        return isStuck
    }
    
    /**
     * - Returns: Gibt die Spielernummer/SpielerID des Zielspielers, welcher angegriffen werden soll, zurück.
     */
    func getTargetPlayer() -> Int{
        return targetPlayer
    }
    
    /**
     * - Returns: Gibt zurück, ob dieser Gegner aus dem Spiel entfernt wurde und vom GameObjectsController überschrieben werden kann.
     */
    func getIsDead() -> Bool{
        return dead
    }
    
    

    
//GETTER END
//SETTER BEGIN
    
    /**
     * Diese Funktion legt fest, dass dieser Gegner in Bewegung ist.
     */
    func setIsRunning(){
        isRunning = true
    }
    
    /**
     * Diese Funktion legt das Ziel des Gegners fest.
     */
    func setTarget(pos: SCNVector3){
        self.target = pos
    }
    
    /**
     * Diese Funktion deklariert diesen Gegner als Tot.
     */
    func setIsDead(){
        dead = true
    }
    
//SETTER END
    
}
