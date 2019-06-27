//
//  nodeControl.swift
//  AR-Tower-Defence
//
//  Created by Hoffmann Mike on 03.01.19.
//  Copyright © 2019 Hoffmann Mike. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit

/**
 * ExtendedNode
 *
 * Diese Klasse dient der Erweiterung der Klasse SCNNode.
 * Es werden Status hinzugefügt, die das Auswerten des Spielfeldes vereinfachen.
 * Diese Status sind: blockiert (isBlocked), istFestung (isBase), istStartpunkt (isSpawn)
 */
public class ExtendedNode{
    var node: SCNNode
    var isBlocked: Bool
    var isBase: Bool
    var isSpawn: Bool
    
    /**
     * Initialisierung eines ExtendedNode-Objekts.
     *
     * - Parameter node: Knoten der um die Attribute eines ExtendedNode erweitert werden soll. Diese zusätzlichen Werte werden von Feldknoten benötigt.
     */
    init (node: SCNNode){
        self.node = node
        self.isBlocked = false
        self.isBase = false
        self.isSpawn = false
    }
    
//FUNCTIONS BEGIN
    
    /*
     * invertiert den Status istBlockiert (isBlocked)
     */
    func swapBlockedState(){
        if isBlocked{
            isBlocked = false
        }else{
            isBlocked = true
        }
    }
    
    /*
     * Setzt die Status zurück
     */
    func resetNode(){
        isBlocked = false
        isBase = false
        isSpawn = false
    }
    
//FUNCTIONS END
// GETTER BEGIN
    
    /*
     * - Returns: Gibt den SCNnode zurück.
     */
    func getNode() -> SCNNode{
        return node
    }
    
    /*
     * - Returns: Gibt die Position zurück.
     */
    func getPosition() -> SCNVector3{
        return node.worldPosition
    }
    
    /*
     * - Returns: Gibt die X-Koordinate der Position zurück.
     */
    func getNodePositionX() -> Float{
        return node.worldPosition.x
    }
    
    /*
     * - Returns: Gibt die Y-Koordinate der Position zurück.
     */
    func getNodePositionY() -> Float{
        return node.worldPosition.y
    }
    
    /*
     * - Returns: Gibt die Z-Koordinate der Position zurück.
     */
    func getNodePositionZ() -> Float{
        return node.worldPosition.z
    }
    
    /*
     * - Returns: Gibt zurück, ob dieser Knoten blockiert ist.
     */
    func getIsBlocked() -> Bool{
        return isBlocked
    }
    
    /*
     * - Returns: Gibt zurück, ob dieser Knoten der Startpunkt (Spawn) ist.
     */
    func getIsSpawn() -> Bool{
        return isSpawn
    }
    
    /*
     * - Returns: Gibt zurück, ob dieser Knoten die Festung (Base) ist.
     */
    func getIsBase() -> Bool{
        return isBase
    }
    
// GETTER END
// SETTER BEGIN
    
    /*
     * Setzt den Status auf: blockiert.
     */
    func setBlocked(){
        isBlocked = true
    }
    
    /*
     * Setzt den Status auf: istFestung (isBase).
     */
    func setBase(){
        if !isSpawn{
            isBase = true
            isBlocked = false
            self.node.geometry = NodeController().getGeometry(name: "blueBox")
        }
    }
    
    /*
     * Setzt den Status auf: istStartpunkt (isSpawn).
     */
    func setSpawn(){
        if !isBase{
            isSpawn = true
            isBlocked = false
            self.node.geometry = NodeController().getGeometry(name: "orangeBox")
            
        }
        
    }
// SETTER END
}


//---------------------------------------------KLASSE NodeController---------------------------------------------------------------------
/**
 * NodeController
 *
 * Diese Klasse dient der Handhabung der Feldknoten und das Aussehen sämtlicher Knoten in diesem Projekt.
 * Es werden die kürzesten Wege ermittelt und zurückgegeben.
 */
public class NodeController {
    // CONSTANTS
    // 0.01 entspricht einem Abstand von 1 cm
    // Dieser Wert muss der Spielkartengröße entsprechen.
    let NODE_DISTANCE = Float(0.1)
    
