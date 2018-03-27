//
//  PlexAPI.swift
//  STM
//
//  Created by KZ on 2018/03/26.
//  Copyright © 2018年 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import SWXMLHash

func getAttribute(xml: XMLIndexer, key: String, dflt: String) -> String {
    if let value = xml.element?.allAttributes[key] {
        return value.text
    }
    return dflt
}

func getPmsUrl(key: String, pmsId: String, pmsPath: String) -> String {
    if pmsPath.hasPrefix("http://") || pmsPath.hasPrefix("https://") {
        // full URL, keep as is...
        print("request full url: \(pmsPath)")
        return pmsPath
    }

    // prepare pms uri & token
    var token: String
    var url: String
    if let pmsInfo = plexMediaServerInformation[pmsId] {
        // PMS specific
        url = pmsInfo.getAttribute(key: "uri")
        token = pmsInfo.getAttribute(key: "accessToken")
    } else {
        // pmsId not pointing to real PMS - try plex.tv and user token
        url = "https://plex.tv"
        token = plexUserInformation.getAttribute(key: "token")
    }

    // path
    if key.hasPrefix("/") { // internal full path
        url = url + key
    } else if key == "" {  // keep current path
        url = url + pmsPath
    } else {  // relative path - current plex new path component
        url = url + pmsPath + "/" + key
    }

    // token
    if token != "" {
        var queryDelimiter = "?"
        if url.contains("?") {
            queryDelimiter = "&"
        }
        url = url + queryDelimiter + "X-Plex-Token=" + token
    }

    print("request: \(url)")
    return url
}

