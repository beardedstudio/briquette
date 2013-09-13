# AccountPreferencesController.rb
# briquette
#
# Created by Dominic Dagradi on 6/14/11.
# Copyright 2011 Bearded. All rights reserved.

require 'SiteSheetController'

class AccountPreferences < SiteSheetController

  attr_accessor :window
  attr_accessor :siteList

  SECTION = "account"
  USERNAME = :username
  PASSWORD = :password
  
  def init
    return super.initWithNibName("Accounts", bundle:nil)
  end
  
  def toolbarItemIdentifier
    "AccountPreferences"
  end
  
  def toolbarItemImage
    NSImage.imageNamed "AccountPreferences"
  end

  def toolbarItemLabel
    "Accounts"
  end
  
    def awakeFromNib
    @sites = Preferences.sharedPreferences.getSites.keys
    
    @updateKeys = false
  end

  # Open sheet for adding site/editting
  def openSiteSheet sender
  
    username_field.setStringValue ""
    username_field.setEnabled true

    password_field.setStringValue ""    
    password_field.setEnabled true
    
    site_field.setStringValue ""
    site_field.setEnabled true
    
    login_spinner.setHidden true
    login_label.setHidden true
    
    NSApp.beginSheet(@sheet, 
      :modalForWindow => @window, 
      :modalDelegate => self,
      :didEndSelector => NSSelectorFromString("didEndSheet:returnCode:contextInfo:"),
      :contextInfo => nil)
  end

  # Sheet closed method
  def didEndSheet sheet, returnCode:code, contextInfo:info    
    @sheet.orderOut self
  end
  
  def closeSheet sender
    super
    refreshSites
  end

  ########
  def removeSite sender
    return if @siteList.selectedRow == -1
    site = @sites[@siteList.selectedRow]
    
    Preferences.sharedPreferences.removeSite site
    
    NSApplication.sharedApplication.delegate.windowController.removeSite site
    
    refreshSites
  end

  ###############################
  # Site table data source
  ###############################
  def refreshSites
    @sites = Preferences.sharedPreferences.getSites.keys
    @siteList.reloadData
  end

  def numberOfRowsInTableView tableView
    @sites.count
  end
  
  def tableView(tableView, objectValueForTableColumn:col, row:row)
    @sites[row]
  end
  
end
