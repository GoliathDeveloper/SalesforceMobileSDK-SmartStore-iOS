//
//  SObjectDataManager.swift
//
//  Created by Philip Guerreiro on 11/05/2016.
//  Copyright © 2016 Salesforce. All rights reserved.
//

import Foundation
import SmartStore
import SalesforceSDKCore
import SmartSync
import UIKit

class SObjectDataManager:NSObject {
    
    let dataSpec: SObjectDataSpec
    let syncManager: SFSmartSyncSyncManager
    var syncDownId: Int = 0
    let kSyncLimit = 10000
    let kMaxQueryPageSize: UInt = 1000
    var dataRows: NSArray?;
    var fullDataRowList: NSArray?
    weak var parentVc: UITableViewController?
    init(theDataSpec: SObjectDataSpec) {
        dataSpec = theDataSpec
        syncManager = SFSmartSyncSyncManager.sharedInstance(SFUserAccountManager.sharedInstance().currentUser)
    }
    
    func store() -> SFSmartStore {
        return SFSmartStore.sharedStoreWithName(kDefaultSmartStoreName) as! SFSmartStore
    }
    
    func refreshRemoteData() {
        if !store().soupExists(self.dataSpec.soupName) {
            self.registerSoup()
        }
        
        weak var weakSelf = self
        let updateBlock: SFSyncSyncManagerUpdateBlock = { sync in
            if sync.isDone() || sync.hasFailed() {
                weakSelf?.syncDownId = sync.syncId
                weakSelf?.refreshLocalData()
            }
        }
        
        if self.syncDownId == 0 {
            // first time
            let strJoined = self.dataSpec.fieldNamesArray().componentsJoinedByString(",");
            let strTable:String = (self.dataSpec.objectType)! as String;
            let soqlQuery: String = String(format: "SELECT %@ FROM %@ LIMIT 10000",strJoined,strTable,CUnsignedLong(kSyncLimit));

            let syncOptions = SFSyncOptions.newSyncOptionsForSyncDown(SFSyncStateMergeMode.LeaveIfChanged)
            let syncTarget = SFSoqlSyncDownTarget.newSyncTarget(soqlQuery)
            self.syncManager.syncDownWithTarget(syncTarget, options: syncOptions, soupName: self.dataSpec.soupName, updateBlock: updateBlock)
        }
        else {
            // subsequent times
            self.syncManager.reSync(self.syncDownId, updateBlock: updateBlock)
        }
    }
    
    func updateRemoteData(updateBlock: SFSyncSyncManagerUpdateBlock) {
        // Added for loop to check if field is writeable and create new array of string
        var mutableFieldNames = [String]()
        for t in self.dataSpec.objectFieldSpecs{
            let t = t as! SObjectDataFieldSpec;
            if t.isWriteable == true{
                mutableFieldNames.append(t.fieldName!)
            }
        }
        let syncOptions = SFSyncOptions.newSyncOptionsForSyncUp(mutableFieldNames, mergeMode: SFSyncStateMergeMode.LeaveIfChanged)
        self.syncManager.syncUpWithOptions(syncOptions, soupName: self.dataSpec.soupName) { syncState in
            if syncState.isDone() || syncState.hasFailed() {
                updateBlock(syncState)
            }
        }
    }
    
    func registerSoup() {
        // Updated as previous function was depreciated encapsulated in do and try to handle errors
        let soupName: String = self.dataSpec.soupName!
        let indexSpecs: [AnyObject] = self.dataSpec.indexSpecs as [AnyObject]
        do{
            try self.store().registerSoup(soupName, withIndexSpecs: indexSpecs,error: ())
        }catch let error as NSError {
            print("Soup Error: \(error.localizedDescription)")
        }
    }
    
    func refreshLocalData() {
        if (!self.store().soupExists(self.dataSpec.soupName)) {
            self.registerSoup()
        }
        var sobjectsQuerySpec: SFQuerySpec;
        sobjectsQuerySpec = SFQuerySpec.newAllQuerySpec(self.dataSpec.soupName, withOrderPath: self.dataSpec.orderByFieldName! as String, withOrder: SFSoupQuerySortOrder.Ascending, withPageSize: kMaxQueryPageSize)
        var queryResults: NSArray ;
        
        do{
            queryResults = try self.store().queryWithQuerySpec(sobjectsQuerySpec, pageIndex: 0);
            self.log(SFLogLevel.Debug, msg: "Got local query results.  Populating data rows.")
        }catch let error as NSError {
            self.log(SFLogLevel.Error, msg: String(format: "Error retrieving '%@' data from SmartStore: %@", self.dataSpec.objectType!,error))
            return
        }
        if queryResults.count > 0{
            self.fullDataRowList = self.populateDataRows(queryResults) as? NSArray
            self.log(SFLogLevel.Debug, msg: String(format: "Finished generating data rows.  Number of rows: %d.  Refreshing view.",self.fullDataRowList!.count))
            
        }else{
            let mutableDataRows: NSMutableArray = NSMutableArray(capacity :queryResults.count)
            self.fullDataRowList = mutableDataRows;
            self.log(SFLogLevel.Debug, msg: String(format: "Philz: No Results in Query.  Number of rows: %d.  Refreshing view.",0))
        }
        self.resetDataRows()
    }
    
