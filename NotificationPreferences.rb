# NotificationPreferencesControlelr.rb
# briquette
#
# Created by Dominic Dagradi on 6/14/11.
# Copyright 2011 Bearded. All rights reserved.

require 'PreferencePaneController'

class NotificationPreferences < PreferencePaneController
  ON = NSOnState
  OFF = NSOffState
  
  attr_accessor :custom_notification_list
  attr_accessor :notifications_table
  
  SECTION = "notifications"

  NEW_GROWL = SECTION+"_new_growl"
  NEW_GROWL_PERSIST = SECTION+"_new_growl_persist"
  NEW_BOUNCE = SECTION+"_new_bounce"
  MENTION_GROWL = SECTION+"_mention_growl"
  MENTION_GROWL_PERSIST = SECTION+"_mention_growl_persist"
  MENTION_BOUNCE = SECTION+"_mention_bounce"
  CUSTOM_NOTIFICATIONS = "#{SECTION}_custom_notifications"
  SOUND_ANNOUNCE_ALL = "_sound_announce_all"
  SOUND_ANNOUNCE_MENTION = "_sound_announce_mention"

  def init
    return super.initWithNibName("Notifications", bundle:nil)
  end

  def toolbarItemIdentifier
    "NotificationPreferences"
  end
  
  def toolbarItemImage
    NSImage.imageNamed "NotificationPreferences"
  end

  def toolbarItemLabel
    "Notifications"
  end
  
  def updateNewGrowl sender
	checked = sender.state == ON

	unless checked
	  view.new_growl_persist.setState(OFF)
	  view.mention_growl_persist.enabled = view.mention_growl.enabled = true
	end
	updateCheckboxPrefs
  end

  def updateNewGrowlPersist sender
	checked = sender.state == ON
	
    if checked
	  [view.new_growl, view.mention_growl, view.mention_growl_persist].each{ |notif| notif.setState(ON)}
	end
	
	view.mention_growl.enabled = view.mention_growl_persist.enabled = !checked
	updateCheckboxPrefs
  end

  def updateMentionGrowl sender
    view.mention_growl_persist.setState(OFF) if sender.state == OFF
	updateCheckboxPrefs
  end

  def updateMentionGrowlPersist sender
    view.mention_growl.setState(NSOnState) if sender.state == NSOnState
	updateCheckboxPrefs
  end

  def updateNewBounce sender    
    # If notifications on all messages is switched, enabled/disable the notifications for mentions only button
    view.mention_bounce.enabled = (sender.state == NSOnState ? false : true)
    view.mention_bounce.setState(NSOnState) if sender.state == NSOnState
	updateCheckboxPrefs
  end

  def updateMentionBounce sender
	updateCheckboxPrefs
  end

  def updateSoundAnnounceAll sender
    # If notifications on all messages is switched, enabled/disable the notifications for mentions only button
    view.sound_announce_mention.enabled = sender.state == NSOnState ? false : true    
    view.sound_announce_mention.setState(NSOnState) if sender.state == NSOnState
	updateCheckboxPrefs
  end

  def updateSoundAnnounceMention sender
    updateBoolean SOUND_ANNOUNCE_MENTION, sender.state
  end

  # Custom notifications table view delegate methods
  ##################################
  def numberOfRowsInTableView table_view
    custom_notification_list.size
  end

  def tableView(table_view, objectValueForTableColumn:column, row:index)
    custom_notification_list[index]
  end
  
  # Add a new blank line to the notifications table and put it in editting mode
  def addCustomNotification sender
    custom_notification_list << ""
    notifications_table.reloadData
    notifications_table.selectRowIndexes(NSIndexSet.indexSetWithIndex(custom_notification_list.size-1), byExtendingSelection:false)
    notifications_table.editColumn(0, row:custom_notification_list.size-1, withEvent:nil, select:true)
  end

  # Remove selected notification from table
  def removeCustomNotification sender
    return if notifications_table.selectedRow == -1
    removed = custom_notification_list[notifications_table.selectedRow]
    custom_notification_list.delete_at(notifications_table.selectedRow)

    update_custom_notification_list      
    
    # Remove notification highlight from views
    NSApplication.sharedApplication.delegate.removeNotificationFromViews(removed)
  end

  def tableView(table_view, setObjectValue:updated_notification, forTableColumn:column, row:rowIndex)
    original_notification = custom_notification_list[rowIndex]
    custom_notification_list[rowIndex] = updated_notification

    update_custom_notification_list
    
    # Add notification highlight to views
    NSApplication.sharedApplication.delegate.addNotificationToViews(updated_notification)
    NSApplication.sharedApplication.delegate.removeNotificationFromViews(original_notification)
  end
  
  def custom_notification_list
    @custom_notification_list ||= Preferences.sharedPreferences.getDefault(CUSTOM_NOTIFICATIONS)
    if @custom_notification_list.nil?
      @custom_notification_list = []
      update_custom_notification_list    
    end
    @custom_notification_list
  end
  
  def update_custom_notification_list
    Preferences.sharedPreferences.setDefault(@custom_notification_list, CUSTOM_NOTIFICATIONS)
    notifications_table.reloadData
  end

  def updateCheckboxPrefs
    updateBoolean(NEW_GROWL, view.new_growl.state)
	updateBoolean(NEW_GROWL_PERSIST, view.new_growl_persist.state)
	updateBoolean(MENTION_GROWL, view.mention_growl.state)
	updateBoolean(MENTION_GROWL_PERSIST, view.mention_growl_persist.state)
	updateBoolean(NEW_BOUNCE, view.new_bounce.state)
	updateBoolean(MENTION_BOUNCE, view.mention_bounce.state)
	updateBoolean(SOUND_ANNOUNCE_ALL, view.sound_announce_all.state)
	updateBoolean(SOUND_ANNOUNCE_MENTION, view.sound_announce_mention.state)
  end

end
