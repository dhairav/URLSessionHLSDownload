//
//  DownloadTaskModel.swift
//  ConcurrencyDemo
//
//  Created by Dhairav Mehta on 17/05/18.
//  Copyright © 2018 Hossam Ghareeb. All rights reserved.
//

import Foundation

class DownLoadTaskInfoModel: NSObject {
    
    var masterDownloadUrl: URL!
    var title: String = ""
    var taskIndex: Int = 0
    var downloaded:Bool = false
    var paused:Bool = false
    var progress:Float = 0
    var totalSize:String = ""
}