    func createLocalData(data: SObjectData) {
        data.updateSoupForFieldName(kSyncManagerLocal, fieldValue: true)
        data.updateSoupForFieldName(kSyncManagerLocallyCreated, fieldValue: true)
        self.store().upsertEntries([ data.soupDict ], toSoup: data.dynamicType.dataSpec().soupName)
    }
    
    func updateLocalData(data: SObjectData) {
        data.updateSoupForFieldName(kSyncManagerLocal, fieldValue: true)
        data.updateSoupForFieldName(kSyncManagerLocallyUpdated, fieldValue: true)
        // Updated as previous function was depreciated encapsulated in do and try to handle errors
        do{
            try self.store().upsertEntries([data.soupDict], toSoup: data.dynamicType.dataSpec().soupName, withExternalIdPath:SObjectDataSpec.kSObjectIdField)
        }
        catch let error as NSError {
            print("Soup Error: \(error.localizedDescription)")
        }
    }
    
    func deleteLocalData(data: SObjectData) {
        data.updateSoupForFieldName(kSyncManagerLocal, fieldValue: true)
        data.updateSoupForFieldName(kSyncManagerLocallyDeleted, fieldValue: true)
        // Updated as previous function was depreciated encapsulated in do and try to handle errors
        do{
            try self.store().upsertEntries([data.soupDict], toSoup: data.dynamicType.dataSpec().soupName, withExternalIdPath: SObjectDataSpec.kSObjectIdField)
        }
        catch let error as NSError {
            print("Soup Error: \(error.localizedDescription)")
        }
    }
    
    func dataHasLocalChanges(data: SObjectData) -> Bool {
        if let value = data.fieldValueForFieldName(kSyncManagerLocal) as? Bool {
            return value
        }
        return false
    }
    
    func dataLocallyCreated(data: SObjectData) -> Bool {
        if let value = data.fieldValueForFieldName(kSyncManagerLocallyCreated) as? Bool {
            return value
        }
        return false
    }
    
    func dataLocallyUpdate(data: SObjectData) -> Bool {
        if let value = data.fieldValueForFieldName(kSyncManagerLocallyUpdated) as? Bool {
            return value
        }
        return false
    }
    
    func dataLocallyDeleted(data: SObjectData) -> Bool {
        if let value = data.fieldValueForFieldName(kSyncManagerLocallyDeleted) as? Bool {
            return value
        }
        return false
    }
    
    // Added intermediate function to wipe everything and start again until SDK 4.2
    func repopulateSoup(){
        let weakSelf: SObjectDataManager = self;
        let soupName: String = (weakSelf.dataSpec.soupName)!;
        let indexSpecs:[AnyObject] = (weakSelf.dataSpec.indexSpecs) as [AnyObject];
        do{
            try self.store().registerSoup(soupName, withIndexSpecs: indexSpecs, error: ())
        }
        catch let error as NSError {
            print("Soup Error: \(error.localizedDescription)")
        }
        
        self.store().removeSoup(soupName);
        self.syncDownId = 0;
        self.refreshRemoteData();
        self.refreshLocalData();
    }

    
    func populateDataRows(queryResults: NSArray) -> AnyObject{
        let mutableDataRows: NSMutableArray = NSMutableArray(capacity :queryResults.count)
        for soup in queryResults {
            let t = self.createSObjectData(soup as! [String : AnyObject]);
            mutableDataRows.addObject(t);
        }
        return mutableDataRows
    }
    // Reset Data Rows
    func resetDataRows() {
        self.dataRows = self.fullDataRowList!.copy() as? NSArray
        let weakSelf: SObjectDataManager = self
        dispatch_async(dispatch_get_main_queue(), {	weakSelf.parentVc!.tableView.reloadData()
            
        })
    }
    
    // needs to be override by subclass otherwise will cause "Could not cast value of type" exception
    func createSObjectData(soupDict: [String: AnyObject]) -> SObjectData {
        return SObjectData(aSoupDict: soupDict)
    }
}

