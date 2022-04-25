//
//  ConVidFileManager.swift
//  ConVidSDK
//
//  Created by Tilakkumar Gondi on 12/01/22.
//

import Foundation
import AVFoundation

struct File_Attributes {
    var fileName:String = ""
    var size:Int = 0
    var mb_size:String = "0MB"
    var fileFormat:String = ""
    var path:String = ""
    var fileUrl:URL?
}

class ConVidFileManager:NSObject {
    let fileManager = FileManager.default
    private var filePathStr:String?
    var config:ConVidConfiguration?
    
    private var assetWriter: AVAssetWriter!
    private var assetWriterVideoInput: AVAssetWriterInput!
    private var audioMicInput: AVAssetWriterInput!
    private var videoURL: URL!
    private var audioAppInput: AVAssetWriterInput!
    private var channelLayout = AudioChannelLayout()
    private var assetReader: AVAssetReader?
    private var bitrate: NSNumber = NSNumber(value: 1250000) // *** you can change this number to increase/decrease the quality. The more you increase, the better the video quality but the the compressed file size will also increase
    private var assetReaderAudioOutput: AVAssetReaderTrackOutput?
    private var assetReaderVideoOutput: AVAssetReaderTrackOutput?
        // compression function, it returns a .mp4 but you can change it to .mov inside the do try block towards the middle. Change assetWriter = try AVAssetWriter ... AVFileType.mp4 to AVFileType.mov
    
    private var audioFinished = false
    private var videoFinished = false
    
    func getAttributesForFile(atPath url:URL) -> File_Attributes?{
        var attributesDict = File_Attributes()
        self.filePathStr = url.path
        attributesDict.path = url.path
        attributesDict.fileUrl = url
        if fileManager.fileExists(atPath: url.path) {
            attributesDict.fileName = url.lastPathComponent
            guard let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
                return  nil
            }
            attributesDict.fileFormat = self.getFileFormatWith(uttype: contentType)
            
            guard let fileSize = try? url.resourceValues(forKeys: [.totalFileSizeKey]).totalFileSize else {
                return nil
            }
            attributesDict.size = fileSize
            
            let fileSizeWithUnit = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
            print("File Size: \(fileSizeWithUnit)")
            attributesDict.mb_size = fileSizeWithUnit
            
            return attributesDict
        }else{
            print("File do not exists")
            return nil
        }
    }
    
    
    
        ///https://stackoverflow.com/questions/11751883/how-can-i-reduce-the-file-size-of-a-video-created-with-uiimagepickercontroller/11819382#11819382
        // add these properties
    
    func compressFile(_ urlToCompress: URL, completion:@escaping (URL, String)->Void) {
        
        
        audioFinished = false
        videoFinished = false
        let asset = AVAsset(url: urlToCompress)
        
            //create asset reader
        do {
            assetReader = try AVAssetReader(asset: asset)
        } catch {
            assetReader = nil
        }
        
        do {
            
            let outputURL = self.getOutputFileURL()
            self.deleteFile(filePath: outputURL)
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: config!.OUTPUT_FORMAT)
            
        } catch {
            assetWriter = nil
        }
        
        guard let writer = assetWriter else {
            print("assetWriter was nil")
                // show user error message/alert
            return
        }
        
            //Prepare the video file for conversion
        let inputObjects = self.prepareToConvert(theAsset: asset)
        guard let audioInput = inputObjects.0 else{
            print("Error in Conversion: Failed to prepare Audio Input for the asset")
            return
        }
        
        guard let videoInput = inputObjects.1 else {
            print("Error in Conversion: Failed to prepare Video Input for the asset")
            return
        }
        
        guard let reader = inputObjects.2 else {
            print("Could not iniitalize asset reader probably failed its try catch")
            return
        }
        
        writer.shouldOptimizeForNetworkUse = true
        writer.add(videoInput)
        writer.add(audioInput)
        
        writer.startWriting()
        reader.startReading()
        writer.startSession(atSourceTime: CMTime.zero)
        
        let videoInputQueue = DispatchQueue(label: "videoQueue")
        let audioInputQueue = DispatchQueue(label: "audioQueue")
        
        let closeWriter:()->Void = {
            if (self.audioFinished && self.videoFinished) {
                self.assetWriter?.finishWriting(completionHandler: { [weak self] in
                    
                    if let assetWriter = self?.assetWriter {
                        do {
                            let data = try Data(contentsOf: assetWriter.outputURL)
                            print("compressFile -file size after compression: \(Double(data.count / 1048576)) mb")
                        } catch let err as NSError {
                            print("compressFile Error: \(err.localizedDescription)")
                        }
                    }
                    
                    if let safeSelf = self, let assetWriter = safeSelf.assetWriter {
                        do {
                            let data = try Data(contentsOf: assetWriter.outputURL)
                            completion(assetWriter.outputURL,"\(Double(data.count / 1048576)) MB")
                        } catch let err as NSError {
                            print("compressFile Error: \(err.localizedDescription)")
                        }
                    }
                })
                
                self.assetReader?.cancelReading()
            }
        }
        
        
        self.processAudioTrack(with: audioInput, on: audioInputQueue, with: closeWriter)
        
        self.processVideoTrack(with: videoInput, on: videoInputQueue, with: closeWriter)
        
        
    }
}

extension ConVidFileManager {
    
