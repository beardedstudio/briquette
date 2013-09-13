# RoomView.rb
# briquette
#
# Created by Dominic Dagradi on 10/24/10.
# Copyright 2010 Bearded. All rights reserved.

class RoomView < M3NavigationView

  include UploadHandler
  include TextHelper
  include KeyboardHelper

  attr_accessor :controller
  attr_accessor :textView
  attr_accessor :messagesView
  attr_accessor :loadingOverlay
  attr_accessor :loadingMessage
  attr_accessor :scriptobj


  def awakeFromNib
    @html_type = "room"
    
    @loadingOverlay.setFrame self.frame
    addSubview @loadingOverlay
    
    @cache = ""
    @last_message = Message.new({}, @controller.room)
    @last_time = nil
    
    # Load index view
    @messagesView.setShouldCloseWithWindow true
    @messagesView.UIDelegate = self
    @messagesView.frameLoadDelegate = self
    @messagesView.resourceLoadDelegate = self
    @messagesView.policyDelegate = self
    @messagesView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSBundle.mainBundle.URLForResource("index.html", withExtension:nil)))

    # WebView no caching rules
    messagesViewPrefs = @messagesView.preferences
    messagesViewPrefs.setCacheModel(WebCacheModelDocumentViewer)
    messagesViewPrefs.setUsesPageCache(false)
    
    # We register for files dragged on us (for drag and drop upload)
    self.registerForDraggedTypes([NSFilenamesPboardType])
  end
  
  def ready
    appendHTML @cache if @cache
    @cache = ""
  end
  
  def leftRoom
    @loadingMessage.setStringValue "Loading..."
    @loadingOverlay.hidden = false
    @loadingOverlay.setNeedsDisplay true

    # Clean message view
    @messagesView.stopLoading(nil)
    @messagesView.removeFromSuperview
    @messagesView = nil
  end
  
  def drawRect rect
    super
    NSColor.whiteColor.set
    NSRectFill(rect)
  end
  
  #########################################
  # Stream management
  #########################################  
  def streamStarted
    @loadingOverlay.hidden = true
    @loadingOverlay.setNeedsDisplay false
  end
  
  def streamFailed
    @loadingMessage.setStringValue "Your connection with Campfire was lost. Attempting to reconnect..."
    @loadingOverlay.hidden = false
    @loadingOverlay.setNeedsDisplay true

    @cache = ""
  end
  
  #########################################
  # User Input
  #########################################  
  
  def reply element # All lowercase for MacRuby
    room = element.valueForKey "room"
    user = element.valueForKey "user"
    @controller.replyTo(user,room)
  end
  
  def star element
    puts element.inspect
    puts "star!"
  end
  
  def play sound
    @controller.playNotificationSound sound
  end

  #########################################
  # Messages
  #########################################  
  
  def addMessage message, options = {}

    # Determine message state
    new_user = true
    new_day = false
    new_time = false
    messageHTML = ""

    new_user = @last_message.user != message.user unless !@last_message.userMessage? || !message.userMessage?
    new_type = @last_message.userMessage? != message.userMessage? || (new_user && message.userMessage?)
    new_day = @last_message.created_at.day != message.created_at.day 
        
    if @last_time.nil? || new_day || (@last_time + 5*60) < message.created_at
      new_time = true
      @last_time = message.created_at
    end

    if new_day
      messageHTML += DayMessageView.new(message, false, true, false).toHTML if display_day_breaks?
      new_type = true
      new_user = true
      new_time = true
    end
    
    begin
      # Get the view class for a message type and return the string
      messageView = eval(message.type+"View").new(message, new_user, new_type, new_time)
      messageHTML += messageView.toHTML @html_type

      # Store last message
      @last_message = message

    rescue NameError => e
      @last_message = Message.new({}, nil, @controller)
      return
    end
    
    # TODO: this sucks
    # Split on whitespace and replace with space (toss out new lines)
    messageHTML = messageHTML.gsub(/\s/, ' ')
    messageHTML = escape_javascript(messageHTML)

    if options["is_from_join"]
      @cache ||= ""
      @cache += messageHTML
    else
      appendHTML messageHTML, "true"
    end
  
  end
  
  def updateMessage message, options = {}
    messageView = eval(message.type+"View").new(message, true, true, true)
    messageHTML = messageView.toHTML @html_type
    
    original_message_id = options.fetch(:original_message_id){ nil }
    
    # TODO: this sucks
    # Split on whitespace and replace with space (toss out new lines)
    messageHTML = messageHTML.gsub(/\s/, ' ')
    messageHTML = escape_javascript(messageHTML)

    updateHTML(messageHTML, message.id, original_message_id)
  end
  
  def display_day_breaks?
    true
  end
  
  def addNotifications
    custom = Preferences.sharedPreferences.getDefault(NotificationPreferences::CUSTOM_NOTIFICATIONS) || []
    notifications = [] + custom + @controller.notifications

    notifications.each do |mention|
      addNotification mention
    end
  end
  
  def addNotification string
    return if @scriptobj.nil? or string.strip.empty? 
    @scriptobj.evaluateWebScript("addMention(\"#{string}\")")
  end
  
  def removeNotification string
    return if @scriptobj.nil? or string.strip.empty?
    @scriptobj.evaluateWebScript("removeMention(\"#{string}\")")
  end
  
  def updateVisibleMessages
    return unless @scriptobj
  
    # Set join/leave, images, timestamp visibility
    join_leave = Preferences.sharedPreferences.getDefault(MessagesPreferences::JOINLEAVE)
    images = Preferences.sharedPreferences.getDefault(MessagesPreferences::IMAGES)
    timestamp = Preferences.sharedPreferences.getDefault(MessagesPreferences::TIMESTAMPS)
    
    @scriptobj.evaluateWebScript("$('.joinleave').#{join_leave ? 'show' : 'hide'}();")
    @scriptobj.evaluateWebScript("$('.image').#{images ? 'show' : 'hide'}();")
    @scriptobj.evaluateWebScript("$('.timestamp').#{timestamp ? 'show' : 'hide'}();")
    
    scrollToLast
  end

  #########################################
  # Web UI delegate
  #########################################

  # Replaces current url request with a cache-less one
  def webView(sender, resource:identifier, willSendRequest:request, redirectResponse:redirectResponse, fromDataSource:dataSource)
    cachelessRequest = NSURLRequest.requestWithURL(request.URL, cachePolicy:NSURLRequestReloadIgnoringCacheData, timeoutInterval:100)
    return cachelessRequest
  end
    
  # Disable loading pages from dragged urls
  def webView(sender, dragDestinationActionMaskForDraggingInfo:draggingInfo)
    items_are_all_files = true
    draggingInfo.draggingPasteboard.pasteboardItems.each do |item|
      items_are_all_files = false unless item.types.include?('public.file-url')
    end
      
    return items_are_all_files ? WebDragDestinationActionAny : WebDragDestinationActionEdit
  end


  # Customize Webkit right-click menu
  def webView(sender, contextMenuItemsForElement:element, defaultMenuItems:defaultMenuItems)
    @lastElement = element

    # Menu items to remove
    openLinkTag = 2000 # Magic constant
    removeDefaults = [openLinkTag, WebMenuItemTagReload, WebMenuItemTagOpenLinkInNewWindow, WebMenuItemTagDownloadLinkToDisk]

    # Custom menu items
    copyMessage = NSMenuItem.alloc.initWithTitle("Copy Message", action: NSSelectorFromString("copyMessage:"), keyEquivalent: "")
    items = [copyMessage]
    if @lastElement["WebElementIsSelected"]
      items << NSMenuItem.alloc.initWithTitle("Search On Campfire", action: NSSelectorFromString("searchOnCampfire:"), keyEquivalent: "")
      items << NSMenuItem.separatorItem
    end
    
    defaultMenuItems.each do |item|
      items << item unless removeDefaults.include?(item.tag)
    end
    
    return items
  end
  
  def copyMessage sender
    node = @lastElement["WebElementDOMNode"]
    message_id = getMessageId node
  
    messageContent = @scriptobj.evaluateWebScript('getMessageData("'+message_id+'");')
    messageContent = messageContent.gsub("<br>", "\n")
    
    pasteboard = NSPasteboard.generalPasteboard
    pasteboard.clearContents
    pasteboard.writeObjects [messageContent]
  end
  
  def searchOnCampfire sender
    NSApplication.sharedApplication.delegate.showSearchWindow(messagesView.selectedDOMRange.text)
  end
  
  # Given a Webkit DOMNode, find the id of the containing message
  def getMessageId node

    name = node.nodeName
    node = node.parentNode if name == "#text" # Text nodes aren't real - don't try to operate on them

    id = (node.hasAttribute("id") ? node.getAttribute("id") : "")

    # If no id, continue searching DOM tree
    return getMessageId node.parentNode if id.empty?
    id
  end
  
  #########################################
  # Web resource load delegate
  #########################################  
  def webView(sender, resource:resource, didFinishLoadingFromDataSource:source)
    scrollToLast
  end

  #########################################
  # Web policy delegate
  #########################################
  
  def webView(webView, decidePolicyForNavigationAction:action, request:request, newFrameName:frame, decisionListener:listener)
    listener.ignore
    NSWorkspace.sharedWorkspace.openURL request.URL
  end
  
  # Decide what to do when a new window is requested
  def webView(webView, decidePolicyForNewWindowAction:action, request:request, newFrameName:frame, decisionListener:listener)
    listener.ignore
    NSWorkspace.sharedWorkspace.openURL request.URL
  end

  #########################################
  # WebScripting delegate
  #########################################

  # This WebScripting delegate method required and must be static.
  # Ensures only methods you want are exposed to javascript.
  def self.isSelectorExcludedFromWebScript(selector)
    return false
  end

  # Delegate method for obtaining the script object. Sets up the main
  # application callback object, myController. MacRuby method names
  # seem to need to be all lowercase characters e.g. 'runme', 'test'
  def webView(wv, windowScriptObjectAvailable:obj)
    @scriptobj = obj
    @scriptobj.setValue(self, forKey:'myController')
    self.respondsToSelector("reply:")
    self.respondsToSelector("star:")
    self.respondsToSelector("play:")
  end

  # Called whenever window.status is called in JS
  def webView(wv, setStatusText:text)
    NSLog "JS status -> #{text}" unless text.empty?
  end

  # Private WebViewUIDelegate method to trap console.log messages
  def webView(wv, addMessageToConsole:message)
    puts "JS console -> " + message['message'] 
  end