    var fieldNodes: [[ExtendedNode]] = []
    
    var fieldCornerNode = SCNNode()
    var fieldIsReady = false
    var fieldChanged = false
    var markerNode = SCNNode()

//FUNCTIONS BEGIN
    /**
     * Diese Funktion fügt den Eckknoten hinzu. Dieser wird benötigt um Spielfeldgrenzen festzulegen.
     * - Parameter rootNode: Wurzelknoten wird benötigt zum Anhängen weiterer Knoten.
     * - Parameter node: Position des Eckknoten.
     */
    func addCorner(rootNode: SCNNode, node: SCNNode){
        let cornerSphere = SCNSphere(radius: CGFloat(NODE_DISTANCE/10))
        cornerSphere.firstMaterial?.diffuse.contents = UIColor.yellow
        node.geometry = cornerSphere
        fieldCornerNode = node
        rootNode.addChildNode(node)
    }
 
    /**
     * Diese Funktion fügt an der übermittelten Position einen Marker als Knoten hinzu. Dieser dient nur als Test des Raycast.
     * - Parameter rootNode: Wurzelknoten wird benötigt zum Anhängen weiterer Knoten.
     * - Parameter node: Position des Raycast-Ergebnisses.
     */
    func addMarker(rootNode: SCNNode, node: SCNNode){
        markerNode.removeFromParentNode()
        markerNode = node
        let markerSphere = SCNSphere(radius: CGFloat(NODE_DISTANCE/10))
        markerSphere.firstMaterial?.diffuse.contents = UIColor.blue
        node.geometry = markerSphere
        rootNode.addChildNode(node)
    }
    
    // OPTIONALE FUNKTION -> FEATURE, dass entweder behalten oder Entfernt werden kann.
    /*
     * Diese Funktion dient dem Umschalten zwischen geblockt und nicht geblockt (per touch)
     * - Parameter position: Position, an welcher der Status geändert werden soll
     */
    /*
    func swapBlockedStateOfNearNodes(position: SCNVector3){
        var difference = SCNVector3()
        fieldNodes.map { array in
            array.map { node in
                difference = SCNVector3(
                    node.getNodePositionX()-position.x,
                    node.getNodePositionY()-position.y,
                    node.getNodePositionZ()-position.z
                )
                if abs(difference.x) <= NODE_DISTANCE/2 {
                    if abs(difference.y) <= NODE_DISTANCE{
                        if abs(difference.z) <= NODE_DISTANCE/2{
                            if !node.getIsBase() && !node.getIsSpawn(){
                                node.swapBlockedState()
                                if node.getBlockedState(){
                                    node.getNode().geometry = getGeometry(name: "redBox")
                                } else {
                                    node.getNode().geometry = getGeometry(name: "greenSphere")
                                }
                            }
                            //rootNode.addChildNode(node)
                        }
                    }
                }
            }
        }
     
        showShortestPath(shortestPath: getShortestPath(fromPos: (-1,-1)))
    }
    */
    
    //Rückgabe welcher ExtendedNode am nächsten an den Zielcoordinaten ist. (Muss innerhalb des Knoten-Bereiches sein)
    
