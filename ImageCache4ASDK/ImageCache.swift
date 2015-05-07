//
//  ImageCache.swift
//  ASDKLesson
//
//  Created by Pikaurd on 4/16/15.
//  Copyright (c) 2015 Shanghai Zuijiao Infomation Technology Inc. All rights reserved.
//

import Foundation
import AsyncDisplayKit

public class ImageCache: NSCache {
    static let kDefaultTimeoutLengthInNanoSeconds = 10 * 1_000_000_000 as Int64
    
    private let downloadConcurrentQueue: dispatch_queue_t
    private let workingConcurrentQueue: dispatch_queue_t
    private let directoryPath: String
    private let fileManager: NSFileManager
    private var downloadingMap: [NSURL : dispatch_semaphore_t]
    
    required public init(appGroupIdentifier: String? = .None) {
        downloadConcurrentQueue = dispatch_queue_create("net.zuijiao.async.DownloadQueue", DISPATCH_QUEUE_CONCURRENT)
        workingConcurrentQueue = dispatch_queue_create("net.zuijiao.async.WorkingQueue", DISPATCH_QUEUE_CONCURRENT)
        downloadingMap = [ : ]
        fileManager = NSFileManager.defaultManager()
        directoryPath = ImageCache.generateCacheDirectoryPathByAppGroupIdentifier(fileManager, appGroupIdentifier: appGroupIdentifier)
        
        super.init()
        
        dispatch_barrier_async(workingConcurrentQueue, { () -> Void in
            if !self.fileManager.fileExistsAtPath(self.directoryPath) {
                var error: NSError?
                self.fileManager.createDirectoryAtPath(self.directoryPath
                    , withIntermediateDirectories: false
                    , attributes: [:]
                    , error: &error)
                if let error = error {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        debugLog("error: \(error)")
                        exit(1)
                    })
                }
            }
        })
        
    }
    
    public func newASNetworkImageNode() -> ASNetworkImageNode {
        return ASNetworkImageNode(cache: self, downloader: self)
    }
    
    public func clearCache() -> () {
        dispatch_barrier_async(workingConcurrentQueue, { () -> Void in
            self.removeAllObjects()
            self.removePath(self.directoryPath)
        })
    }
    
    public func clearCache(key: NSURL) -> () {
        dispatch_barrier_async(workingConcurrentQueue, { () -> Void in
            self.removeObjectForKey(key)
            let filePath = self.getFilePath(key)
            self.removePath(filePath)
        })
    }
    
    private func removePath(path: String) -> () {
        if self.fileManager.fileExistsAtPath(path) {
            var error: NSError?
            self.fileManager.removeItemAtPath(path, error: &error)
            if let error = error {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    debugLog("error: \(error)")
                })
            }
        }
    }
    
    private func persistImage(image: UIImage, withKey key: NSURL) {
        dispatch_sync(workingConcurrentQueue, { () -> Void in
            self.setObject(image, forKey: key)
            let png = UIImagePNGRepresentation(image)
            png.writeToFile(self.getFilePath(key), atomically: true)
        })
    }
    
    public func fetchImage(key: NSURL) -> UIImage? {
        let resultImage: UIImage?
        if let hittedImage: AnyObject = self.objectForKey(key) { // memory
            resultImage = hittedImage as? UIImage
            debugLog("Hit")
        }
        else if imageInDiskCache(key) { // fetch from disk
            resultImage = UIImage(contentsOfFile: getFilePath(key))
            setObject(resultImage!, forKey: key)
            debugLog("Miss")
        }
        else { // Not hit
            resultImage = .None
        }
        
        return resultImage
    }
    
    private func imageInDiskCache(url: NSURL) -> Bool {
        return fileManager.fileExistsAtPath(getFilePath(url))
    }
    
    private func getFilePath(url: NSURL) -> String {
        return "\(directoryPath)/Cache_\(url.hash).png"
    }
    
    private func downloadImage(url: NSURL) -> UIImage? {
        if let _ = downloadingMap[url] {
            return .None // cancle thread 'cause the url was downloading
        }
        
        let sema = dispatch_semaphore_create(0)
        
        downloadingMap.updateValue(sema, forKey: url)
        
        dispatch_async(downloadConcurrentQueue, { () -> Void in
            if let data = NSData(contentsOfURL: url) {
                if let image = UIImage(data: data) {
                    self.persistImage(image, withKey: url)
                }
            }
            dispatch_semaphore_signal(sema)
        });
        
        let timeout = dispatch_time(DISPATCH_TIME_NOW, ImageCache.kDefaultTimeoutLengthInNanoSeconds)
        dispatch_semaphore_wait(sema, timeout);
        
        downloadingMap.removeValueForKey(url)
        
        let resultImage = fetchImage(url)
        return resultImage
    }
    
    private static func generateCacheDirectoryPathByAppGroupIdentifier(fileManager: NSFileManager, appGroupIdentifier: String?) -> String {
        let foldername = "Library/Caches/net.zuijiao.ios.asyncdisplay.ImageCache"
        let path: String
        if let appGroupIdentifier = appGroupIdentifier {
            let url = fileManager.containerURLForSecurityApplicationGroupIdentifier(appGroupIdentifier)
            let folderUrl = url!.URLByAppendingPathComponent(foldername).absoluteString!
            path = folderUrl.substringFromIndex(advance(folderUrl.startIndex, 7))
        }
        else {
            path = "\(NSHomeDirectory())\(foldername)"
        }
        return path
    }
    
}

extension ImageCache: ASImageCacheProtocol {
    
    public func fetchCachedImageWithURL(
        URL: NSURL!
        , callbackQueue: dispatch_queue_t!
        , completion: ((CGImage!) -> Void)!
        ) -> ()
    {
        dispatch_async(callbackQueue, { () -> Void in
            completion(self.fetchImage(URL)?.CGImage)
        })
    }
    
}

extension ImageCache: ASImageDownloaderProtocol {
    
    public func downloadImageWithURL(
        URL: NSURL!
        , callbackQueue: dispatch_queue_t!
        , downloadProgressBlock: ((CGFloat) -> Void)!
        , completion: ((CGImage!, NSError!) -> Void)!)
        -> AnyObject!
    {
        dispatch_async(workingConcurrentQueue, { () -> Void in
            var error: NSError?
            let resultImage: UIImage! = self.downloadImage(URL)
            if resultImage == .None {
                error = NSError(domain: "net.zuijiao.ios.async", code: 0x1, userInfo: ["Reason": "download failed"])
            }
            
            dispatch_async(callbackQueue, { () -> Void in
                completion(resultImage?.CGImage, error)
            })
        })
        
        return .None // not implement cancle method
    }
    
    public func cancelImageDownloadForIdentifier(downloadIdentifier: AnyObject!) {
        debugLog("[Not implement] Do nothing")
    }
}

private class DownloadState {
    let semaphore: dispatch_semaphore_t
    let task: NSURLSessionTask
    
    required init(semaphore: dispatch_semaphore_t, task: NSURLSessionTask) {
        self.semaphore = semaphore
        self.task = task
    }
}















