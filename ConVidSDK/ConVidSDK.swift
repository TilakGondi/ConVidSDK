//
//  ConVidSDK.swift
//  ConVidSDK
//
//  Created by Tilakkumar Gondi on 12/01/22.
//

import Foundation


public class ConVidSDK:NSObject {
    private var configuration:ConVidConfiguration?
    private var sdkFileMgr:ConVidFileManager?
    
    public func initSDK(with config:ConVidConfiguration) {
        self.configuration = config
        self.sdkFileMgr = ConVidFileManager()
        self.sdkFileMgr?.config = config
        print("Initialized S3UploaderSDK with Configuration")
    }
    
    public func processFile(atURL fileUrl: URL, completion:@escaping (URL, String)->Void){
        print("ConVidSDK: Processing File...")
        print("ConVidSDK: Input File Path: \(fileUrl)")
        
        let fileAttributes = sdkFileMgr?.getAttributesForFile(atPath: fileUrl)
        
        
        if (fileAttributes!.size > (configuration?.FILE_SIZE_LIMIT.rawValue)!) && (configuration?.COMPRESSION  != .NO_COMPRESSION){
            sdkFileMgr?.compressFile(fileUrl, completion: { outputUrl,outFileSize  in
                print(outputUrl)
                completion(outputUrl,outFileSize)
            })
        }else{
            completion(fileUrl,"\(fileAttributes!.mb_size)")
        }
        
    }
    
    
}
