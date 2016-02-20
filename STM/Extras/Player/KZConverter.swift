//
//  KZConverter.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox
// swiftlint:disable trailing_whitespace
// swiftlint:disable line_length
/*
class KZConverter {
    var render_converter = AudioConverterRef()
    var currentSampleRate = Double(0.0)
    var currentAudioBufferList = AudioBufferList()
    var descAACFormat = AudioStreamBasicDescription()
    var sourceFormat = AudioStreamBasicDescription()
    let kBLOCK_SIZE = UInt32(4096)
    
    init(sourceFormat: AudioStreamBasicDescription) {
        self.sourceFormat = sourceFormat
        descAACFormat = M4AFormatWith(1, sampleRate: 44100)
    }
    
    func pipeData(audioBufferList: AudioBufferList) {
        if currentSampleRate != AVAudioSession.sharedInstance().sampleRate {
            currentSampleRate = AVAudioSession.sharedInstance().sampleRate
            if var description = getAudioClassDescriptionWith(kAudioFormatMPEG4AAC, manufacturer: kAppleSoftwareAudioCodecManufacturer) {
                let st = AudioConverterNewSpecific(&sourceFormat, &descAACFormat, 2, &description, &render_converter)
                if st != 0 {
                    print("error creating audio converter: %d", st)
                }
            }
        }
        
        let data = NSMutableData()
        let times = Int(ceilf(Float(audioBufferList.mBuffers.mDataByteSize) / Float(kBLOCK_SIZE)))
        
        for (var i = 0; i < times; i++) {
            let pcmBufferList = AllocateABL(2, bytesPerFrame: kBLOCK_SIZE, interleaved: true, capacityFrames: 1)
            var aacBufferList = AllocateABL(1, bytesPerFrame: kBLOCK_SIZE, interleaved: true, capacityFrames: 1)
            var resultDesc = AudioStreamPacketDescription()
            
            if (i*Int(kBLOCK_SIZE) + Int(kBLOCK_SIZE)) > Int(audioBufferList.mBuffers.mDataByteSize) {
                memcpy(pcmBufferList.mBuffers.mData, audioBufferList.mBuffers.mData.advancedBy(i*Int(kBLOCK_SIZE)), Int(audioBufferList.mBuffers.mDataByteSize) - (i*Int(kBLOCK_SIZE)))
            } else {
                memcpy(pcmBufferList.mBuffers.mData, audioBufferList.mBuffers.mData.advancedBy(i*Int(kBLOCK_SIZE)), Int(kBLOCK_SIZE))
            }
            
            var ouputPacketsCount = UInt32(1)
            currentAudioBufferList = pcmBufferList
            if (0 == AudioConverterFillComplexBuffer(render_converter, encoderDataProc, UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque()), &ouputPacketsCount, &aacBufferList, &resultDesc)) {
                data.appendBytes(aacBufferList.mBuffers.mData, length: Int(aacBufferList.mBuffers.mDataByteSize))
            }
            
            free(aacBufferList.mBuffers.mData)
            free(pcmBufferList.mBuffers.mData)
        }
    }
    
    var encoderDataProc: AudioConverterComplexInputDataProc = {(inAudioConverter: AudioConverterRef,
        ioNumberDataPackets: UnsafeMutablePointer<UInt32>, ioData: UnsafeMutablePointer<AudioBufferList>, outDataPacketDescription: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>>, inUserData: UnsafeMutablePointer<Void>) -> OSStatus in
        
        let converter = Unmanaged<KZConverter>.fromOpaque(COpaquePointer(inUserData)).takeUnretainedValue()
        
        let pcmList = converter.currentAudioBufferList
        ioData.memory.mBuffers.mData = pcmList.mBuffers.mData;
        ioData.memory.mBuffers.mDataByteSize = pcmList.mBuffers.mDataByteSize;
        ioData.memory.mBuffers.mNumberChannels = 1
        
        return 0
    }
    
    //MARK: Helper Functions
    
    func M4AFormatWith(channels: UInt32, sampleRate: Double) -> AudioStreamBasicDescription {
        var absd = AudioStreamBasicDescription()
        absd.mFormatID = kAudioFormatMPEG4AAC
        absd.mChannelsPerFrame = channels
        absd.mSampleRate = sampleRate
        
        var propSize = UInt32(sizeof(AudioStreamBasicDescription))
        AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &propSize, &absd)
        
        return absd
    }
    
    func adtsDataForPacketLength(packetLength: Int) -> NSData {
        let adtsLength = 7
        let profile = 2
        let freqIdx = 4
        let chanCfg = 1
        let fullLength = adtsLength + packetLength;
        
        var packet : [UInt8] = [255, 249]
        packet.append(UInt8(((profile-1)<<6) + (freqIdx<<2) + (chanCfg>>2)))
        packet.append(UInt8(((chanCfg&3)<<6) + (fullLength>>11)))
        packet.append(UInt8((fullLength&0x7FF) >> 3))
        packet.append(UInt8(((fullLength&7)<<5) + 0x1F))
        packet.append(252)
        return NSData(bytes: packet, length: packet.count)
    }
    
    func getAudioClassDescriptionWith(type: UInt32, manufacturer: UInt32) -> AudioClassDescription?  {
        var desc = AudioClassDescription()
        
        var encoderSpecifier = type;
        var st = OSStatus()
        var size = UInt32()
        
        st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, UInt32(sizeof(UInt32)), &encoderSpecifier, &size)
        if st != 0 {
            return nil
        }
        
        var descriptions = [AudioClassDescription]()
        st = AudioFormatGetProperty(kAudioFormatProperty_Encoders, UInt32(sizeof(UInt32)), &encoderSpecifier, &size, &descriptions);
        if st != 0 {
            return nil
        }
        
        for (var i = 0; i < descriptions.count; i++) {
            if (type == descriptions[i].mSubType) && (manufacturer == descriptions[i].mManufacturer) {
                memcpy(&desc, &(descriptions[i]), sizeof(AudioClassDescription));
                return desc;
            }
        }
        
        return AudioClassDescription(mType: kAudioEncoderComponentType, mSubType: type, mManufacturer: manufacturer)
    }
}

func AllocateABL(channelsPerFrame: UInt32, bytesPerFrame: UInt32, interleaved: Bool, capacityFrames: UInt32) -> AudioBufferList {
    var bufferList = AudioBufferList()
    
    let numBuffers = UInt32(interleaved ? 1 : channelsPerFrame)
    let channelsPerBuffer = UInt32(interleaved ? channelsPerFrame : 1)
    
    bufferList.mNumberBuffers = numBuffers
    bufferList.mBuffers.mData = calloc(Int(capacityFrames), Int(bytesPerFrame))
    bufferList.mBuffers.mDataByteSize = capacityFrames * bytesPerFrame;
    bufferList.mBuffers.mNumberChannels = channelsPerBuffer
    
    return bufferList;
}*/