func getVideoPath(video: XMLIndexer, partIx: Int, pmsId: String, pmsPath: String?) -> String {
    var res: String

    // sanity check: pmsId
    var accessToken: String
    var pmsUri: String = ""
    var pmsLocal: Bool
    if let pmsInfo = plexMediaServerInformation[pmsId] {
        accessToken = pmsInfo.getAttribute(key: "accessToken")
        pmsUri = pmsInfo.getAttribute(key: "uri")
        pmsLocal = (pmsInfo.getAttribute(key: "publicAddressMatches") == "1")
    } else {
        guard let pmsPath = pmsPath else {
            return ""
        }

        if pmsPath.hasPrefix("http://") || pmsPath.hasPrefix("https://") {
            accessToken = ""
            // arbitrary host, defined in parent path, eg. queue/indirect
            // todo: use regex? use urlComponents?
            let range = pmsPath.index(pmsPath.startIndex, offsetBy: 8)..<pmsPath.endIndex
            // 8 - start searching behind "//"  // todo: optionals
            if let rangeHostPathDelimiter = pmsPath.range(of: "/", options: [], range: range, locale: nil) {
                pmsUri = String(pmsPath[..<rangeHostPathDelimiter.lowerBound])  // todo: optional
            }
            pmsLocal = false
        } else {
            // try plex.tv, user token
            accessToken = plexUserInformation.getAttribute(key: "token")
            pmsUri = "https://plex.tv"
            pmsLocal = false
        }
    }
    // todo: pmsPath as optional?

    // XML pointing to Video node
    let media = video["Media"][0]  // todo: cover XMLError, errorchecking on optionals
    let part = media["Part"][partIx]

    // transcoder action
    let transcoderAction = "DirectPlay"

    // video format
    //    HTTP live stream
    // or native aTV media
    var videoATVNative =
        ["hls"].contains(getAttribute(xml: media, key: "protocol", dflt: ""))
            ||
            ["mov", "mp4"].contains(getAttribute(xml: media, key: "container", dflt: "")) &&
            ["mpeg4", "h264", "drmi"].contains(getAttribute(xml: media, key: "videoCodec", dflt: "")) &&
            ["aac", "ac3", "drms"].contains(getAttribute(xml: media, key: "audioCodec", dflt: ""))

    /* limitation of aTV2/3 only?
     for stream in part["Stream"] {
     if (stream.element!.attributes["streamType"] == "1" &&
     ["mpeg4", "h264"].contains(stream.element!.attributes["codec"]!)) {
     if (stream.element!.attributes["profile"] == "high 10" ||
     Int(stream.element!.attributes["refFrames"]!) > 8) {
     videoATVNative = false
     break
     }
     }
     }
     */
    print("videoATVNative: " + String(videoATVNative))

    // quality limits: quality=(resolution, quality, bitrate)
    let qualityLookup = [
        "480p 2.0Mbps": ("720x480", "60", "2000"),
        "720p 3.0Mbps": ("1280x720", "75", "3000"),
        "720p 4.0Mbps": ("1280x720", "100", "4000"),
        "1080p 8.0Mbps": ("1920x1080", "60", "8000"),
        "1080p 12.0Mbps": ("1920x1080", "90", "12000"),
        "1080p 20.0Mbps": ("1920x1080", "100", "20000"),
        "1080p 40.0Mbps": ("1920x1080", "100", "40000")
    ]
    let transcoderQuality = "1080p 40.0Mbps"
    var quality: [String: String] = [:]
    if pmsLocal {
        quality["resolution"] = qualityLookup[transcoderQuality]?.0
        quality["quality"] = qualityLookup[transcoderQuality]?.1
        quality["bitrate"] = qualityLookup[transcoderQuality]?.2
    } else {
        quality["resolution"] = qualityLookup[transcoderQuality]?.0
        quality["quality"] = qualityLookup[transcoderQuality]?.1
        quality["bitrate"] = qualityLookup[transcoderQuality]?.2
    }
    let qualityDirectPlay = Int(getAttribute(xml: media, key: "bitrate", dflt: "0"))! < Int(quality["bitrate"]!)!
    print("quality: ", quality["resolution"], quality["quality"], quality["bitrate"], "qualityDirectPlay: ", qualityDirectPlay)

    // subtitle renderer, subtitle selection
    /* not used yet - todo: implement and test
     let subtitleRenderer = settings.getSetting("subtitleRenderer")

     var subtitleId = ""
     var subtitleKey = ""
     var subtitleFormat = ""
     for stream in part["Stream"] {  // todo: check 'Part' existance, deal with multi part video
     if stream.element!.attributes["streamType"] == "3" &&
     stream.element!.attributes["selected"] == "1" {
     subtitleId = stream.element!.attributes["id"]!
     subtitleKey = stream.element!.attributes["key"]!
     subtitleFormat = stream.element!.attributes["format"]!
     break
     }
     }

     let subtitleIOSNative = (subtitleKey == "") && (subtitleFormat == "tx3g")  // embedded
     let subtitleThisApp   = (subtitleKey != "") && (subtitleFormat == "srt")  // external

     // subtitle suitable for direct play?
     //    no subtitle
     // or 'Auto'    with subtitle by iOS or ThisApp
     // or 'iOS,PMS' with subtitle by iOS
     let subtitleDirectPlay =
     subtitleId == ""
     ||
     subtitleRenderer == "Auto" && ( (videoATVNative && subtitleIOSNative) || subtitleThisApp )
     ||
     subtitleRenderer == "iOS, PMS" && (videoATVNative && subtitleIOSNative)
     print("subtitle: IOSNative - {0}, PlexConnect - {1}, DirectPlay - {2}", subtitleIOSNative, subtitleThisApp, subtitleDirectPlay)
     */

    // determine video URL
    // direct play for...
    //    indirect or full url, eg. queue
    //
    //    force direct play
    // or videoATVNative (HTTP live stream m4v/h264/aac...)
    //    limited by quality setting
    //    with aTV supported subtitle (iOS embedded tx3g, PlexConnext external srt)
    let key = getAttribute(xml: part, key: "key", dflt: "")
    let indirect = getAttribute(xml: media, key: "indirect", dflt: "0")
    if indirect == "1" ||
        key.hasPrefix("http://") || key.hasPrefix("https://") {
        res = key
    } else if transcoderAction == "DirectPlay"
        ||
        transcoderAction == "Auto" && videoATVNative && qualityDirectPlay /*&& subtitleDirectPlay*/ {
        // direct play
        var xargs = getDeviceInfoXArgs()
        if accessToken != "" {
            xargs += [URLQueryItem(name: "X-Plex-Token", value: accessToken)]
        }

        let urlComponents = NSURLComponents(string: key)
        urlComponents!.queryItems = xargs

        res = urlComponents!.string!
    } else {
        // request transcoding
        let key = getAttribute(xml: video, key: "key", dflt: "")
        let ratingKey = getAttribute(xml: video, key: "ratingKey", dflt: "")

        // misc settings: subtitlesize, audioboost
        /*
         let subtitle = ["selected": "1" if subtitleId else "0",
         "dontBurnIn": "1" if subtitleDirectPlay else "0",
         "size": settings.getSetting("subtitlesize") ]
         */
        let audio = ["boost": "100" /*settings.getSetting("audioboost")*/ ]

        let args = getTranscodeVideoArgs(path: key, ratingKey: ratingKey, partIx: partIx, transcoderAction: transcoderAction, quality: quality, audio: audio
            // subtitle: subtitle
        )

        var xargs = getDeviceInfoXArgs()
        xargs.append(URLQueryItem(name: "X-Plex-Client-Capabilities", value: "protocols=http-live-streaming,http-mp4-streaming,http-streaming-video,http-streaming-video-720p,http-mp4-video,http-mp4-video-720p;videoDecoders=h264{profile:high&resolution:1080&level:41};audioDecoders=mp3,aac{bitrate:160000}"))
        if accessToken != "" {
            xargs.append(URLQueryItem(name: "X-Plex-Token", value: accessToken))
        }

        let urlComponents = NSURLComponents(string: "/video/:/transcode/universal/start.m3u8?")
        urlComponents!.queryItems = args + xargs

        res = urlComponents!.string!
    }

    if res.hasPrefix("/") {
        // internal full path
        res = pmsUri + res
    } else if res.hasPrefix("http://") || res.hasPrefix("https://") {
        // external address - do nothing
    } else {
        // internal path, add-on
        res = pmsUri + pmsPath! + "/" + res
    }

    return res
}

