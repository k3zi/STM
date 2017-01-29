//
//  Strings+Localized.swift
//  STM
//
//  Created by Kesi Maduka on 1/28/17.
//  Copyright © 2017 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

extension String {

    struct Settings {
        static let HostMusicVolume = NSLocalizedString("Music Volume", comment: "")
        static let HostMusicVolumeDescription = NSLocalizedString("The volume for the music playback that listeners will here when the mic is inactive", comment: "")

        static let HostMicrophoneVolume = NSLocalizedString("Microphone Volume", comment: "")
        static let HostMicrophoneVolumeDescription = NSLocalizedString("The microphone's volume when it is active", comment: "")

        static let HostMusicVolumeWhenMicActive = NSLocalizedString("Music Volume When Mic Active", comment: "")
        static let HostMusicVolumeWhenMicActiveDescription = NSLocalizedString("The volume for the music playback that listeners will here when the mic is active", comment: "")

        static let HostMicFadeTime = NSLocalizedString("Microphone Fade Time", comment: "")
        static let HostMicFadeTimeDescription = NSLocalizedString("The duration that the music fades out for while the mic fades in", comment: "")

        static let StreamName = NSLocalizedString("Stream Name", comment: "")
        static let StreamNameDescription = NSLocalizedString("The name displayed to listeners for the broadcast", comment: "")

        static let StreamDescription = NSLocalizedString("Stream Description", comment: "")
        static let StreamDescriptionDescription = NSLocalizedString("Use this space to add details & extra info about you stream", comment: "")

        static let StreamPhoto = NSLocalizedString("Stream Photo", comment: "")
        static let StreamPhotoDescription = NSLocalizedString("Add a picture to make your stream stand out (Click on the right to change your stream's picture)", comment: "")

        static let StreamThemeColor = NSLocalizedString("Stream Theme Color", comment: "")
        static let StreamThemeColorDescription = NSLocalizedString("Theme your stream using the slider. This wil be saved for future streams and takes effect immediately", comment: "")

        static let HostMonitoring = NSLocalizedString("Mic Monitoring", comment: "")
        static let HostMonitoringDescription = NSLocalizedString("Toggle to hear microphone input", comment: "")
    }

    struct Navigation {
        static let Dashboard = NSLocalizedString("Dashboard", comment: "")
        static let Search = NSLocalizedString("Search", comment: "")
        static let Messages = NSLocalizedString("Messages", comment: "")
        static let Profile = NSLocalizedString("Profile", comment: "")
    }

}
