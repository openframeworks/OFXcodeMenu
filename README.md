OFPlugin
========

OpenFrameworks plugin for Xcode 5 that adds addons to open projects.

You can get a pre-compiled version of this addon at [adamcarlucci.com/ofplugin.zip](http://adamcarlucci.com/ofplugin.zip)

Building the included Xcode project will install the plugin. To do it manually, put OFPlugin.xcplugin in ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/OFPlugin.xcplugin

In theory it'll work on Xcode 4 as well, but you'll need to enable garbage collection when building the plugin.

Addon Writers!
--------------

The plugin parses addons_config.mk and will use it to tell which system frameworks to add, which folders to ignore, extra includes to add, etc. Example folders are always ignored by default. It will also use some of the meta data, such as the dependency list and addon url. If your addon doesn't work with OFPlugin properly out-of-the-box, you should add an addon_config.mk. See ofxKinect and ofxMidi for examples.

If OFPlugin doesn't seem to be parsing your addon_config.mk properly, please [open an issue](https://github.com/admsyn/OFPlugin/issues).

![screenshot](screenshot.jpg "it does this")