private
  #######################################
  # DOM manipulation
  #######################################

  # TODO: Looks like these can be refactored a ton
  
  # Append message HTML to messages div and scroll to bottom
  def appendHTML(html, posted = "false")
    unless @scriptobj.nil?

      @scriptobj.evaluateWebScript('addMessage("'+ html + '", "'+posted+'");')
      
      scrollToLast
      
      updateVisibleMessages
      addNotifications
    end
  end
  
  # Update HTML of existing messages
  def updateHTML(html, message_id, original_message_id = nil)
    unless @scriptobj.nil?
      @scriptobj.evaluateWebScript('updateMessage("'+html+'", "'+(original_message_id.nil? ? message_id.to_s : original_message_id.to_s) +'");')
            
      scrollToLast
      updateVisibleMessages
      addNotifications
    end
  end
  
  def scrollToLast
    doc = @messagesView.mainFrameDocument
    return if doc.nil? || @last_message.nil?

    last_id = nil
    last_id = @scriptobj.evaluateWebScript('$("#messages .message:visible:last").attr("id")') if @scriptobj
    last_id = @last_message.id.to_s if last_id.nil? or last_id.is_a? WebUndefined 
    
    element = doc.getElementById last_id
    element.scrollIntoView true unless element.nil?
  end
  
end