OFPlugin
========

OpenFrameworks plugin for Xcode 5. It adds addons to open projects.

You can get a pre-compiled version of this addon at [adamcarlucci.com/ofplugin.zip](http://adamcarlucci.com/ofplugin.zip)

Building the included Xcode project will install the plugin. To do it manually, put OFPlugin.xcplugin in ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/OFPlugin.xcplugin (to uninstall, just remove it from there. Obviously.)

In theory it'll work on Xcode 4 as well, but you'll need to enable garbage collection when building the plugin.

![screenshot](screenshot.png "it does this")

For the most part, the plugin should do the right thing when given an addon. It will add "src" and "libs" folders, ignoring those that are clearly for windows, linux, etc. Individual addons can have additional rules, such as how ofxCv requires a link to ofxOpenCv's static libs. See [OFAddon.m](https://github.com/admsyn/OFPlugin/blob/master/OFPlugin/OFAddon.m) if you'd like to pull-request any special cases for your addon.
