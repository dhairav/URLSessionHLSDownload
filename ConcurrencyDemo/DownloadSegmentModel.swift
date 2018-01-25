//
//  DownloadSegmentModel.swift
//  ConcurrencyDemo
//
//  Created by Dhairav Mehta on 23/01/18.
//  Copyright © 2018 Hossam Ghareeb. All rights reserved.
//

import Foundation

class DownloadSegmentModel {
    
    let name: String
    let index: Int
    var downloaded = false
    let size: Float
    let downloadUrl: URL
    
    init(name: String, size: Float, index: Int, downloadUrl: URL) {
        self.name = name
        self.index = index
        self.size = size
        self.downloadUrl = downloadUrl
    }
}
