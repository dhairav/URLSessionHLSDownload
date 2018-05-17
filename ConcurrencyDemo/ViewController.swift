//
//  ViewController.swift
//  ConcurrencyDemo
//
//  Created by Dhairav Mehta on 25/01/2018.
//  Copyright © 2018 Dhairav Mehta. All rights reserved.
//
import UIKit
import Pantomime
import AVFoundation
import AVKit
import GCDWebServer

let builder = ManifestBuilder()
var masterUrl = URL(string: "http://drm01.sboxdc.com/sample_media/hls_enc/master.m3u8")
var manifest = builder.parse(masterUrl!)
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
var localDownloadUrl = documentsPath.appendingPathComponent("Sample", isDirectory: true)
let tempPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
var localTempUrl = tempPath.appendingPathComponent("Temp", isDirectory: true)
var completedDownloadsCount = 0
var totalSegmentCount: Int? = nil
var canPlayBack = false
var playlist: MediaPlaylist? = nil
var session: URLSession? = nil
var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
let sessionConfig = URLSessionConfiguration.background(withIdentifier: "InitialDownload")
var totalDownloadedBytes: Int64 = 0
var isDownloading = false

class ViewController: UIViewController, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var pauseButton: UIButton!
    var resumeDataArray: [Data]?
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        let segmentFilePath = localDownloadUrl.appendingPathComponent((downloadTask.response?.url?.lastPathComponent)!)
        
        print(downloadTask.response!)
        
        do {
            if FileManager.default.fileExists(atPath: segmentFilePath.absoluteString) {
                try FileManager.default.removeItem(at: segmentFilePath)
                try FileManager.default.moveItem(at: location, to: segmentFilePath)
                debugPrint("Replaced file: \(String(describing: downloadTask.response?.url?.lastPathComponent))")
            }
            else {
                try FileManager.default.moveItem(at: location, to: segmentFilePath)
                debugPrint("Moved file: \(String(describing: downloadTask.response?.url?.lastPathComponent))")
            }
            if (downloadTask.response?.url?.lastPathComponent == masterUrl?.lastPathComponent) {
                var selectedPlaylistUrl = masterUrl?.deletingLastPathComponent().absoluteURL
                
                selectedPlaylistUrl = selectedPlaylistUrl?.appendingPathComponent((manifest.getPlaylist(1)?.path)!)
                playlist = manifest.getPlaylist(1)
                let playlistRequest = URLRequest(url: selectedPlaylistUrl!)
                let playlistDownloadTask = session.downloadTask(with: playlistRequest)
                playlistDownloadTask.resume()
                startDownloadingSegments()
            }
            completedDownloadsCount += 1
        }catch{
            print(error.localizedDescription)
            if error.localizedDescription.contains("already exists") {
                
            }
        }
        if(completedDownloadsCount == totalSegmentCount) {
            canPlayBack = true
            print("Downloading crypt key now, all segments downloaded.")
            let cryptTask = session.downloadTask(with: (masterUrl?.deletingLastPathComponent().appendingPathComponent("crypt.key"))!)
            cryptTask.resume()
            isDownloading = false
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            
            totalDownloadedBytes += bytesWritten

            let progress = Float(totalDownloadedBytes) / Float(261503000)
            
//            debugPrint("Progress \(String(describing: downloadTask.response?.url?.lastPathComponent)) \(progress * 100)%")
            
            DispatchQueue.main.async {
                self.progressView.setProgress(Float(progress), animated: true)
                let progressToDisplay = (progress * 100).rounded()
                self.progressLabel.text = "progress: \(progressToDisplay)%"
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        debugPrint("Task completed: \(task), error: \(String(describing: error))")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didClickOnPause(_ sender: Any) {
        if isDownloading {
            session?.getAllTasks(completionHandler: { (tasks) in
                session?.getTasksWithCompletionHandler({ (sessiondataDaskArray, sessionUploadTaskArray, sessionDownloadTaskArray) in
                    for task in sessionDownloadTaskArray {
                        task.cancel(byProducingResumeData: { (resumeData) in
                            let tempPath = localTempUrl.appendingPathComponent((task.response?.url?.lastPathComponent)!)
                            self.writeResumedDataInLocalStorage(filePath: tempPath, resumeData: resumeData!)
                        })
                    }
                })
                isDownloading = false
                canPlayBack = false
                DispatchQueue.main.async {
                    self.pauseButton.setTitle("Resume", for: .normal)
                }
            })
        }else if canPlayBack {
            let alert = UIAlertController(title: "Alert", message: "Content Already downloaded", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else if !canPlayBack && (pauseButton.currentTitle?.contains("Resume"))! {
            session?.getTasksWithCompletionHandler({ (sessionDataTaskArray, sessionUploadTaskArray, sessionDownloadTaskArray) in
                
            })
            session?.getAllTasks(completionHandler: { (tasks) in
                for task in tasks {
                    task.resume()
                }
                isDownloading = true
                canPlayBack = false
                DispatchQueue.main.async {
                    self.pauseButton.setTitle("Pause", for: .normal)
                }
            })
        }
    }
    
    func startDownloadingSegments() {
        isDownloading = true
        
        totalSegmentCount = playlist?.getSegmentCount()
        
        for i in 0..<totalSegmentCount! {
            
            let tsName = playlist?.getSegment(i)?.path
            
            let components = masterUrl?.absoluteString.components(separatedBy: "/")
            let stringToRemove = components?[(components?.count)!-1]
            
            let downloadUrl = masterUrl?.absoluteString.replacingOccurrences(of: stringToRemove!, with:tsName!)
            print(downloadUrl!)
            let request = URLRequest(url: URL.init(string: downloadUrl!)!)
            let downloadTask = session?.downloadTask(with: request)
            downloadTask?.resume()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionConfig.allowsCellularAccess = true
        
        session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue())
        session?.downloadTask(with: masterUrl!).resume()

        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func didClickOnStart(sender: AnyObject) {
        
        sessionConfig.allowsCellularAccess = false
        sessionConfig.httpMaximumConnectionsPerHost = 5
        
        session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue())
        
        do {
            try FileManager.default.createDirectory(atPath: localDownloadUrl.path, withIntermediateDirectories: true, attributes: nil)
            let task = session?.downloadTask(with: masterUrl!)
            task?.resume()
        }catch {
            print(error.localizedDescription)
        }
        
    }
    
    //When user pauses download write the partially downloaded data into document directory in order to resume download after app restart
    func writeResumedDataInLocalStorage(filePath: URL, resumeData: Data)
    {
        let fileManager = FileManager.default
        
        //remove existing content if any from the filepath and write new one
        try? fileManager.removeItem(at: filePath)
        do {
            try resumeData.write(to: filePath)
        }
        catch let error {
            print("Could not copy file to disk: \(error.localizedDescription)")
        }
    }
    
    //get filepath url for downloading file into documents directory
    func getFilePath(for url: URL) -> URL{
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(url.lastPathComponent)
    }
    
    @IBAction func playContent(_ sender: Any) {
        
        if canPlayBack {
            
            let server = GCDWebServer()
            server.addGETHandler(forBasePath: "/", directoryPath: path, indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)
            server.start(withPort: 3000, bonjourName: nil)
            
            let playbackUrl = URL.init(string: "http://localhost:3000/Sample/master.m3u8")
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

