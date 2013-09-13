# BriquetteDelegate.rb
# briquette
#
# Created by Dominic Dagradi on 10/24/10.
# Copyright 2010 Bearded. All rights reserved.
#
# Application Delegate

class BriquetteDelegate

  SPELLING_CORRECTION_ENABLED = "spelling_correction_enabled"
  
  attr_accessor :windowController

	def applicationDidFinishLaunching(notification)

    NSApplication.sharedApplication.setPresentationOptions (1<<10) # Substitute for NSApplicationPresentationFullScreen
    GrowlApplicationBridge.setGrowlDelegate self    

    setAppDefaults
    monitorNetwork
    
    showMainWindow

    showLoginSheet if Preferences.sharedPreferences.firstLaunch?
	end
  
  def setAppDefaults
    # Set defaults
    Preferences.sharedPreferences.setDefaultIfNil 1, BriquetteDelegate::SPELLING_CORRECTION_ENABLED
    Preferences.sharedPreferences.setDefaultIfNil true, MessagesPreferences::JOINLEAVE
    Preferences.sharedPreferences.setDefaultIfNil true, MessagesPreferences::IMAGES
    Preferences.sharedPreferences.setDefaultIfNil true, MessagesPreferences::TIMESTAMPS
    Preferences.sharedPreferences.setDefaultIfNil false, NotificationPreferences::NEW_GROWL
    Preferences.sharedPreferences.setDefaultIfNil false, NotificationPreferences::NEW_GROWL_PERSIST
    Preferences.sharedPreferences.setDefaultIfNil true, NotificationPreferences::MENTION_GROWL
    Preferences.sharedPreferences.setDefaultIfNil true, NotificationPreferences::MENTION_GROWL_PERSIST
    Preferences.sharedPreferences.setDefaultIfNil true, NotificationPreferences::NEW_BOUNCE
    Preferences.sharedPreferences.setDefaultIfNil true, NotificationPreferences::MENTION_BOUNCE
    Preferences.sharedPreferences.setDefaultIfNil false, NotificationPreferences::SOUND_ANNOUNCE_ALL
    Preferences.sharedPreferences.setDefaultIfNil false, NotificationPreferences::SOUND_ANNOUNCE_MENTION
    Preferences.sharedPreferences.setDefaultIfNil [], NotificationPreferences::CUSTOM_NOTIFICATIONS
  end
  
  def monitorNetwork
    @notifier = NetworkNotifier.alloc.init
    @notifier.delegate = ConnectionManager.sharedManager
  end
  
	def showMainWindow
		@windowController = MainWindowController.alloc().initWithWindowNibName("MainWindow") if @windowController.nil?
		@windowController.window.makeKeyAndOrderFront(self)
	end

	def showPreferencesWindow
    unless @preferenceController
      controllers = []
      accountPreferences = AccountPreferences.new 
      messagePreferences = MessagesPreferences.new
      controllers << accountPreferences
      controllers << messagePreferences
      controllers << NotificationPreferences.new

      @preferenceController = PreferencesWindowController.alloc().initWithViewControllers(controllers, title:"Preferences")
      @preferenceController.messagePreferences = messagePreferences
      accountPreferences.window = @preferenceController.window
    end

    @preferenceController.window.makeKeyAndOrderFront(self)
	end	
  
  def updateWindowTitle(title = "Briquette")
    @windowController.window.setTitle(title) unless @windowController.nil?
  end

	def showSearchWindow(search_term = nil)

    @searchController = SearchWindowController.alloc().initWithWindowNibName("SearchWindow") unless @searchController
    @searchController.starting_term = search_term unless search_term.nil?
    @searchController.window.makeKeyAndOrderFront(self)
    @searchController.updateSearchFieldAndSearch(nil)

	end
  
  # Load and manage login sheet on first run
  def showLoginSheet
    NSApp.beginSheet(@windowController.sheet, 
      :modalForWindow => @windowController.window, 
      :modalDelegate => self,
      :didEndSelector => NSSelectorFromString("closeLoginSheet:returnCode:contextInfo:"),
      :contextInfo => nil)
  end
  
  def closeLoginSheet sheet, returnCode:code, contextInfo:info
    sheet = @windowController.sheet
    
    @windowController.sheet.orderOut self
  end
  
  ########################################  
  # Application Events
  ########################################  

  #when this app gets focus mark the current room's messages as read.
  def applicationWillBecomeActive event
    @windowController.markCurrentRoomAsRead unless @windowController.nil?
  end
  
  def applicationShouldHandleReopen app, hasVisibleWindows:flag
    showMainWindow if !flag 
    true
  end
  
  def applicationShouldTerminate sender
    #leave all rooms before quitting
    @windowController.sites.values.each{|site| site.leaveAllRooms({"exiting" => true}) }

    return NSTerminateNow
  end
  
  def growlNotificationWasClicked context
    NSApp.activateIgnoringOtherApps true
    showMainWindow
    @windowController.selectRoomWithId context
  end
  
  # Refreshes all the messages in our currently open rooms
  def refreshRoomViews
    @windowController.sites.each_value do |site|
      site.rooms.each_value do |room| 
        room.controller.view.updateVisibleMessages if room.controller
      end
    end
  end

  # Manage notification highlights in views
  def addNotificationToViews notification_string
    @windowController.sites.each_value do |site|
      site.rooms.each_value do |room| 
        room.controller.view.addNotification notification_string if room.joined
      end
    end
  end

  def removeNotificationFromViews notification_string
    @windowController.sites.each_value do |site|
      site.rooms.each_value do |room| 
        room.controller.view.removeNotification notification_string if room.joined
      end
    end
  end
  
  ####################################
  # Application Status
  ####################################
  
  # Posts application status message to specified room without sending through Campfire
  def addStatusMessage(status, toRoom:room)
    message = { 'type' => Message::SYSTEM,
                'created_at' => Time.now.to_s,
                'room_id' => room.id,
                'body' => status,
                'user_id' => 'null',
                'id' => "status-#{Time.now.to_i}"
              }
              
    room.messageReceived message
  end
  
  def addAlert(title, message, type, room = nil)
    messageView = @windowController.messagesView
    alert = AlertView.alloc.initWithFrame NSMakeRect(0,messageView.frame.size.height-48,messageView.frame.size.width,48)
    alert.title = title
    alert.message = message
    alert.type = type
    
    messageView.addSubview alert
  end
  
  ####################################
  # Navigation
  ####################################
  def selectNextRoom
    @windowController.roomList.selectNextRoomView
  end

  def selectPreviousRoom
    @windowController.roomList.selectPrevRoomView
  end

  
  ####################################
  # Spelling Correction
  ####################################
  def toggleSpellingCorrection
    @windowController.rooms.each_value do |room|
      unless room.controller.nil?
        input = room.controller.messageInput
        input.toggleAutomaticSpellingCorrection self        
      end
    end

    #    puts Preferences.sharedPreferences.getDefault(BriquetteDelegate::SPELLING_CORRECTION_ENABLED)
    #puts value
    
    #Preferences.sharedPreferences.setDefault(value,BriquetteDelegate::SPELLING_CORRECTION_ENABLED)
  end
  
  
end