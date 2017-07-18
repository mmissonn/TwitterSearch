//
//  model.swift
//  TwitterSearches
//
//  Created by Marc M on 2015-07-15.
//  Copyright (c) 2015 StratusCFO. All rights reserved.
//

import Foundation

protocol ModelDelegate {
    func modelDataChanged()
}

// Manages the saved searches
class Model {
    
    //keys used for storing app's data in app's NSUserDefaults
    private let pairsKey = "TwitterSearchesKVPairs"
    private let tagsKey = "TwitterSearchesKeyOrder"

    private var searches: [String: String] = [:]
    private var tags: [String] = []
    
    private let delegate: ModelDelegate

    // Initialize the Model
    init(delegate: ModelDelegate){
        self.delegate=delegate
        
        // get the NSUserDefaults object for the app
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        // Populate the dictionary with the user defaults
        if let pairs = userDefaults.dictionaryForKey(pairsKey){
            self.searches = pairs as! [String: String]
        }
        
        if let tags = userDefaults.dictionaryForKey(tagsKey){
            self.tags = tags as! [String]
        }
        
        // register to iCloud notifications - for key value store changes
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "updateSearches",
            name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.defaultStore())
    }
    
    // Called by the view controler to synchronize the model
    func synchronize(){
        // Synchronize with iCloud app data
        NSUbiquitousKeyValueStore.defaultStore().synchronize()
        
    }
    
    func tagAtIndex(index: Int) ->String{
        return tags[index]
        
    }
    
    func queryForTag(tag: String) ->String? {
        return searches[tag]
    }
    
    func queryForTagAtIndex(index: Int)->String? {
        return searches[tags[index]]
    }
    
    var count: Int{
        return tags.count
    }
    
    // Removes a search favorite in iCloud and in the user app data on the device
    func deleteSearchAtIndex(index: Int){
        searches.removeValueForKey(tags[index])
        let removedTag = tags.removeAtIndex(index)
        updateUserDefaults(updateTags: true, updateSearches: true)
        
        let keyValueStore = NSUbiquitousKeyValueStore.defaultStore()
        keyValueStore.removeObjectForKey(removedTag)
    }
    
    // Moves a search favorite
    func moveTagAtIndex(oldIndex: Int, toDestinationIndex newIndex: Int){
        let temp = tags.removeAtIndex(oldIndex)
        tags.insert(temp, atIndex: newIndex)
        updateUserDefaults(updateTags: true, updateSearches: false)
        
    }
    
    // Saves the list of favorite searches in the user app data (NSUSerDefaults)
    // # means: Requires the first parameter to be named in function calls
    func updateUserDefaults(# updateTags: Bool, updateSearches: Bool){
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if updateTags {
            userDefaults.setObject(tags, forKey: tagsKey)
            
        }
        if updateSearches{
            userDefaults.setObject(searches, forKey: pairsKey)
        }
        
        // Ensure that the user app data is saved on the device immediately
        userDefaults.synchronize()
    }
    
    // Observer registered with iCloud when the search favorites are updated
    @objc func updateSearches(notification: NSNotification){
        if let userInfo = notification.userInfo{
            if let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as!
                NSNumber? {
                    if reason.integerValue == NSUbiquitousKeyValueStoreServerChange ||
                       reason.integerValue ==
                        NSUbiquitousKeyValueStoreInitialSyncChange{
                            performUpdates(userInfo)
                    }
            }
        }
    }
    
    func performUpdates (userInfo: [NSObject: AnyObject?]){
        let changedKeysObject = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey]
        
        let changedKeys = changedKeysObject as! [String]
        
        let keyValueStore = NSUbiquitousKeyValueStore.defaultStore()
        
        for key in changedKeys {
            if let query = keyValueStore.stringForKey(key){
                saveQuery(query,forTag: key, syncToCloud: false)
                
            } else{
                let tempSearches = searches // iOS 8.1 bug workaround
                searches.removeValueForKey(key)
                tags = tags.filter{$0 != key}
                updateUserDefaults(updateTags: true, updateSearches: true)
                
            }
            
            //Update the view
            delete.modelDataChanged()
        }
    }
    
    func saveQuery(query: String, forTag tag: String, syncToCloud sync: Bool){
        let oldValue = searches.updateValue(query, forKey: tag)
        
        // If this a new key the value will be null
        if oldValue == nil {
            tags.insert(tag, atIndex: 0)
            updateUserDefaults(updateTags: true, updateSearches: true)
            
        } else{
            updateUserDefaults(updateTags: false, updateSearches: true)
        }
    
        // Add the search favorite to iCloud
        if sync {
            NSUbiquitousKeyValueStore.defaultStore().setObject(query, forKey: tag)
        }
    }
    
    
    
}