func getDirectVideoPath(key: String, pmsToken: String) -> String {
    var res: String

    if key.hasPrefix("http://") || key.hasPrefix("https://") {  // external address, eg. channels - keep
        res = key
    } else if pmsToken == "" {  // no token, nothing to add - keep
        res = key
    } else {
        var queryDelimiter = "?"
        if key.contains("?") {
            queryDelimiter = "&"
        }
        res = key + queryDelimiter + "X-Plex-Token=" + pmsToken  // todo: does token need urlencode?
    }

    return res
}

func getTranscodeVideoArgs(path: String, ratingKey: String, partIx: Int, transcoderAction: String, quality: [String: String], audio: [String: String]) -> [URLQueryItem] {
    var directStream: String
    if transcoderAction == "Transcode" {
        directStream = "0"  // force transcoding, no direct stream
    } else {
        directStream = "1"
    }
    // transcoderAction 'directPlay' - handled by the client in MEDIARUL()

    let args: [URLQueryItem] = [
        URLQueryItem(name: "path", value: path),
        URLQueryItem(name: "partIndex", value: String(partIx)),

        URLQueryItem(name: "session", value: ratingKey),  // todo: session UDID? ratingKey?

        URLQueryItem(name: "protocol", value: "hls"),
        URLQueryItem(name: "videoResolution", value: quality["resolution"]!),
        URLQueryItem(name: "videoQuality", value: quality["quality"]!),
        URLQueryItem(name: "maxVideoBitrate", value: quality["bitrate"]!),
        URLQueryItem(name: "directStream", value: directStream),
        URLQueryItem(name: "audioBoost", value: audio["boost"]!),
        URLQueryItem(name: "fastSeek", value: "1"),

        URLQueryItem(name: "skipSubtitles", value: "1"),  // no PMS subtitles for now

        /* todo: subtitle support
         args["subtitleSize"] = subtitle["size"]
         args["skipSubtitles"] = subtitle["dontBurnIn"]  // '1'  // shut off PMS subtitles. Todo: skip only for aTV native/SRT (or other supported)
         */

    ]
    return args
}

