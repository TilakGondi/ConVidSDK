//
//  ConVidConfiguration.swift
//  ConVidSDK
//
//  Created by Tilakkumar Gondi on 12/01/22.
//

import Foundation
import AVFoundation

public enum MAX_FILESIZE:Int {
    case MAX_10MB = 10485760
    case MAX_20MB = 20971520
    case MAX_30MB = 31457280
    case MAX_40MB = 41943040
    case MAX_50MB = 52428800
    case MAX_60MB = 62914560
    case MAX_70MB = 73400320
    case MAX_80MB = 83886080
    case MAX_90MB = 94371840
    case MAX_100MB = 104857600
    case MAX_200MB = 209715200
    case MAX_300MB = 314572800
    case MAX_400MB = 419430400
    case MAX_500MB = 524288000
}

public enum COMPRESSION_MODE:String {
    case NO_COMPRESSION = "NO_COMPRESSION"          //Default from video track
    case VHD = "VHIGH"                              // 5120000
    case HD = "HIGH"                                // 2560000
    case SD = "MEDIUM"                              // 1228800
    case LD = "LOW"                                 // 716800
    case VLD = "VLOW"                               // 358400
    
}

public class ConVidConfiguration:NSObject {
    public var FILE_SIZE_LIMIT:MAX_FILESIZE = MAX_FILESIZE(rawValue: Int()) ?? .MAX_10MB
    public var OUTPUT_FORMAT:AVFileType = .mov
    public var COMPRESSION:COMPRESSION_MODE = COMPRESSION_MODE(rawValue: String()) ?? .NO_COMPRESSION
    
    public override init() {
        
    }
    
}
