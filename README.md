OFPlugin
========

OpenFrameworks plugin for Xcode that adds addons to your project.

Installing
==========

Building the included Xcode project will install the plugin. To do it manually, put OFPlugin.xcplugin in:

    ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/OFPlugin.xcplugin

You may need to create a few of the directories on the way, as they don't all exist by default.

You can get a pre-compiled version of this addon at [adamcarlucci.com/ofplugin.zip](http://adamcarlucci.com/ofplugin.zip), though it'll be much easier to stay up to date by cloning this repo. 

![screenshot](screenshot.jpg "it does this")

Known Compatibility
===================
Should work on OSX 10.8+ with all versions of Xcode 5, as well as the Xcode 6 beta.

Troubleshooting
===============

**"I updated Xcode and now the plugin doesn't show up"**

Xcode works on a UUID whitelist system, meaning each new version of Xcode needs to have its UUID added to OFPlugin's Info.plist file. If OFPlugin isn't updated in time, you can do this update yourself (and by all means send a pull request afterwards!).

Get the UUID by running the following in the terminal:

```
defaults read /Applications/Xcode.app/Contents/Info DVTPlugInCompatibilityUUID
```
Then, open the OFPlugin project and edit the Supporting Files > OFPlugin-Info.plist file. You'll need to add the UUID you just copied to the DVTPlugInCompatibilityUUIDs section.

Rebuild the plugin, restart Xcode and you should see the OF menu reappear.

**"The plugin isn't adding my addon correctly"**

The plugin parses addons_config.mk and will use it to tell which system frameworks to add, which folders to ignore, extra includes to add, etc. Example folders are always ignored by default. It will also use some of the metadata, such as the dependency list and addon url. If your addon doesn't work with OFPlugin properly out-of-the-box, you should add an addon_config.mk. See ofxKinect and ofxMidi for examples.

If OFPlugin doesn't seem to be parsing your addon_config.mk properly, please [open an issue](https://github.com/admsyn/OFPlugin/issues).