func getAudioPath(audio: XMLIndexer, pmsId: String, pmsPath: String?) -> String {
    var res: String

    // sanity check
    // todo: ?

    // XML pointing to Track node
    let media = audio["Media"][0]  // todo: cover XMLError, errorchecking on optionals
    let part = media["Part"][0]

    // todo: transcoder action setting?

    let audioATVNative =
        // todo: check Media.get('container') as well - mp3, m4a, ...?
        ["mp3", "aac", "ac3", "drms", "alac", "aiff", "wav"].contains(getAttribute(xml: media, key: "audioCodec", dflt: ""))
    print("audioATVNative: " + String(audioATVNative))

    // transcoder bitrate setting [kbps] -  eg. 128, 256, 384, 512?
    var quality: [String: String] = [:]
    quality["bitrate"] = "384"  // maxAudioBitrate  // todo: setting?
    let qualityDirectPlay = true
    print("quality: ", quality["bitrate"], "qualityDirectPlay: ", qualityDirectPlay)

    // determine adio URL
    // direct play for...
    //    audioATVNative
    //    limited by quality setting
    let accessToken = plexMediaServerInformation[pmsId]!.getAttribute(key: "accessToken")
    if audioATVNative && qualityDirectPlay {
        // direct play
        let key = getAttribute(xml: part, key: "key", dflt: "")

        var xargs = getDeviceInfoXArgs()
        if accessToken != "" {
            xargs.append(URLQueryItem(name: "X-Plex-Token", value: accessToken))
        }

        let urlComponents = NSURLComponents(string: key)
        urlComponents!.queryItems = xargs

        res = urlComponents!.string!
    } else {
        // request transcoding
        let key = getAttribute(xml: audio, key: "key", dflt: "")
        let ratingKey = getAttribute(xml: audio, key: "ratingKey", dflt: "")

        let args = getTranscodeAudioArgs(path: key, ratingKey: ratingKey, quality: quality)

        var xargs = getDeviceInfoXArgs()
        if accessToken != "" {
            xargs.append(URLQueryItem(name: "X-Plex-Token", value: accessToken))
        }

        let urlComponents = NSURLComponents(string: "/music/:/transcode/universal/start.mp3?")
        urlComponents!.queryItems = args + xargs

        res = urlComponents!.string!
    }

    if res.hasPrefix("/") {
        // internal full path
        res = plexMediaServerInformation[pmsId]!.getAttribute(key: "uri") + res
    } else if res.hasPrefix("http://") || res.hasPrefix("https://") {
        // external address - do nothing
    } else {
        // internal path, add-on
        res = plexMediaServerInformation[pmsId]!.getAttribute(key: "uri") + pmsPath! + "/" + res
    }

    return res
}

func getTranscodeAudioArgs(path: String, ratingKey: String, quality: [String: String]) -> [URLQueryItem] {
    let args: [URLQueryItem] = [
        URLQueryItem(name: "path", value: path),
        URLQueryItem(name: "session", value: ratingKey),  // todo: session UDID? ratingKey?
        URLQueryItem(name: "protocol", value: "http"),
        URLQueryItem(name: "maxAudioBitrate", value: quality["bitrate"]!)
    ]
    return args
}

func getPhotoPath(photo: XMLIndexer, width: String, height: String, pmsId: String, pmsPath: String?) -> String {
    var res: String

    // sanity check
    // todo: ?

    // XML pointing to Video node
    let media = photo["Media"][0]  // todo: cover XMLError, errorchecking on optionals
    let part = media["Part"][0]

    // todo: transcoder action setting
    //let transcoderAction = settings.getSetting("transcoderAction")

    // photo format
    let photoATVNative = ["jpg", "jpeg", "tif", "tiff", "gif", "png"].contains(getAttribute(xml: media, key: "container", dflt: ""))
    print("photoATVNative: " + String(photoATVNative))

    let accessToken = plexMediaServerInformation[pmsId]!.getAttribute(key: "accessToken")
    if photoATVNative && width == "" && height == "" {
        // direct play
        let key = getAttribute(xml: part, key: "key", dflt: "")

        var xargs = getDeviceInfoXArgs()
        if accessToken != "" {
            xargs.append(URLQueryItem(name: "X-Plex-Token", value: accessToken))
        }

        let urlComponents = NSURLComponents(string: key)
        urlComponents!.queryItems = xargs

        res = urlComponents!.string!
    } else {
        // request transcoding
        let key = getAttribute(xml: part, key: "key", dflt: "")  // compare video/audio. Photo transcoder takes one file, not XML Photo structure

        var _width = width
        var _height = height
        if _height == "" {
            _height = width
        }
        if _width == "" {
            _width = "1920"
            _height = "1080"
        }

        var photoPath: String
        if key.hasPrefix("/") {
            // internal full path
            photoPath = "http://127.0.0.1:32400" + key
        } else if key.hasPrefix("http://") || key.hasPrefix("https://") {
            // external address - do nothing - can we get a transcoding request for external images?
            photoPath = key
        } else {
            // internal path, add-on
            photoPath = "http://127.0.0.1:32400" + pmsPath! + "/" + key
        }

        let args: [URLQueryItem] = [
            URLQueryItem(name: "url", value: photoPath),
            URLQueryItem(name: "width", value: _width),
            URLQueryItem(name: "height", value: _height)
        ]

        var xargs: [URLQueryItem] = []
        if accessToken != "" {
            xargs.append(URLQueryItem(name: "X-Plex-Token", value: accessToken))
        }

        let urlComponents = NSURLComponents(string: "/photo/:/transcode")
        urlComponents!.queryItems = args + xargs

        res = urlComponents!.string!
    }

    if res.hasPrefix("/") {
        // internal full path
        res = plexMediaServerInformation[pmsId]!.getAttribute(key: "uri") + res
    } else if res.hasPrefix("http://") || res.hasPrefix("https://") {
        // external address - do nothing
    } else {
        // internal path, add-on
        res = plexMediaServerInformation[pmsId]!.getAttribute(key: "uri") + pmsPath! + res
    }

    return res
}

