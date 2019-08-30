//
//  Debugger.swift
//  DynamicBrushes
//
//  Created by JENNIFER  JACOBS on 2/15/19.
//  Copyright © 2019 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON
import Macaw

final class Debugger {
    static public let debugInterval:Int = 1
    static public var debugTimer:Timer! = nil
    static public let debuggerEvent = Event<(String)>();

    
    static private var debuggingActive = false;
    static var propSort = ["ox","oy","sx","sy","rotation","dx","dy","x","y","radius","theta","diameter","hue","lightness","saturation","alpha"]

    static public func activate(){
        Debugger.debuggingActive = true;
        Debugger.debuggerEvent.raise(data: ("INIT"));
    }
    
    static public func deactivate(){
        debuggingActive = false;
    }
    
    static public func orderProps(propList:[JSON])->[JSON]{
        var _propList = propList;
        var sortedMappings = [JSON]();

        propSort.forEach { key in
        var found = false;
        _propList = _propList.filter { (mapping) -> Bool in
            
            if( !found && mapping["relativePropertyName"].stringValue == key){
                sortedMappings.append(mapping);
                found = true;
                return false;
            } else{
                return true;
            }
        }
        }
        return sortedMappings;
    }
    
    static public func startDebugTimer(interval:Int){
        self.endDebugTimer();
        Debugger.debugTimer = Timer(timeInterval: TimeInterval(interval), target: self, selector: #selector(Debugger.fireDebugUpdate), userInfo: nil, repeats: true)
        RunLoop.current.add(debugTimer, forMode: RunLoop.Mode.common)
    }
    
    
   static public func endDebugTimer(){
        if(Debugger.debugTimer != nil){
            Debugger.debugTimer.invalidate();
        }
        Debugger.debugTimer = nil;
    }
    

    static func generateOutputDebugData()->JSON{
        var debugData:JSON = [:]
          debugData["groupName"] = JSON("output");
        debugData["behaviors"] = BehaviorManager.drawing.activeStrokesToJSON();
        return debugData;
    }
    
    
  static func generateInputDebugData()->JSON{
       
        var debugData:JSON = [:]
        let generatorCollectionsJSON = Debugger.generateGeneratorDebugData();
        
        let liveCollections = BehaviorManager.signalCollections[3];
        var liveCollectionsJSON:JSON = [:]
        liveCollectionsJSON["groupName"] = JSON("inputGlobal");
        var globalItems = [JSON]();
    
        for(key,value) in liveCollections{
            var liveData:JSON = [:]
            liveData["params"] = value.paramsToJSON();
            liveData["name"] = JSON(key);
            liveData["id"] = JSON(key);
            globalItems.append(liveData);
        }
    
        liveCollectionsJSON["items"] = JSON(globalItems);
        debugData["generator"] = generatorCollectionsJSON;
    
        debugData["inputGlobal"] = liveCollectionsJSON;

        return debugData;
    }
    
    static func generateGeneratorDebugData()->JSON{
        
        let generatorCollections = BehaviorManager.signalCollections[2];
        var generatorCollectionsJSON:JSON = [:]
        generatorCollectionsJSON["groupName"] = JSON("generator");
        
        for(key,value) in generatorCollections{
            var generatorData:JSON = [:]
            generatorData["params"] = value.paramsToJSON();
            generatorData["name"] = JSON(key);
            generatorData["id"] = JSON(key);
            generatorCollectionsJSON[key] = generatorData;
        }
        
        
       return generatorCollectionsJSON;
    }
    
    static func generateSingleBrushDebugData(brush:Brush)->JSON{
        var debugData:JSON = [:]
        debugData["behaviorId"] = JSON(brush.behaviorDef!.id);
        debugData["prevState"] = JSON(brush.prevState);
        debugData["currentState"] = JSON(brush.currentState);
        debugData["transitionId"] = JSON(brush.prevTransition);
        debugData["params"] = brush.params.toJSON();
        debugData["id"] = JSON(brush.id);
        debugData["constraints"] = brush.states[brush.currentState]!.getConstrainedPropertyNames();
        debugData["methods"] = brush.transitions[brush.prevTransition]!.getMethodNames();
        return debugData;
    }
    
    static func generateBrushDebugData()->JSON{
        var debugData:JSON = [:]
        debugData["groupName"] = JSON("brush");
        var behaviorListJSON = [JSON]();
        var brushesListJSON = [JSON]();
        let behaviors = BehaviorManager.getAllBrushInstances();
        for (behaviorId,brushTuple) in behaviors {
            let behaviorName = brushTuple.0;
            let brushes = brushTuple.1;
            for brush in brushes {
                var brushJSON = generateSingleBrushDebugData(brush: brush);
                brushJSON["name"] = JSON(brush.name);
                brushesListJSON.append(brushJSON);
        }
            var behaviorJSON:JSON = [:];
            behaviorJSON["id"] = JSON(behaviorId);
            behaviorJSON["name"] = JSON(behaviorName);
            behaviorJSON["brushes"] = JSON(brushesListJSON);
            behaviorListJSON.append(behaviorJSON);
            
        debugData["behaviors"] = JSON(behaviorListJSON);
        }

        return debugData;
    }
    
    
    static public func  generateDebugData()->JSON{
        let inputData = Debugger.generateInputDebugData();
        let brushData = Debugger.generateBrushDebugData();
        let outputData = Debugger.generateOutputDebugData();
        var debugData:JSON = [:];
        debugData["brush"] = brushData;
        debugData["input"] = inputData;
        debugData["output"] = outputData;
        return debugData;
    }
    
    @objc static func fireDebugUpdate(){
        let debugData = Debugger.generateDebugData();
        let socketRequest = Request(target: "socket", action: "send_inspector_data", data: debugData, requester: RequestHandler.sharedInstance)
        RequestHandler.addRequest(requestData: socketRequest)
    }
    
    static public func getGeneratorValue(brushId:String) -> [(Double,Int,String)] {
        var val = -1.0
        var time = -1
        var type = "none"
        var freq:Float = -1.0
        var returnVals:[(val:Double,time:Int,type:String)] = []
        let generatorJSON = Debugger.generateGeneratorDebugData()
        if generatorJSON["default"].exists()  {
            let params:JSON = generatorJSON["default"]["params"]
            for (_, subJsonArr):(String, JSON) in params {
                for (_, subJson):(String, JSON) in subJsonArr {
                    if (subJson["brushId"].string == brushId) {
                        val = subJson["v"].double ?? -1.0
                        time = subJson["time"].int ?? -1
                        type = subJson["generatorType"].string ?? "none"
//                        if subJson["settings"].exists() {
                        print("FREQUENCY OF SINE IS ~~~~~~ ", params.rawString())

//                        }
                        returnVals.append((val:val, time:time, type:type))
                        
                    }
                }
            }
        }
        return returnVals
    }
    
    static public func drawUnrendererdBrushes(view:BrushGraphicsView){
        let behaviors = BehaviorManager.getAllBrushInstances();
        //check to see which brushes are "unrendered"
       // pass them the UI view and draw into it
        var brushIds = Set<String>()
        var i = 0 //note - this is only until we get active instance
        for (behaviorId,brushTuple) in behaviors {
            let brushes = brushTuple.1;
            let brush = brushes[0]
//            for brush in brushes {
            if brush.unrendered && i < 1 {
                print("~~~ about to draw into context in debugger with brush ", brush.id)
                brush.drawIntoContext(context:view)
                let valArray = Debugger.getGeneratorValue(brushId: brush.id)
                view.scene!.drawGenerator(valArray: valArray)
            
                i += 1
            }
            brushIds.insert(brush.id)
//            }
        }
        //remove brush if not in this list
        let brushesIdsOnCanvas = Set(view.scene!.activeBrushIds.keys)
        
        let keysToRemove = Array(brushesIdsOnCanvas.symmetricDifference(brushIds))
//        print("##keys to remove is ", keysToRemove)
        for id in keysToRemove {
            view.scene!.removeActiveId(id:id)
            view.updateNode()
        }
        
    }
    
    
    static func jumpToState(stroke:Stroke,segment:Segment){
        var brushId = stroke.brushId;
        var behaviorId = stroke.behaviorId;
        var brush = BehaviorManager.getBrushById(behaviorId: behaviorId, brushId:brushId);
        
        var time = segment.time;
        
        
        
        
    }
    
}
