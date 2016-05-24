# SalesforceMobileSDK-SmartStore-iOS
Salesforce Mobile SDK SmartStore Development Example For iOS Swift 2.2

I've created this to expand on the initial SmartSyncExplorer native sample provided in [SalesforceMobileSDK-iOS repository](https://github.com/forcedotcom/SalesforceMobileSDK-iOS).

These coding samples use a modified version of the original SObject* classes provided by Salesforce but upgraded to Swift 2.2 using the latest SDK at this time (May 2016) 4.1.2.

The main reason behind this upgrade and modification was formula field you can retrieve them but syncing back causes exceptions because they are ready only, the isWriteable flag allows you to specify in the framework which fields you want written back to the force.com platform.

## Modifications
- ive added a isWriteable bool to the SObjectDataFieldSpec  
- SObjectDataManager updateRemoteData has a for loop to only pick the writable fields that you want to be updated in Salesforce

## Requirements
* [SalesforceMobileSDK-iOS (4.1.2)](https://github.com/forcedotcom/SalesforceMobileSDK-iOS)

## Usage
Use the SObject classes to utilise the SmartStore Offline data framework read more here [Mobile SDK Development Guide: Using SmartStore to Securely Store Offline Data](https://developer.salesforce.com/docs/atlas.en-us.mobile_sdk.meta/mobile_sdk/offline_intro.htm)

## Examples
Coming Soon

## Recommendations
- Use [Cocoa Pods](https://cocoapods.org/) the package manager for Xcode projects
