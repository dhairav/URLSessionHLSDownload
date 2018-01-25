//
//  DownloadSessionDelegate.swift
//  ConcurrencyDemo
//
//  Created by Dhairav Mehta on 23/01/18.
//  Copyright © 2018 Hossam Ghareeb. All rights reserved.
//

import Foundation

struct SessionProperties {
    static let identifier:String! = "url_session_background_download"
}


typealias CompleteHandlerBlock = () -> ()
class DownloadSessionDelegate : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
    }
    
    
    var handlerQueue: [String : CompleteHandlerBlock]!
    class var sharedInstance: DownloadSessionDelegate {
        struct Static {
            static var instance : DownloadSessionDelegate?
            static var token = 0
        }
        
        // init () {
        
        Static.instance = DownloadSessionDelegate()
        Static.instance!.handlerQueue = [String :
            CompleteHandlerBlock]()
        //  }
        return Static.instance!
    }
    
    //MARK: session delegate
    func urlSession(_: URLSession, didBecomeInvalidWithError error: Error?) {
        debugPrint("session error: \(String(describing: error?.localizedDescription)).")
    }
    
    func URLSession(session: URLSession,
                    downloadTask:URLSessionDownloadTask,
                    didFinishDownloadingToURL location: URL) {
        debugPrint("session \(session) has finished the download task \(downloadTask) of URL \(location).")
    }
    
    func URLSession(session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        debugPrint("session \(session) download task \(downloadTask) wrote an additional \(bytesWritten) bytes (total (totalBytesWritten) bytes) out of an expected \(totalBytesExpectedToWrite) bytes")
    }
    func urlSessionDidFinishEvents(forBackgroundURLSession session:
        URLSession) {
        debugPrint("background session \(session) finished events.")
        
        if !(session.configuration.identifier?.isEmpty)! {
            callCompletionHandlerForSession(identifier: "Our Identifier")
        }
    }
    
    //MARK: completion handler
    func addCompletionHandler(handler: @escaping CompleteHandlerBlock,
                              identifier: String) {
        handlerQueue[identifier] = handler
    }
    
    func callCompletionHandlerForSession(identifier: String!) {
        let handler : CompleteHandlerBlock =
            handlerQueue[identifier]!
        handlerQueue!.removeValue(forKey: identifier)
        handler()
    }
}
