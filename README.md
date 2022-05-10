# ConVidSDK
**About:**

This SDK will convert the video at given URL into .mp4/.mov/.m4v format and compress it with
predefined compression bit rate of VLD/LD/SD/HD/VHD/nill.

**SDK Configuration:**

Declare the sdk_config var of type **ConVidConfiguration** to pass the required Configuration values
to SDK
```Swift 
var sdk_config:ConVidConfiguration = ConVidConfiguration()
```

**CONFIGURATION PARAMETERS:**
```Swift 
sdk_config.FILE_SIZE_LIMIT = .MAX_30MB 
```
The **FILE_SIZE_LIMIT** configuration property is meant for specifying the threshold value
for the input video file size. i.e. if th input video file size is greater than the set value then the
video will be compressed and converted by the SDK. Else the compression or conversion is not
done. This will accept the Enum values defined in the SDK *enum FILE_SIZE_LIMIT*.

Allowed Values : **MAX_10MB ,MAX_20MB ,MAX_30MB ,MAX_40MB ,MAX_50MB ,MAX_60MB ,MAX_70MB ,MAX_80MB ,MAX_90MB ,MAX_100MB ,MAX_200MB ,MAX_300MB ,MAX_400MB ,MAX_500MB**

```Swift
sdk_config.OUTPUT_FORMAT = .mp4
```
The **OUTPUT_FORMAT** configuration property is meant for specifying the output video
format to which the SDK must convert the video. This property will take the values of type
AVFileType, i.e.

Allowed values : **.mp4, .m4v, .mov**

```Swift
sdk_config.COMPRESSION = .HD
```
The **COMPRESSION** configuration property is meant for specifying the compression quality in
terms of definition, i.e. for compressing the video to quality of High Definition Video set “.HD”
This will accept the Enum values defined in the SDK, *enum COMPRESSION_MODE*.

Allowed Values : **NO_COMPRESSION, VHD ,HD ,SD ,LD ,VLD**

## Steps for Integration of ConVidSDK
- Copy the **ConVidSDK.framework** to the project folder
- In Xcode project settings **General>Frameworks & Libraries** Add the SDK as framework with
“**Embed & Sign**” option
- Go to your swift class file and add below code:
    ```Swift
        import ConVidSDK
    ```
- Declare the below variables
    ```Swift
        var sdk_config:ConVidConfiguration = ConVidConfiguration()
        var sdk_conVid:ConVidSDK!
    ```
- Set the configuration values
    ```Swift
        sdk_config.FILE_SIZE_LIMIT = .MAX_30MB
        sdk_config.OUTPUT_FORMAT = .mp4
        sdk_config.COMPRESSION = .HD
    ```
- Initialise the SDK with configuration
    ```Swift 
        sdk_conVid = ConVidSDK()
        sdk_conVid.initSDK(with: sdk_config)
    ```
## Using ConVidSDK to compress and convert video in to required format 
- Input Parameters:
    - localURL -> This must be the url to the video file that must be converted and compressed by the SDK.
- Output Parameters:
    - SDK will return the output in the closure block with two parameters **convertedUrl** and **outFileSize**
    - The SDK will return **convertedUrl** which is the URL of the converted file placed in the tmp folder by the SDK and **outFileSize** will be the size of the converted file in MB.

```Swift
    self?.sdk_conVid!.processFile(atURL: localURL, completion: { convertedUrl,outFileSize in
        DispatchQueue.main.async {
            print(“Converted File URL: \(convertedUrl)”)
            print(“Converted File Size: \(outFileSize)”)
        }
    })
```

###### *For improvements and suggestions reach out to me at: tilak.gondi@gmil.com*
