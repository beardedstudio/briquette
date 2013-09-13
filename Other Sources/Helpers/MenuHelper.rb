# MenuHelper.rb
# briquette
#
# Created by Dominic Dagradi on 1/23/11.
# Copyright 2011 Bearded. All rights reserved.

class MenuHelper

  def nextRoom sender
    NSApplication.sharedApplication.delegate.selectNextRoom
  end
  
  def prevRoom sender
    NSApplication.sharedApplication.delegate.selectPreviousRoom
  end
  
  def supportPage sender
    NSWorkspace.sharedWorkspace.openURL NSURL.URLWithString "http://getsatisfaction.com/bearded/products/bearded_briquette"
  end
  
  def refreshRooms sender
    NSApplication.sharedApplication.delegate.windowController.updateSites
  end
  
  def searchTranscripts sender
    NSApplication.sharedApplication.delegate.showSearchWindow 
  end

  def showMainWindow sender
    NSApplication.sharedApplication.delegate.showMainWindow
  end
  
  def showPreferences sender
    NSApplication.sharedApplication.delegate.showPreferencesWindow
  end
  
  def toggleSpellingCorrection sender
    NSApplication.sharedApplication.delegate.toggleSpellingCorrection
  end
  
  ####################################
  # Fullscreen
  ####################################
  def toggleFullscreen sender
    if defined?(NSAppKitVersionNumber10_6)
      NSApplication.sharedApplication.delegate.windowController.window.toggleFullScreen(sender)
    end
  end
  
  def hideFullscreen
    return defined?(NSAppKitVersionNumber10_6).nil?
  end
  
end