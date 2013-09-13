# RoomController.rb
# briquette
#
# Created by Dominic Dagradi on 10/24/10.
# Copyright 2010 Bearded. All rights reserved.

class RoomController < NSViewController

  include TextHelper
  include UploadHandler

  attr_accessor :site
  attr_accessor :room
  attr_accessor :splitView
  attr_accessor :usersView
  attr_accessor :messageInput
  
  VALID_SOUNDS = ['rimshot','crickets','trombone','drama','tmyk','vuvuzela','live','greatjob','pushit','alert']
  
  def awakeFromNib
    @awake = true
    if @ready
      joinedRoom
    end
    
  
    @splitView.subviews[0].setAutoresizingMask NSViewWidthSizable    
    @splitView.colorIsEnabled = true
    @splitView.color = NSColor.colorWithHexColorString("EFF1F4")
  end

  def has_focus?
    @focus = false if @focus.nil?
    @focus
  end
  
  def select
    @focus = true
    markMessagesAsRead
  end
  
  def deselect
    @focus = false
  end
  
  def notifications
    [@room.site.name.downcase]
  end
  
  ############################################### 
  # User Input
  ############################################### 
  def postMessage string    
    # Copy string, instead of passing by reference
    new_string = "" + string
    if string.match(/^http(s)?:\/\/twitter.com\/\S+\/status\/\d+$/)
      @room.tweet new_string
    elsif new_string.index("\n")
      @room.paste new_string
      
    # Match strings to play sounds
    elsif %w(\sound \plays \play /sound /plays /play).map{|str| new_string.index "#{str} "}.include? 0
      sound_name = new_string.sub(/[\\,\/][a-zA-Z]+ /, "")
      
      if VALID_SOUNDS.include?(sound_name)
        @room.play sound_name 
      else
        NSApplication.sharedApplication.delegate.addStatusMessage("Unknown Sound #{sound_name}", :toRoom => @room)
      end
      
    # Match /topic to change room tpic
    elsif %w(\topic /topic).map{|str| new_string.index "#{str} "}.include? 0
      new_string = new_string.sub(/[\\,\/][a-zA-Z]+ /, "")
      @room.setTopic new_string
      
    # Match /name to change room name
    elsif %w(\name /name).map{|str| new_string.index "#{str} "}.include? 0
      new_string = new_string.sub(/[\\,\/][a-zA-Z]+ /, "")
      @room.setName new_string
      NSApplication.sharedApplication.delegate.updateWindowTitle("#{@room.site.title} - #{new_string}");
      
    # Match /me syntax
    elsif %w(\me /me).map{|str| new_string.index "#{str} "}.include? 0
      @room.message "*" + new_string.sub(/[\/|\\]me /, "") + "*"
      
    # FOR BRETT
    elsif %w(\dundun /dundun).map{|str| new_string.index "#{str}"}.include? 0
      @room.play "drama"
    else
      @room.message new_string       
    end
  end

  def replyTo user, room
    insertCompletion user
  end
  
  def insertCompletion string
    @messageInput.insertCompletion(string, forPartialWordRange:@messageInput.selectedRange, movement:NSTabTextMovement, isFinal:true)
    @messageInput.insertText " "
  end

  def uploadDialog sender
    openPanel = NSOpenPanel.openPanel
    openPanel.setAllowsMultipleSelection true

    result = openPanel.runModalForDirectory(NSHomeDirectory(), file:nil, types:nil)
    _uploadFiles openPanel.filenames if result == NSOKButton
  end 

  ############################################### 
  # Room delegate methods
  ############################################### 
  def joinedRoom
    if @awake
      refreshUsers
      view.ready      
    else 
      @ready = true
    end
  end
  
  def leftRoom
    view.leftRoom
  end
  
  def refreshUsers
    @usersView.reloadData 
  end
  
  def addMessage message, options = {}
    view.addMessage message, options
    
    unless options["is_from_join"]
      notifyUser message    
    end
  end
  
  def updateMessage message, options = {}
    view.updateMessage message, options
  end
  
  def notifyUser message
    unless has_focus? && !NSApplication.sharedApplication.keyWindow.nil?      
      # Increment dock badge count
      updateBadgeForMessage message if message.shouldUpdateBadgeLabel?
      
      # Bounce dock icon
      bounceDockIcon if message.shouldBounceDockIcon?
      
      # Post Growl notification 
      postGrowlMessage message if message.shouldPostGrowlMessage?
    end

    # Play sound notification, even if we have focus
    playNotificationSound if message.shouldPlaySoundNotification?
  end
  
  def playNotificationSound sound = "incoming"
    url = NSBundle.mainBundle.URLForResource("#{sound}.mp3", withExtension:nil)
    sound = NSSound.alloc.initWithContentsOfURL(url, :byReference => false)
    sound.nil? ? NSLog("Couldn't play alert sound.") : sound.play
  end 
  
  def updateBadgeForMessage message
    if message.mentioned?
      @room.badgeMention += 1
    else
      @room.badgeMessage += 1
    end
    
    # get our badge label, set to 1 if there is none, otherwise increment, then update the badge label.
    badgeText = NSApplication.sharedApplication.dockTile.badgeLabel
    updatedText = badgeText.nil? ? "1" : (badgeText.to_i + 1).to_s
    
    # TODO: combine these into an updateInterface method of some sort
    NSApplication.sharedApplication.dockTile.setBadgeLabel(updatedText)
    NSApplication.sharedApplication.delegate.windowController.roomList.reloadData        
  end
  
  def bounceDockIcon
    NSApplication.sharedApplication.requestUserAttention NSInformationalRequest
  end
  
  def postGrowlMessage message    
    # Build title with room and user name if possible
    title = "#{@room.title}" 
    title += ": #{message.user.name}" unless message.user.nil?

    # Strip HTML from messages
    body = message.raw
    
    GrowlApplicationBridge.notifyWithTitle(title, 
      description:body, 
      notificationName:"message", 
      iconData:nil, 
      priority:0, 
      isSticky:message.growlMessageIsSticky?,
      clickContext:@room.id)
  end
  
  # subtracts the number of new messages for this room from the badge label and resets @badgeCount to 0
  def markMessagesAsRead
    badgeText = NSApplication.sharedApplication.dockTile.badgeLabel
    return if badgeText.nil?
    
    totalUnreadMessageCount = badgeText.to_i - @room.badgeCount
    updatedText = totalUnreadMessageCount == 0 ? nil : totalUnreadMessageCount.to_s
    @room.badgeMessage = 0
    @room.badgeMention = 0

    NSApplication.sharedApplication.dockTile.setBadgeLabel(updatedText)
    NSApplication.sharedApplication.delegate.windowController.roomList.reloadData  
  end
  
  #########################################
  # Stream management
  #########################################  
  def streamStarted
    view.streamStarted
  end
  
  def streamFailed
    view.streamFailed
  end
  
  ############################################### 
  # Text view delegate methods
  ############################################### 
  def textView(textView, doCommandBySelector:sel)
    result = false
    
    # if there's no text in the textView, act like we handled an event so a newline doesn't get added.
    if textView.string.empty?
      result = true
      
    # Send message on new line      
    elsif sel == NSSelectorFromString("insertNewline:") && !textView.string.empty?
      # Detect if shift key being pressed: http://www.cocoadev.com/index.pl?DetectIfShiftKeyIsBeingPressed
      flags = NSApplication.sharedApplication.currentEvent.modifierFlags
      if (flags & NSShiftKeyMask) != NSShiftKeyMask
        message = textView.string
        self.postMessage message
 
        textView.shouldChangeTextInRange(NSMakeRange(0, message.length), replacementString:"")
        textView.setString ""
        textView.breakUndoCoalescing
        
        result = true
      end
      
    # Complete names/rooms on tab
    # TODO: support room names
    elsif sel == NSSelectorFromString("insertTab:")
      textView.complete self
      result = true
    elsif sel == NSSelectorFromString("noop:")
      result = true
    end
    
    
    result
  end
  
  # Provide list of usernames that match the word being completed
  def textView(textView, completions:completions, forPartialWordRange:range, indexOfSelectedItem:selected)
    partial = textView.string.substringWithRange range
    
    @completions = []
    return @completions if partial.empty?
    
    @room.completions.each do |item|
      
      # Check from start of word to length of completion
      check = item[0, range.length]

      if check.downcase == partial.downcase
        @completions << item
      end
    end
    
    @completions
  end
  
  ############################################### 
  # User List data source and delegate methods
  ############################################### 
  def numberOfRowsInTableView table_view
    @room.present.compact.size
  end

  def tableView(table_view, objectValueForTableColumn:column, row:index)
    name = @room.present[index].nil? ? "" : @room.present[index].name
  end
   
  def tableViewSelectionDidChange(aNotification)
    selection =  @usersView.selectedRow
    return if selection == -1
    
    name = @room.present[selection].name
    insertCompletion name
        
    @usersView.deselectAll self
  end
          
end