func getDeviceInfoXArgs() -> [URLQueryItem] {
    let device = UIDevice()

    let xargs: [URLQueryItem] = [
        URLQueryItem(name: "X-Plex-Device", value: device.model),
        URLQueryItem(name: "X-Plex-Model", value: "4,1"),  // todo: hardware version
        URLQueryItem(name: "X-Plex-Device-Name", value: device.name),  // todo: "friendly" name: aTV-Settings->General->Name
        URLQueryItem(name: "X-Plex-Platform", value: "iOS" /*device.systemName*/),  // todo: have PMS to accept tvOS
        URLQueryItem(name: "X-Plex-Client-Platform", value: "iOS" /*device.systemName*/),
        URLQueryItem(name: "X-Plex-Platform-Version", value: device.systemVersion),

        URLQueryItem(name: "X-Plex-Client-Identifier", value: device.identifierForVendor?.uuidString),

        URLQueryItem(name: "X-Plex-Product", value: "PlexConnectApp"),  // todo: actual App name
        URLQueryItem(name: "X-Plex-Version", value: "0.1")  // todo: version
    ]
    return xargs
}

func reqXML(url: String, fn_success: @escaping (Data) -> (), fn_error: @escaping (Error) -> ()) {
    // request URL asynchronously
    let _nsurl = URL(string: url)
    //let config = NSURLSessionConfiguration.defaultSessionConfiguration()
    //let session = NSURLSession(configuration: config)  // previously: convert() loop was done within fn_success closure, leading to thread hang up...
    let session = URLSession.shared
    let task = session.dataTask(with: _nsurl!, completionHandler: { (data, response, error) -> Void in
        // get response
        if let httpResp = response as? HTTPURLResponse, let data = data {
            // todo: check statusCode: 200 ok, 404 not not found...
            //let data_str = NSString(data: data!, encoding: NSUTF8StringEncoding)
            //print("NSData \(data_str)")
            //print("NSURLResponse \(response)")
            //print("NSError \(error)")
            fn_success(data)
        } else if let error = error {
            fn_error(error)
        }
    })
    task.resume()
}

func getXMLWait(urlString: String) -> XMLIndexer? {
    // request URL, wait for response, parse XML
    var XML: XMLIndexer?

    let dsptch = DispatchSemaphore(value: 0)
    DispatchQueue.global(qos: .default).async {
        guard let url = URL(string: urlString) else {
            return
        }

        //let session = NSURLSession.sharedSession()
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            if let _ = response as? HTTPURLResponse {
                XML = SWXMLHash.parse(data!)
            } else {
                // error: what to do?
            }
            dsptch.signal()
        })
        task.resume()
    }
    _ = dsptch.wait(timeout: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + httpTimeout.uptimeNanoseconds))
    return XML
}

