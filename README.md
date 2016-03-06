# STM [![Build Status](https://travis-ci.com/k3zi/STM.svg?token=gKfozS7CKh23NEAzKfWg&branch=master)](https://travis-ci.com/k3zi/STM)
- [Server][0]

**Only edit this file on the master branch**

----

**Table of Contents**
- [Tudo](#todo)

----

## Todo
- Transition away from `Realm` (takes way too long to build)

----

## App Rundown

#### 3rd Party Frameworks

These are the frameworks that we will use inside the iOS app. The app utilizes CocoaPods to install these frameworks.
- <a href="https://github.com/aerogear/aerogear-ios-http" target="_blank">AeroGearHttp</a> - Handles GET/POST requests and uploading files to server
- <a href="https://github.com/Hearst-DD/ObjectMapper" target="_blank">ObjectMapper</a> - Converts server objects into their coresponding models
- <a href="https://github.com/PureLayout/PureLayout" target="_blank">PureLayout</a> - Allows easy manipulation of view layouts
- <a href="https://github.com/onevcat/Kingfisher" target="_blank">Kingfisher</a> - Lazy loads images into UIImageView
- <a href="https://github.com/hackiftekhar/IQKeyboardManager" target="_blank">IQKeyboardManagerSwift</a> - Automatically shifts text inputs so they appear above the keyboard
- <a href="https://github.com/nielsmouthaan/SecureNSUserDefaults" target="_blank">SecureNSUserDefaults</a> - Used for storring user data securely
- <a href="https://github.com/tobiasahlin/SpinKit" target="_blank">SpinKit</a> - Displays a indicator on the screem
- <a href="https://github.com/Marxon13/M13ProgressSuite" target="_blank">M13ProgressSuite</a> - Displays progress bars and animations for loading

#### Swift Syntax/Conventions
- Here are some useful guides for coding effectively
  * https://github.com/github/swift-style-guide
  * https://github.com/schwa/Swift-Community-Best-Practices/
- Constants
  * We will be using a static struct type called `Constants` to
    - Store nonchanging variables such as the size of an image or colors used multiple times
    - Functions that are added to Apple's classes (AKA `extension`)

#### Structure
- Folder/Developmemt structure will be MVC or Model–View–Controller
  * Model - stores data retrieved from server
  * View - Updates itself depending on the data in the model
  * Controllers - encapsulates a main view (and it's subviews) and displays it on the screen

- Xcode makes strurcturing folders difficult. In Xcode to actually create a group that coresponds to a folder:
![Tip 1](https://www.dropbox.com/s/u9jypvkq4ytesd0/tip1.png?dl=1)

----

[0]: https://github.com/k3zi/STM-Server