    /**
     * Diese Funktion ermittelt den am nächsten liegenden Spielfeldknoten.
     * Befindet sich die mitgegebene Position nicht im Spielfeld, wird ein nodeDummy zurückgegeben. Dieser indiziert eine unerfolgreiche Knotensuche.
     *
     * - Parameter position: Die Position, an welcher der nächstgelegener Feldknoten ermittelt werden soll.
     * - Returns: Gibt den ermittelten Feldknoten (TYP: ExtendedNode) zurück. Bei unerfolgreicher Suche wird ein Dummy zurückgegeben, der die Position (-1,-1,-1) besitzt.
     */
    func getClosestNode(position: SCNVector3) -> ExtendedNode?{
        var difference = SCNVector3()
        let nodeDummy = SCNNode()
            nodeDummy.position = SCNVector3(-1,-1,-1)
        var foundNode = ExtendedNode(node: nodeDummy)
        fieldNodes.map { array in
            array.map { node in
                difference = SCNVector3(
                    node.getNodePositionX()-position.x,
                    node.getNodePositionY()-position.y,
                    node.getNodePositionZ()-position.z
                )
                if abs(difference.x) <= NODE_DISTANCE/2 {
                    if abs(difference.y) <= NODE_DISTANCE{
                        if abs(difference.z) <= NODE_DISTANCE/2{
                            foundNode = node
                        }
                    }
                }
            }
            
        }
        return foundNode
    }
    
    
    /**
     * Diese Funktion baut das Spielfeld innerhalb des gegebenen Rahmens auf.
     * ## Wichtige Information ##
     * In ARKit (mit Koordinatensystem von SceneKit) entspricht eine Koordinatenabwichung von 0.01 einem Abstand von 1 cm.
     *
     * - Parameter rootNode: Wurzelknoten wird benötigt zum Anhängen weiterer Knoten.
     */
    func setUpField(rootNode: SCNNode){
        print("Bau mir mein Spielfeld auf!")
        let greenSphere = SCNSphere(radius: CGFloat(NODE_DISTANCE/10))
        greenSphere.firstMaterial?.diffuse.contents = UIColor.green
        
        var newNode = SCNNode(geometry: greenSphere)
        
        var newExtendedNode = ExtendedNode(node: newNode)
        
        
        let maxZ = ((fieldCornerNode.worldPosition.z + NODE_DISTANCE/2 - rootNode.worldPosition.z) / NODE_DISTANCE).rounded(.down)
        let maxX = ((fieldCornerNode.worldPosition.x + NODE_DISTANCE/2 - rootNode.worldPosition.x) / NODE_DISTANCE).rounded(.down)

        
        for z in 0...Int(maxZ) {
            fieldNodes.append( [] )
            for x in 0...Int(maxX) {
                newNode = SCNNode(geometry: greenSphere)
                newNode.position = rootNode.position
                newNode.worldPosition.z += NODE_DISTANCE * Float(z)
                newNode.worldPosition.x += NODE_DISTANCE * Float(x)
                rootNode.addChildNode(newNode)
                newExtendedNode = ExtendedNode(node: newNode)
                fieldNodes[z].append( newExtendedNode )
            }
        }
        fieldIsReady = true
    }
    
    /**
     * Diese Funktion dient dem Empfang der Objektliste. Durch das Auswerten dieser, werden die Status der Feldknoten verändert.
     * ## Objekttypen ##
     * Es existieren 4 gültige Objekttypen:
     * spawn, base, wall und tower
     *
     * - Parameter objList: Eine ObjektArray, bestehend aus dem Tupel node und type. Diese geben den Objektknoten mit seinem typen an.
     */
    func receiveFieldupdate(objList: [(node: SCNNode ,type: String)]){
        resetFieldNodes()
        resetVisualsFieldNodes()
        
        for i in 0 ..< objList.count{
            let node = getClosestNode(position: objList[i].node.position)
            if (objList[i].type == "spawn"){
                node?.setSpawn()
            }
            if (objList[i].type == "base"){
                node?.setBase()
            }
            if (objList[i].type == "wall"){
                node?.setBlocked()
            }
            if (objList[i].type == "tower"){
                node?.setBlocked()
            }
            
        }
    }
    
    
    
    
    /**
     * Diese Funktion managt das Aussehen der Knoten. Jedes Knotendesign beitzt einen Namen. Es werden die benötigten Werte in Form von SCNGeometrys zurückgegeben.
     * Diese müssen daraufhin den Knoten zugewiesen werden. Existiert keine übereinstimmung wird eine "noneSphere" zurückgegeben.
     *
     * - Parameter name: Name des Aussehens.
     * - Returns: Rückgabe eines SCNGeometry-Elements mit dem gewünschten Aussehen.
     */
    func getGeometry(name: String) -> SCNGeometry{
        // Verwendete Geometries
        let greenSphere = SCNSphere(radius: CGFloat(NODE_DISTANCE/10))
        greenSphere.firstMaterial?.diffuse.contents = UIColor.green
        
        
        //BASE
        let baseBox = SCNBox(width: CGFloat(NODE_DISTANCE), height: CGFloat(NODE_DISTANCE), length: CGFloat(NODE_DISTANCE), chamferRadius: 0)
        baseBox.firstMaterial?.diffuse.contents = "base.png"
        //SPAWN
        let spawnBox = SCNBox(width: CGFloat(NODE_DISTANCE), height: CGFloat(NODE_DISTANCE), length: CGFloat(NODE_DISTANCE), chamferRadius: 0)
        spawnBox.firstMaterial?.diffuse.contents = UIImage(named: "spawn.png")
        
        //PATH
        let blueSphere = SCNSphere(radius: CGFloat(NODE_DISTANCE/20))
        blueSphere.firstMaterial?.diffuse.contents = UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha:1.0)
        //WALL
        let wall = SCNBox(width: CGFloat(NODE_DISTANCE), height: CGFloat(NODE_DISTANCE), length: CGFloat(NODE_DISTANCE), chamferRadius: 0)
        wall.firstMaterial?.diffuse.contents = "walltexture.jpg"
        //TOWER
        let tower = SCNBox(width: CGFloat(NODE_DISTANCE), height: CGFloat(NODE_DISTANCE*2), length: CGFloat(NODE_DISTANCE), chamferRadius: 0)
        tower.firstMaterial?.diffuse.contents = "tower.png"        
        //PROJECTILE
        let projectile = SCNSphere(radius: CGFloat(NODE_DISTANCE/10))
        projectile.firstMaterial?.diffuse.contents = UIColor.red
        
