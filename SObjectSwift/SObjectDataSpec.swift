//
//  SObjectDataSpec.swift
//
//  Created by Philip Guerreiro on 11/05/2016.
//  Copyright © 2016 Salesforce. All rights reserved.
//
import Foundation
import SmartStore
import SalesforceSDKCore
import SmartSync
import UIKit

class SObjectDataSpec: NSObject {
	
	static let kSObjectIdField : String = "Id"

	
	let kSyncManagerLocal : String = "__local__"
    let kSoupIndexTypeString : String  = "string";

	
	var objectType : String?
	var objectFieldSpecs = [AnyObject]()
	var indexSpecs = [AnyObject]()
	var soupName : String?
	var orderByFieldName : String?
	
	var fieldNames:[String] {
		get {
			var mutableFieldNames = [String]()
			for fieldSpec in self.objectFieldSpecs {
				let fSpec = fieldSpec as! SObjectDataFieldSpec
				mutableFieldNames.append(fSpec.fieldName!)
			}
			return mutableFieldNames
		}
	}
	
    // createSObjectData is abstract.
    // needs to be override.
    class func createSObjectData(soupDict: [String: AnyObject]) -> SObjectData {
        return SObjectData()
    }
    
    // added function to return array of all field names
    func fieldNamesArray() -> NSArray {
        let mutableFieldNames: NSMutableArray = NSMutableArray(capacity: self.objectFieldSpecs.count);
        for fieldSpec in self.objectFieldSpecs{
            let localfieldSpec = fieldSpec as! SObjectDataFieldSpec;
            mutableFieldNames.addObject(localfieldSpec.fieldName!);
        }
        return mutableFieldNames;
    }
    
	var soupFieldNames : [AnyObject]{
		get {
			var retNames = [AnyObject]()
			for fieldSpec in self.objectFieldSpecs {
				let fSpec = fieldSpec as! SObjectDataFieldSpec
				retNames.append(String(format:"{%@:%@}", self.soupName!, fSpec.fieldName!))
			}
			return retNames
		}
	}
	
    override init() {
    }
	
	
	init(objectType: String, objectFieldSpecs: [AnyObject], indexSpecs: [AnyObject], soupName: String, orderByFieldName: String){
		super.init()
		self.objectType = objectType;
		self.objectFieldSpecs = buildObjectFieldSpecs(objectFieldSpecs)
		self.indexSpecs = buildSoupIndexSpecs(indexSpecs)
		self.soupName = soupName
		self.orderByFieldName = orderByFieldName
	}

	func buildObjectFieldSpecs(origObjectFieldSpecs: [AnyObject])->[AnyObject]{
		var foundIdFieldSpec : Bool = false
		for fieldSpec in origObjectFieldSpecs {
			let fSpec = fieldSpec as! SObjectDataFieldSpec
			let isEqual = (fSpec.fieldName == SObjectDataSpec.kSObjectIdField)
			if (isEqual == true) {
				foundIdFieldSpec = true
				break
			}
		}
		
		if (foundIdFieldSpec == false){
			var objectFieldSpecsWithId = origObjectFieldSpecs
			let idSpec = SObjectDataFieldSpec(fieldName: SObjectDataSpec.kSObjectIdField, searchable: false,writeable: true)
			objectFieldSpecsWithId.insert(idSpec, atIndex: 0)
			return objectFieldSpecsWithId
		}else{
			return origObjectFieldSpecs
		}
		
	}
	
	
	func buildSoupIndexSpecs(origIndexSpecs: [AnyObject])->[AnyObject]{
		var mutableIndexSpecs = origIndexSpecs
		let isLocalDataIndexSpec = SFSoupIndex(path: kSyncManagerLocal, indexType: kSoupIndexTypeString, columnName: kSyncManagerLocal)
		mutableIndexSpecs.insert(isLocalDataIndexSpec, atIndex: 0)
		
		var foundIdFieldSpec : Bool = false
		for indexSpec in origIndexSpecs {
			let indSpec = indexSpec as! SFSoupIndex
			let isEqual = (indSpec.path == SObjectDataSpec.kSObjectIdField)
			if (isEqual == true) {
				foundIdFieldSpec = true
				break
			}
		}
		
		if (foundIdFieldSpec == false){
			let idIndexSpec = SFSoupIndex(path: SObjectDataSpec.kSObjectIdField, indexType: kSoupIndexTypeString, columnName: SObjectDataSpec.kSObjectIdField)
			mutableIndexSpecs.insert(idIndexSpec, atIndex: 0)
		}
		
		return mutableIndexSpecs
	}
	
}
