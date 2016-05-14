//
//  SObjectDataFieldSpec.swift
//
//  Created by Philip Guerreiro on 11/05/2016.
//  Copyright © 2016 Salesforce. All rights reserved.
//

import UIKit

class SObjectDataFieldSpec: NSObject {
	
	var fieldName : String?
	var isSearchable : Bool?
    var isWriteable: Bool?
    init(fieldName: String, searchable: Bool,writeable: Bool){
		super.init()
		self.fieldName = fieldName
		self.isSearchable = searchable
        self.isWriteable = writeable
	}
}