        //NONE (BEI FEHLERHAFTER ANGABE VON "name")
        let noneSphere = SCNSphere(radius: CGFloat(NODE_DISTANCE/20))
        noneSphere.firstMaterial?.diffuse.contents = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha:0.0)        //let material = SCNMaterial()
        //material.diffuse.contents =
        //redBox.materials = [material]
        
        
        
        //ENEMYS
        let magentaSphere = SCNSphere(radius: CGFloat(NODE_DISTANCE/3))
        magentaSphere.firstMaterial?.diffuse.contents = UIColor(red: 255/255, green: 0/255, blue: 255/255, alpha:1.0)
        
        
        //FAILED
        let failBox = SCNBox(width: CGFloat(NODE_DISTANCE), height: CGFloat(NODE_DISTANCE), length: CGFloat(NODE_DISTANCE), chamferRadius: 0)
        failBox.firstMaterial?.diffuse.contents = UIColor(red: 255/255, green: 0/255, blue: 233/255, alpha:0.5)
        
        switch name{
        case "wall":
            return wall
        case "tower":
            return tower
        case "projectile":
            return projectile
        case "greenSphere":
            return greenSphere
        case "baseBox":
            return baseBox
        case "spawnBox":
            return spawnBox
        case "blueSphere":
            return blueSphere
        case "magentaSphere":
            return magentaSphere
        case "none":
            return noneSphere
        default:
            return failBox
        }
    }
    
    
    
    

        