    func prepareToConvert(theAsset asset:AVAsset) -> (AVAssetWriterInput?,AVAssetWriterInput?,AVAssetReader?){
        
        guard let reader = assetReader else {
            print("Could not iniitalize asset reader probably failed its try catch")
                // show user error message/alert
            return (nil,nil,nil)
        }
        
        guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else { return (nil,nil,nil)}
        self.bitrate = (self.config?.COMPRESSION == .NO_COMPRESSION) ? self.getEstimatedBitRateFor(assetTrack: videoTrack) : self.getBitRateFromConfig()
        
        let videoReaderSettings: [String:Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB]
        
        assetReaderVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
        
        if reader.canAdd(assetReaderVideoOutput!) {
            reader.add(assetReaderVideoOutput!)
        } else {
            print("Couldn't add video output reader")
                // show user error message/alert
            return (nil,nil,nil)
        }
        
        if let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first {
            
            let audioReaderSettings: [String : Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2
            ]
            
            assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioReaderSettings)
            
            if reader.canAdd(assetReaderAudioOutput!) {
                reader.add(assetReaderAudioOutput!)
            } else {
                print("Couldn't add audio output reader")
                    // show user error message/alert
                return (nil,nil,nil)
            }
        }
        
        let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: self.getAudioSettings())
        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: self.getVideoSettings(forTrack: videoTrack))
        videoInput.transform = videoTrack.preferredTransform
        
        return (audioInput,videoInput,reader)
    }
    
    
    func processVideoTrack(with videoInput:AVAssetWriterInput,on  videoInputQueue:DispatchQueue,with  closeWriter:@escaping ()->Void) {
        videoInput.requestMediaDataWhenReady(on: videoInputQueue) {
                // request data here
            while(videoInput.isReadyForMoreMediaData) {
                if let cmSampleBuffer = self.assetReaderVideoOutput?.copyNextSampleBuffer() {
                    videoInput.append(cmSampleBuffer)
                } else {
                    videoInput.markAsFinished()
                    DispatchQueue.main.async {
                        self.videoFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }
    }
    
    func processAudioTrack(with audioInput:AVAssetWriterInput,on  audioInputQueue:DispatchQueue,with  closeWriter:@escaping ()->Void) {
        audioInput.requestMediaDataWhenReady(on: audioInputQueue) {
            while(audioInput.isReadyForMoreMediaData) {
                if let cmSampleBuffer = self.assetReaderAudioOutput?.copyNextSampleBuffer() {
                    audioInput.append(cmSampleBuffer)
                } else {
                    audioInput.markAsFinished()
                    DispatchQueue.main.async {
                        self.audioFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }
    }
    
        //Get Video track settings
    func getVideoSettings(forTrack videoTrack:AVAssetTrack) -> [String:Any] {
        return [
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: self.getBitRateFromConfig()],
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoHeightKey: videoTrack.naturalSize.height,
            AVVideoWidthKey: videoTrack.naturalSize.width,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill
        ]
    }
    
    
    func getAudioSettings() -> [String:Any]{
        return [AVFormatIDKey : kAudioFormatMPEG4AAC,
        AVNumberOfChannelsKey : 2,
              AVSampleRateKey : 44100.0,
           AVEncoderBitRateKey: 128000
        ]
    }
}


extension ConVidFileManager {
    func getEstimatedBitRateFor(assetTrack track:AVAssetTrack) -> NSNumber {
        return NSNumber(value: track.estimatedDataRate);
    }
    
    func getBitRateFromConfig() -> NSNumber{
        switch config!.COMPRESSION {
            case .NO_COMPRESSION:
                return self.bitrate
            case .VHD:
                return NSNumber(value: 5120000)
            case .HD:
                return NSNumber(value: 2560000)
            case .SD:
                return NSNumber(value: 1228800)
            case .LD:
                return NSNumber(value: 716800)
            case .VLD:
                return NSNumber(value: 358400)
        }
    }
    
    func getOutputFileURL() -> URL {
        var fileName = "SDK_ConvertedFile"
        switch config!.OUTPUT_FORMAT {
            case .mp4:
                fileName = "\(fileName).mp4"
            case .m4v:
                fileName = "\(fileName).m4v"
            case .mov:
                fileName = "\(fileName).mov"
            default:
                fileName = "\(fileName).mp4"
        }
        let tempDir = NSTemporaryDirectory()
        let outputPath = "\(tempDir)\(fileName)"
        let outputURL = URL(fileURLWithPath: outputPath)
        return outputURL
    }
    
    private func getFileFormatWith(uttype type:UTType) -> String{
        switch type{
            case .quickTimeMovie:
                return ".mov"
            case .movie:
                return ".mov"
            case .mpeg4Movie:
                return ".mp4"
            case .mpeg:
                return ".mpeg"
            case .mpeg2Video:
                return ".mpeg2"
            case .mpeg4Movie:
                return ".mpeg4"
            case .appleProtectedMPEG4Video:
                return ".m4v"
            case .avi:
                return ".avi"
            case .wav:
                return ".wav"
            default:
                return ""
        }
    }
    
    func deleteFile(filePath:URL) {
        guard fileManager.fileExists(atPath: filePath.path) else {
            return
        }
        do {
            try fileManager.removeItem(atPath: filePath.path)
        }catch{
            fatalError("Unable to delete file: \(error).")
        }
    }
}