// myPlexSignIn
func myPlexSignIn(username: String, password: String) {
    var XML: XMLIndexer?

    let config = URLSessionConfiguration.default
    let userPasswordData = (username + ":" + password).data(using: String.Encoding.utf8)
    let base64EncodedCredential = userPasswordData!.base64EncodedString()
    let authString = "Basic \(base64EncodedCredential)"
    config.httpAdditionalHeaders = ["Authorization" : authString]
    let session = URLSession(configuration: config)

    let url = URL(string: "https://plex.tv/users/sign_in.xml")
    var request = URLRequest(url: url!)
    request.httpMethod = "POST"

    let xargs = getDeviceInfoXArgs()
    for xarg in xargs {
        request.addValue(xarg.value!, forHTTPHeaderField: xarg.name)
    }

    print("signing in")
    let dsptch = DispatchSemaphore(value: 0)
    DispatchQueue.global(qos: .default).async {
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            if let httpResp = response as? HTTPURLResponse, let data = data {
                XML = SWXMLHash.parse(data)
            } else {
                // error: what to do?
            }
            dsptch.signal()
        })
        task.resume()
    }
    _ = dsptch.wait(timeout: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + httpTimeout.uptimeNanoseconds))
    print("sign in done")

    // todo: errormanagement. better check of XML, ...
    if let XML = XML {
        plexUserInformation = PlexUserInformation(xmlUser: XML["user"])
    } else {
        plexUserInformation.clear()
    }

    // re-discover Plex Media Servers
    discoverServers()
}

// myPlexSignOut
func myPlexSignOut() {
    // notify plex.tv
    let url = URL(string: "https://plex.tv/users/sign_out.xml")  // + "?X-Plex-Token=" + user._token)
    var request = URLRequest(url: url!)
    request.httpMethod = "POST"
    request.addValue(plexUserInformation.getAttribute(key: "token"), forHTTPHeaderField: "X-Plex-Token")
    let session = URLSession.shared

    let dsptch = DispatchSemaphore(value: 0)
    DispatchQueue.global(qos: .default).async {
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            dsptch.signal()
        })
        task.resume()
    }
    dsptch.wait(timeout: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + httpTimeout.uptimeNanoseconds))
    print("sign out done")

    // clear user data
    plexUserInformation.clear()

    // clear Plex Media Server list
    plexMediaServerInformation = [:]
}

// PlexHome managed users
func myPlexSwitchHomeUser(id: String, pin: String) {
    var XML: XMLIndexer?

    var url = "https://plex.tv/api/home/users/" + id + "/switch"
    if pin.count != 0 {
        url += "?pin=" + pin
    }

    var request = URLRequest(url: URL(string: url)!)  // todo: optional
    request.httpMethod = "POST"
    request.addValue(plexUserInformation.getAttribute(key: "token"), forHTTPHeaderField: "X-Plex-Token")
    let session = URLSession.shared

    let xargs = getDeviceInfoXArgs()
    for xarg in xargs {
        request.addValue(xarg.value!, forHTTPHeaderField: xarg.name)
    }

    print("switch HomeUser")
    let dsptch = DispatchSemaphore(value: 0)
    DispatchQueue.global(qos: .default).async {
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            if let httpResp = response as? HTTPURLResponse, let data = data {
                XML = SWXMLHash.parse(data)
            } else {
                // error: what to do?
            }
            dsptch.signal()
        }
        task.resume()
    }
    _ = dsptch.wait(timeout: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + httpTimeout.uptimeNanoseconds))
    print("switch HomeUser done")

    // todo: errormanagement. better check of XML, ...
    if let XML = XML {
        plexUserInformation.switchHomeUser(xmlUser: XML["user"])
    } else {
        //plexUserInformation.clear()  // todo: switch user failed, what to do? stick with previous selection?
    }

    // re-discover Plex Media Servers
    discoverServers()
}

func discoverServers() {
    // check for servers
    let url = "https://plex.tv/api/resources?includeHttps=1" +
        "&X-Plex-Token=" + plexUserInformation.getAttribute(key: "token")
    guard let xml = getXMLWait(urlString: url) else {
        return
    }

    plexMediaServerInformation = [:]
    var pms: PlexMediaServerInformation
    for (ix, server) in xml["MediaContainer"]["Device"].all.enumerated() {
        guard let element = server.element else {
            continue
        }

        if element.allAttributes["product"]?.text == "Plex Media Server" {
            pms = PlexMediaServerInformation(xmlPms: server)
            plexMediaServerInformation[String(ix)] = pms
        }
    }
}

func searchForMedia(search: String, server: String) -> [XMLIndexer] {
    guard let encodedString = search.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) else {
        return []
    }

    let urlString = getPmsUrl(key: "?type=10&X-Plex-Container-Size=100&query=" + encodedString, pmsId: server, pmsPath: "/search")
    guard let xml = getXMLWait(urlString: urlString) else {
        return []
    }

    return xml["MediaContainer"]["Track"].all

    // let audioPath = getAudioPath(audio: first, pmsId: "0", pmsPath: nil)
    // print(audioPath)
}