// -------------------------------------------- BSF und dafür benötigte Funkionen --------------------------------------------------------------
    
    /**
     * Diese Funktion nutzt den BSF-Algotithmus zur suche des kürzesten Weges.
     * ## BFS (Breadth First Search) ##
     * Finden des kürzesten Pfades von Spawn zu Base.
     * -1 = node geblockt
     *  0 = nicht geblockt
     *  1 = Startposition (spawn)
     *  2 = Endposition (base)
     *  9 = bereits Besucht
     *
     * fromPos = (-1,-1) => von spawnPos aus suchen
     *
     * - Parameter fromPos: Gibt eine X- und Y-Position im Spielfeldarray an. Diese wird als Startposition gesetzt. Bei der Position (-1,-1) wird die Position des Spawn verwendet.
     * - Returns: Gibt ein Array an Tupeln zurück. Diese x und y Werte, die den Positionen der Feldknoten im Spielfeldarray enspricht.
     */
    func getShortestPath(fromPos: (x: Int,y: Int)) -> [(x: Int, y: Int)]{
        //Variablen zur Speicherung des Pfades/Anzahl der Iterationen
        var iterations: Int
            iterations = 0
        var finalIteration = 0
        
        var listOfBSF: [(pos:(x: Int, y: Int), iteration: Int, prevIteration: Int)] = []
        var shortestPath: [(x: Int, y: Int)] = []
        var finished = false
        
        var spawnPos: (x: Int,y: Int)
        spawnPos = (x: 0, y: 0)
        
        var currentListPos = 0
        
        //ermitteln der Spielfeldgröße
        var rows: Int
        var columns: Int
        rows = fieldNodes.count
        if rows > 0 {
            columns = fieldNodes[0].count
        }else{
            columns = 0
        }
        
        // erstellen eines vereinfachten fieldArrays zum Anwenden des BFS (auswerten der ExtendedNode-Status)
        var simpleFieldArray = [[Int]](repeating: [Int](repeating: 0, count: columns), count: rows)
        
        for i in 0 ..< rows{
            for j in 0 ..< columns{
                if fieldNodes[i][j].getIsBlocked(){
                    simpleFieldArray[i][j] = -1
                } else if fieldNodes[i][j].getIsSpawn(){
                    simpleFieldArray[i][j] = 1
                    spawnPos = (i,j)
                    //print("SPAWN x: \(spawnPos.y) y: \(spawnPos.y)")
                    
                } else if fieldNodes[i][j].getIsBase(){
                    simpleFieldArray[i][j] = 2
                    //basePos = (i,j)
                    //print("BASE x: \(basePos.y) y: \(basePos.y)")
                } else {
                    simpleFieldArray[i][j] = 0
                }
            }
        }
        if (fromPos != (-1,-1)){
            spawnPos = fromPos
        }
        listOfBSF.append((pos: spawnPos, iteration: iterations, prevIteration: -1))
        
        // start der Baumerstellung. Absuche nach unmarkierten Knoten im Uhrzeigersinn.
        // Wird wiederholt, bis das Ziel gefunden wurde oder die maximale Suchdauer überschritten wird (entspricht der Anzahl an Feldknoten).
        while !finished{

            let neighbours = getNeighbours(simpleFieldArray: &simpleFieldArray,pos: listOfBSF[currentListPos].pos)
            //iterations = listOfBSF[currentListPos].iteration
            
            
        
                
            
            if neighbours.up == 0 || neighbours.up == 2 {
                iterations = iterations+1
                listOfBSF.append((pos: (((listOfBSF[currentListPos].pos.x)-1), listOfBSF[currentListPos].pos.y), iteration: iterations, prevIteration: listOfBSF[currentListPos].iteration))
                if neighbours.up == 2{
                    finalIteration = iterations
                }
                    
            }

            if neighbours.right == 0 || neighbours.right == 2 {
                iterations = iterations+1
                listOfBSF.append((pos: ((listOfBSF[currentListPos].pos.x), (listOfBSF[currentListPos].pos.y)+1), iteration: iterations, prevIteration: listOfBSF[currentListPos].iteration))
                if neighbours.right == 2{
                
                    finalIteration = iterations
                }
            }
            
            if neighbours.down == 0 || neighbours.down == 2 {
                iterations = iterations+1
                listOfBSF.append((pos: (((listOfBSF[currentListPos].pos.x)+1), listOfBSF[currentListPos].pos.y), iteration: iterations, prevIteration: listOfBSF[currentListPos].iteration))
                if neighbours.down == 2{
                    finalIteration = iterations
                }
            }
            
            if neighbours.left == 0 || neighbours.left == 2 {
                iterations = iterations+1
                listOfBSF.append((pos: ((listOfBSF[currentListPos].pos.x), (listOfBSF[currentListPos].pos.y)-1), iteration: iterations, prevIteration: listOfBSF[currentListPos].iteration))
                if neighbours.left == 2{
                    finalIteration = iterations
                }
            }
            
            //Abbruchbedingung: Kein Ziel gefunden
            currentListPos = currentListPos+1
            if currentListPos >= listOfBSF.count{
                finished = true
            }
            
            if (neighbours.up == 2) || (neighbours.right == 2) || (neighbours.down == 2) || (neighbours.left == 2) {
                for j in 0 ..< listOfBSF.count{
                    if listOfBSF[j].iteration == finalIteration{
                        currentListPos = j
                        shortestPath.insert(listOfBSF[currentListPos].pos, at: 0)
                    }
                }
                

                while listOfBSF[currentListPos].prevIteration != -1 {
                    for i in 0 ..< listOfBSF.count{
                        if listOfBSF[i].iteration == listOfBSF[currentListPos].prevIteration{
                            currentListPos = i
                            shortestPath.insert(listOfBSF[currentListPos].pos, at: 0)
                        }
                    }
                }
                
                finished = true
            }
            
            /* --------------------------------- TESTAUSGABE zum erkennen des Arrays ----------------------------------
            var arrToText = ""
            for i in 0 ..< rows{
                for j in 0 ..< columns{
                    arrToText.append("\(simpleFieldArray[i][j])")
                }
                print(arrToText)
                arrToText = ""
            }
             
            print("------------")
            // --------------------------------- TESTAUSGABE zum erkennen des Arrays ----------------------------------
            
            
            */
        }
        
        
        return shortestPath
    }
    
    /**
     * Diese Funktion liefert die x und y Position des Knotens in der Spielfeldmatrix. Dient der simplifizierung für den BSF.
     *
     * - Parameter fromPos: Position des Knotens, dessen Position in der Spielfeldknotenmatrix für den BSF benötigt wird.
     * - Returns: Gibt ein Tupel zurück. Dieses entspricht der x und y position in der Spielfeldmatrix. Unerfolgreiche suche gibt (-1,-1) zurück.
     */
    func getSimplePosition(pos: SCNVector3) -> (x: Int,y: Int){
        for i in 0 ..< fieldNodes.count{
            for j in 0 ..< fieldNodes[0].count{
                if (SCNVector3EqualToVector3(pos, fieldNodes[i][j].getPosition())){
                    //print("suche ab neuer Position")
                    return (i,j)
                }
            }
        }
        return (-1,-1)
    }
    
    /**
     * Diese Funktion liefert die Status der umliegenden Knoten innerhalb des simpleFieldArrays.
     * ## Wichtige Information INOUT ##
     * Diese Funktion erhält Zugriff auf das simpleFiledArray. Die abgesuchten Nachbarn erhalten den besuchtstatus "9" zugewiesen.
     *
     * - Parameter pos: Position von der aus die Nachbarn untersucht werden sollen.
     * - Returns: Gibt ein Tupel zurück. Dieses Entspricht den Status der umliegenden Feldknoten innerhalb des simpleFieldArrays.
     */
    func getNeighbours(simpleFieldArray: inout [[Int]], pos: (Int,Int)) -> (up: Int, right: Int, down: Int, left: Int){
        var rows: Int
        var columns: Int
        rows = fieldNodes.count
        if rows > 0 {
            columns = fieldNodes[0].count
        } else {
            columns = 0
        }
        var up = -1
        var right = -1
        var down = -1
        var left = -1
        if (pos.0)>=0 && (pos.1)>=0{
            if (pos.0)-1 >= 0{
                up = simpleFieldArray[(pos.0)-1][pos.1]
                simpleFieldArray[(pos.0)-1][(pos.1)] = 9
            }
            if (pos.1)+1 < columns{
                right = simpleFieldArray[pos.0][(pos.1)+1]
                simpleFieldArray[(pos.0)][(pos.1)+1] = 9
            }
            if (pos.0)+1 < rows{
                down = simpleFieldArray[(pos.0)+1][pos.1]
                simpleFieldArray[(pos.0)+1][(pos.1)] = 9
            }
            if (pos.1)-1 >= 0{
                left = simpleFieldArray[pos.0][(pos.1)-1]
                simpleFieldArray[(pos.0)][(pos.1)-1] = 9
            }
        
            simpleFieldArray[pos.0][pos.1] = 9
        }
        return (up, right, down, left)
    }
    
    /**
     * Diese Funktion liefert den kürzesten Weg als Vectorpositionsliste.
     * ## Wichtige Information ENEMY ##
     * Die Klasse Enemy benötigt den kürzesten Pfad als Vectorliste, da die Animation nicht mit Knoten, sondern nur mit Positionen arbeiten kann.
     *
     * - Parameter fromPos: Position als xy-Tupel, die der Position innerhalb der Spielfeldmatrix angibt. Von dieser Position aus soll die Pfadfindung gestartet werden.
     * - Returns: Gibt ein Array an VectorKoordinaten zurück (SCNVector3), die den kürzesten Weg zum Ziel ergeben.
     */
    func getShortestPathAsVectors(fromPos: (x: Int,y: Int)) -> [SCNVector3]{
        var shortestPath = getShortestPath(fromPos: fromPos)
        //print(shortestPath)
        var vector3Path: [SCNVector3] = []
        for i in 0 ..< shortestPath.count{
            vector3Path.append(fieldNodes[shortestPath[i].x][shortestPath[i].y].getPosition())
        }
        
        return vector3Path
    }
    
    /**
     * Diese Funktion ändert das Aussehen der Feldknoten. Alle Feldknoten, die auf dem kürzesten Pfad zwischen Spawn und Base liegen, erhalten eine neue geometry zugewiesen.
     *
     * - Parameter shortestPath: Der kürzeste Pfad, angegeben als xy-Positionen in der Feldknotenmatrix.
     */
    func showShortestPath(shortestPath: [(x: Int, y: Int)]){
        resetVisualsFieldNodes()
        if shortestPath.count != 0{
            for i in 1 ..< (shortestPath.count)-1{
                fieldNodes[shortestPath[i].x][shortestPath[i].y].node.geometry = getGeometry(name: "blueSphere")
            }
        }
    }
    
    /**
     * Diese Funktion startet die reset-Funktion für sämtliche Feldknoten
     */
    func resetFieldNodes(){
        for i in 0 ..< fieldNodes.count{
            for j in 0 ..< fieldNodes[i].count{
                fieldNodes[i][j].resetNode()
            }
        }
    }
    
    /**
     * Diese Funktion setzt das Aussehen der Feldknoten zurück.
     * Diese Funktion wird aufgerufen, wenn eine Feldaktuallisierung stattfindet.
     */
    func resetVisualsFieldNodes(){
        for i in 0 ..< fieldNodes.count{
            for j in 0 ..< fieldNodes[i].count{
                if fieldNodes[i][j].getIsBlocked(){
                    //fieldNodes[i][j].node.geometry = getGeometry(name: "redBox")
                    fieldNodes[i][j].node.geometry = getGeometry(name: "none")
                } else {
                    fieldNodes[i][j].node.geometry = getGeometry(name: "greenSphere")
                }
                if fieldNodes[i][j].getIsSpawn(){
                    //fieldNodes[i][j].node.geometry = getGeometry(name: "orangeBox")
                    fieldNodes[i][j].node.geometry = getGeometry(name: "none")
                }
                if fieldNodes[i][j].getIsBase(){
                    fieldNodes[i][j].node.geometry = getGeometry(name: "none")
                    //fieldNodes[i][j].node.geometry = getGeometry(name: "blueBox")
                }
                
            }
        }
    }
    
