//
//  Builder.swift
//  Justickets
//
//  Created by Arvindh Sukumar on 05/04/16.
//  Copyright © 2016 Arvindh Sukumar. All rights reserved.
//

import Foundation

enum AppID: String {
    case Justickets = "com.outsetapps.mobile.iphone.ticketdada"
    case Justickets_Staging = "in.justickets.Justickets-Staging"
}

let urls: [AppID: String] = [
    .Justickets : "https://www.dropbox.com/s/v125devagilitl4/config.json?dl=0&raw=1",
    .Justickets_Staging : "https://www.dropbox.com/s/myic1om5ku877tr/config.json?dl=0&raw=1"
]

class Builder: NSObject {
    var currentAppID: AppID = .Justickets_Staging
    var fileManager: NSFileManager
    var whiteLabelFolder: String {
        return "/whitelabel/\(currentAppID.rawValue)/"
    }
    let dispatch_group: dispatch_group_t = dispatch_group_create()
    
    override init(){
        self.fileManager = NSFileManager()
        super.init()
        fileManager.delegate = self
    }
    
    func start() -> Bool {
        fetchConfig()
        dispatch_group_wait(dispatch_group, DISPATCH_TIME_FOREVER)
        return true
    }
    
    func fetchConfig() {
        print(fileManager.currentDirectoryPath)
        
        dispatch_group_enter(dispatch_group)
        let request = try? Pidgey.GET(urls[currentAppID]!, queryParams: nil)
        request?.resume { (response, error) in
            
            let data = response?.data
            data?.writeToFile(self.configPath(), atomically: true)
            print("got config")
            if let config = response?.json as? NSDictionary {
                let assetsURL = config.valueForKey("ASSET_URL_IOS") as! String
                self.fetchAssets(assetsURL)
            }
            dispatch_group_leave(self.dispatch_group)
        }
        
    }
    
    func fetchAssets(url: String) {
        dispatch_group_enter(dispatch_group)
        let request = try? Pidgey.GET(url, queryParams: nil)
        request?.resume { (response, error) in
            
            let data = response?.data
            data?.writeToFile(self.pathForFileName("assets.zip"), atomically: true)
            print("got assets")
            dispatch_group_leave(self.dispatch_group)
        }
    }
    
    func copyAppIcon() {
        copyFile("appIcon.xcassets", fromPath: whiteLabelFolder, toPath: "/Justickets/")
    }
    
    func copyConfig() {
        copyFile("config.json", fromPath: whiteLabelFolder, toPath: "/Justickets/")
    }
    
    private func copyFile(fileName: String, fromPath: String, toPath: String) {
        let fromPath = fileManager.currentDirectoryPath + (fromPath as NSString).stringByAppendingPathComponent(fileName)
        let fromURL = NSURL(fileURLWithPath: fromPath)

        let toPath = fileManager.currentDirectoryPath + (toPath as NSString).stringByAppendingPathComponent(fileName)
        let toURL = NSURL(fileURLWithPath: toPath)
        
        print(fromURL)
        print(toURL)
        
        do {
            try fileManager.removeItemAtURL(toURL)
            try fileManager.copyItemAtURL(fromURL, toURL: toURL)
        }
        catch {
            
        }
    }
}

extension Builder {
    // File paths
    
    private func configPath() -> String {
        return pathForFileName("config.json")
    }
    
    private func pathForFileName(fileName: String) -> String {
        let toPath = fileManager.currentDirectoryPath + (whiteLabelFolder as NSString).stringByAppendingPathComponent(fileName)
        return toPath
    }
}

extension Builder: NSFileManagerDelegate {
    
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, copyingItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool {
        
        if error.code == NSFileWriteFileExistsError {
            return true
        }
        
        return false
    }
    
    
}

