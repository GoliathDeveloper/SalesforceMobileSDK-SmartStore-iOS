//
//  SObjectData.swift
//
//  Created by Philip Guerreiro on 11/05/2016.
//  Copyright © 2016 Salesforce. All rights reserved.
//

import Foundation

class SObjectData: NSObject {
	
    var soupDict: NSDictionary = [:];
	
	override init() {
		super.init()
		for fieldName in self.dynamicType.dataSpec().fieldNames {
			self.updateSoupForFieldName(fieldName, fieldValue: nil)
		}
		self.updateSoupForFieldName("attributes", fieldValue: self.dynamicType.dataSpec().objectType)
	}
	
	convenience init(aSoupDict: [String: AnyObject]?) {
		self.init()
		if let soupDict = aSoupDict {
			for fieldName in soupDict.keys {
				self.updateSoupForFieldName(fieldName, fieldValue: soupDict[fieldName])
			}
		}
	}
	
	func updateSoupForFieldName(fieldName: String, fieldValue: AnyObject?) {
		var mutableSoup: [NSObject : AnyObject] = self.soupDict.mutableCopy() as! [NSObject : AnyObject]
		mutableSoup[fieldName] = fieldValue
		self.soupDict = mutableSoup
	}
	
	func fieldValueForFieldName(fieldName: String) -> AnyObject? {
		return self.nonNullFieldValue(fieldName)
	}
	
	func nonNullFieldValue(fieldName: String) -> AnyObject? {
		return self.soupDict.nonNullObjectForKey(fieldName)
	}
	
	func desc() -> String {
		return String(format: "<%@:%p> %@", self, self, self.soupDict)
	}
	
	// dataSpec is abstract.
	// needs to be override.
    class func dataSpec() -> SObjectDataSpec {
        return SObjectDataSpec()
    }
}