//FUNCTIONS END
//GETTER BEGIN
    
    /**
     * - Returns: Gibt die Koordinatenposition der Festung(Base) zurück.
     */
    func getBasePostion() -> SCNVector3{
        for i in 0 ..< fieldNodes.count{
            for j in 0 ..< fieldNodes[i].count{
                if (fieldNodes[i][j].getIsBase()) {
                    return fieldNodes[i][j].getPosition()
                }
            }
        }
        return SCNVector3Make(-1,-1,-1)
    }
    
    
    /**
     * - Returns: Gibt die Koordinatenposition der Gegnerstartposition(Spawn) zurück.
     */
    func getSpawnPosition() -> SCNVector3{
        for i in 0 ..< fieldNodes.count{
            for j in 0 ..< fieldNodes[i].count{
                if fieldNodes[i][j].isSpawn{
                    return fieldNodes[i][j].getPosition()
                }
                
                
            }
        }
        return SCNVector3Make(-1,-1,-1)
    }
    
    /**
     * - Returns: Gibt zurück, ob alle Bedingungen zur Spielfelderstellung erfüllt sind.
     */
    func getFieldIsReady() -> Bool {
        return fieldIsReady
    }
    
    /**
     * - Returns: Gibt den Koordinatenabstand zwischen den Feldknoten an.
     */
    func getNodeDistance() -> Float {
        return NODE_DISTANCE
    }
}


