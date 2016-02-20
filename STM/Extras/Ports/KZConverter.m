//
//  Ports.m
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

#import "KZConverter.h"

#define kBLOCK_SIZE 4096

@interface KZConverter()

@property AudioConverterRef render_converter;
@property double currentSampleRate;
@property AudioStreamBasicDescription descAACFormat;
@property AudioStreamBasicDescription sourceFormat;

@end

@implementation KZConverter


- (instancetype)init {
    self = [super init];
    _descAACFormat = [KZConverter M4AFormatWithNumberOfChannels:1 sampleRate:48000];
    return self;
}

- (void)pipeData:(AudioBufferList *)audioBufferList format:(AudioStreamBasicDescription)format {
    if(_currentSampleRate != [AVAudioSession sharedInstance].sampleRate){
        _currentSampleRate = [AVAudioSession sharedInstance].sampleRate;
        _descAACFormat = [KZConverter M4AFormatWithNumberOfChannels:1 sampleRate:48000];
        // see the question as for setting up pcmASBD and arc ASBD
        AudioClassDescription *description = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
        if (!description){
            NSLog(@"description  fail!");
        }
        
        
        OSStatus st = AudioConverterNewSpecific(&format, &_descAACFormat, 2, description, &_render_converter);
        if(st){
            NSLog(@"error creating audio converter: %d", (int)st);
        }
    }
    
    NSMutableData *data = [NSMutableData data];
    int times = ceilf((float)audioBufferList->mBuffers[0].mDataByteSize / (float)kBLOCK_SIZE);
    
    for (int i = 0; i < times; i++) {
        AudioBufferList *pcmBufferList = AllocateABLX(audioBufferList->mBuffers[0].mNumberChannels, kBLOCK_SIZE, TRUE, 1);
        AudioBufferList *aacBufferList = AllocateABLX(1, kBLOCK_SIZE, TRUE, 1);
        AudioStreamPacketDescription resultDesc;
        
        if((i*kBLOCK_SIZE + kBLOCK_SIZE) > audioBufferList->mBuffers[0].mDataByteSize){
            memcpy(pcmBufferList->mBuffers[0].mData, (char*)audioBufferList->mBuffers[0].mData + (i*kBLOCK_SIZE), audioBufferList->mBuffers[0].mDataByteSize - (i*kBLOCK_SIZE));
        }else{
            memcpy(pcmBufferList->mBuffers[0].mData, (char*)audioBufferList->mBuffers[0].mData + (i*kBLOCK_SIZE), kBLOCK_SIZE);
        }
        
        UInt32 ouputPacketsCount = 1;
        if (0 == AudioConverterFillComplexBuffer(_render_converter, encoderDataFunc, &pcmBufferList, &ouputPacketsCount, aacBufferList,&resultDesc)){
            [data appendData:[self adtsDataForPacketLength:aacBufferList->mBuffers[0].mDataByteSize]];
            [data appendBytes:aacBufferList->mBuffers[0].mData length:aacBufferList->mBuffers[0].mDataByteSize];
        }
        free(aacBufferList->mBuffers[0].mData);
        free(aacBufferList);
        free(pcmBufferList->mBuffers[0].mData);
        free(pcmBufferList);
    }
    
    if(self.delegate != nil) {
        [self.delegate receiveConvertedData:data];
    }
}

OSStatus encoderDataFunc(AudioConverterRef inAudioConverter,
                         UInt32* ioNumberDataPackets,
                         AudioBufferList* ioData,
                         AudioStreamPacketDescription** outDataPacketDescription,
                         void* inUserData)
{
    AudioBufferList *pcmList = *(AudioBufferList**)inUserData;
    // put the data pointer into the buffer list
    ioData->mBuffers[0].mData = pcmList->mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = pcmList->mBuffers[0].mDataByteSize;
    ioData->mBuffers[0].mNumberChannels = pcmList->mBuffers[0].mNumberChannels;
    
    return 0;
}

- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer {
    static AudioClassDescription desc;
    
    UInt32 encoderSpecifier = type;
    OSStatus st;
    
    UInt32 size;
    st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier,
                                    &size);
    if (st) {
        NSLog(@"error getting audio format propery info: %d", (int)st);
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    st = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                sizeof(encoderSpecifier),
                                &encoderSpecifier,
                                &size,
                                descriptions);
    if (st) {
        //  NSLog(@"error getting audio format propery: %s", OSSTATUS(st));
        
        NSLog(@"error getting audio format propery: %d", (int)st);
        
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }
    
    return nil;
}

+ (AudioStreamBasicDescription)M4AFormatWithNumberOfChannels:(UInt32)channels sampleRate:(float)sampleRate {
    AudioStreamBasicDescription asbd;
    memset(&asbd, 0, sizeof(asbd));
    asbd.mFormatID          = kAudioFormatMPEG4AAC;
    asbd.mChannelsPerFrame  = channels;
    asbd.mSampleRate        = sampleRate;
    
    // Fill in the rest of the descriptions using the Audio Format API
    UInt32 propSize = sizeof(asbd);
    [self checkResult:AudioFormatGetProperty(kAudioFormatProperty_FormatInfo,
                                             0,
                                             NULL,
                                             &propSize,
                                             &asbd)
            operation:"Failed to fill out the rest of the m4a AudioStreamBasicDescription"];
    
    return asbd;
}

+ (void)checkResult:(OSStatus)result
          operation:(const char *)operation {
    if (result == noErr) return;
    char errorString[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(result);
    if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(errorString, "%d", (int)result);
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}

- (NSData*) adtsDataForPacketLength:(NSUInteger)packetLength {
    int adtsLength = 7;
    char *packet = (char*)(malloc(sizeof(char) * adtsLength));
    // Variables Recycled by addADTStoPacket
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    int freqIdx = 3;  //44.1KHz
    int chanCfg = 1;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + packetLength;
    // fill in ADTS data
    packet[0] = (char)0xFF;	// 11111111  	= syncword
    packet[1] = (char)0xF9;	// 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) + (chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

@end







AudioBufferList * AllocateABLX(UInt32 channelsPerFrame, UInt32 bytesPerFrame, bool interleaved, UInt32 capacityFrames){
    AudioBufferList *bufferList = NULL;
    
    UInt32 numBuffers = interleaved ? 1 : channelsPerFrame;
    UInt32 channelsPerBuffer = interleaved ? channelsPerFrame : 1;
    
    bufferList = (AudioBufferList *)(calloc(1, offsetof(AudioBufferList, mBuffers) + (sizeof(AudioBuffer) * numBuffers)));
    
    bufferList->mNumberBuffers = numBuffers;
    
    for(UInt32 bufferIndex = 0; bufferIndex < bufferList->mNumberBuffers; ++bufferIndex)
    {
        bufferList->mBuffers[bufferIndex].mData = (void *)(calloc(capacityFrames, bytesPerFrame));
        bufferList->mBuffers[bufferIndex].mDataByteSize = capacityFrames * bytesPerFrame;
        bufferList->mBuffers[bufferIndex].mNumberChannels = channelsPerBuffer;
    }
    
    return bufferList;
}