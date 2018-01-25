//
//  DownloadService.swift
//  ConcurrencyDemo
//
//  Created by Dhairav Mehta on 23/01/18.
//  Copyright © 2018 Hossam Ghareeb. All rights reserved.
//

import Foundation

// Downloads song snippets, and stores in local file.
// Allows cancel, pause, resume download.
class DownloadService {
   // var task: URLSessionDownloadTask?
    // SearchViewController creates downloadsSession
    var downloadsSession: URLSession!
    var activeDownloads: [URL: Download] = [:]
    
    // MARK: - Download methods called by TrackCell delegate methods
    
    func startDownload(_ track: DownloadSegmentModel) {
        print(track)
        // 1
        let download = Download(segment: track)
        // 3
        download.task!.resume()
        // 4
        download.isDownloading = true
    }
    
    func pauseDownload(_ track: DownloadSegmentModel) {
        guard let download = activeDownloads[track.downloadUrl] else { return }
        if download.isDownloading {
            download.task?.cancel(byProducingResumeData: { data in
                download.resumeData = data
            })
            download.isDownloading = false
        }
    }
    
    func cancelDownload(_ track: DownloadSegmentModel) {
        if let download = activeDownloads[track.downloadUrl] {
            download.task?.cancel()
            activeDownloads[track.downloadUrl] = nil
        }
    }
    
    func resumeDownload(_ track: DownloadSegmentModel) {
        guard let download = activeDownloads[track.downloadUrl] else { return }
        if let resumeData = download.resumeData {
            download.task = downloadsSession.downloadTask(withResumeData: resumeData)
        } else {
            download.task = downloadsSession.downloadTask(with: download.segment.downloadUrl)
        }
        download.task!.resume()
        download.isDownloading = true
    }
    
}

class Download {
    
    var segment: DownloadSegmentModel
    init(segment: DownloadSegmentModel) {
        self.segment = segment
    }
    
    // Download service sets these values:
    var isDownloading = false
    var resumeData: Data?
    
    // Download delegate sets this value:
    var progress: Float = 0
    
}
