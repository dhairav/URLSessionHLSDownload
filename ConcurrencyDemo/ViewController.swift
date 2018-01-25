//
//  ViewController.swift
//  ConcurrencyDemo
//
//  Created by Hossam Ghareeb on 11/15/15.
//  Copyright © 2015 Hossam Ghareeb. All rights reserved.
//
import UIKit
import Pantomime
import AVFoundation
import AVKit
import GCDWebServer

let builder = ManifestBuilder()
let masterUrl = URL(string: "http://184.72.239.149/vod/smil:BigBuckBunny.smil/playlist.m3u8")
let manifest = builder.parse(masterUrl!)
// Get local file path: download task stores tune here; AV player plays it.
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
var localDownloadUrl = documentsPath.appendingPathComponent("Sample", isDirectory: true)
var completedDownloadsCount = 0
var totalSegmentCount: Int? = nil
var canPlayBack = true
var session: URLSession? = nil

let sessionConfig = URLSessionConfiguration.background(withIdentifier: "InitialDownload")


class ViewController: UIViewController, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        let segmentFilePath = localDownloadUrl.appendingPathComponent((downloadTask.response?.url?.lastPathComponent)!)
        
        do {
            try FileManager.default.moveItem(at: location, to: segmentFilePath)
            debugPrint("Moved file: \(String(describing: downloadTask.response?.url?.lastPathComponent))")
            completedDownloadsCount += 1
        }catch{
            print(error.localizedDescription)
        }
        if(completedDownloadsCount == totalSegmentCount) {
            canPlayBack = true
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            debugPrint("Progress \(String(describing: downloadTask.response?.url?.lastPathComponent)) \(progress * 100)%")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        debugPrint("Task completed: \(task), error: \(String(describing: error))")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        sessionConfig.allowsCellularAccess = false
        sessionConfig.httpMaximumConnectionsPerHost = 5
        session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue())
        
        
        let server = GCDWebServer()
        server.addGETHandler(forBasePath: "/", directoryPath: documentsPath.absoluteString, indexFilename: "index.html", cacheAge: 3600, allowRangeRequests: true)
        server.start(withPort: 3000, bonjourName: nil)
        print(server.serverURL)
        print(documentsPath.absoluteString)
        
    }

    @IBAction func didClickOnStart(sender: AnyObject) {
        
        do {
            try FileManager.default.createDirectory(atPath: localDownloadUrl.path, withIntermediateDirectories: true, attributes: nil)
        }catch {
            print(error.localizedDescription)
        }
        let mediaPlaylistSample = manifest.getPlaylist(0)
        
        totalSegmentCount = mediaPlaylistSample?.getSegmentCount()

        for i in 0..<mediaPlaylistSample!.getSegmentCount() {

            let tsName = mediaPlaylistSample?.getSegment(i)?.path

            let components = masterUrl?.absoluteString.components(separatedBy: "/")
            let stringToRemove = components?[(components?.count)!-1]

            let downloadUrl = masterUrl?.absoluteString.replacingOccurrences(of: stringToRemove!, with:tsName!)
            print(downloadUrl!)
            let request = URLRequest(url: URL.init(string: downloadUrl!)!)
            let downloadTask = session?.downloadTask(with: request)
            downloadTask?.resume()

        }
    
        let request = URLRequest(url: masterUrl!)
        let downloadTask = session?.downloadTask(with: request)
        downloadTask?.resume()
        
        var playListUrl = masterUrl?.deletingLastPathComponent().absoluteURL
        
        playListUrl = playListUrl?.appendingPathComponent((mediaPlaylistSample?.path)!)
        
        let playlistRequest = URLRequest(url: playListUrl!)
        let playlistDownloadTask = session?.downloadTask(with: playlistRequest)
        playlistDownloadTask?.resume()
    }
    
    @IBAction func playContent(_ sender: Any) {
        
        if canPlayBack {

            let playbackUrl = URL.init(string: "http://localhost:3000/playlist.m3u8")
//            let playbackUrl = localDownloadUrl.appendingPathComponent("chunklist_w1792260766_b560000.m3u8")
            let player = AVPlayer.init(url: playbackUrl!)
            let playerController = AVPlayerViewController()
            playerController.player = player
            self.present(playerController, animated: true) {
                playerController.player!.play()
            }
        }
    }
    func localFilePath(for url: URL) -> URL {
        return documentsPath.appendingPathComponent(url.lastPathComponent)
    }
    
}

