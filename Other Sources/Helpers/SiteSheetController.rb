# SiteSheetController.rb
# briquette
#
# Created by Dominic Dagradi on 1/22/11.
# Copyright 2011 Bearded. All rights reserved.

class SiteSheetController < NSViewController
  
  attr_accessor :sheet
  attr_accessor :username_field
  attr_accessor :password_field
  attr_accessor :site_field
  attr_accessor :login_spinner
  attr_accessor :login_label
  attr_accessor :submit_button

  attr_accessor :site
  attr_accessor :site_info
  
  # Take info in sheet and attempt to connect to campfire site
  def attemptLogin sender    
    sheet.makeFirstResponder submit_button

    # Disable fields
    username_field.setEnabled false
    password_field.setEnabled false
    site_field.setEnabled false
    login_spinner.setHidden false
    login_label.setHidden true
    
    # Get entered values
    @username = username_field.stringValue
    @password = password_field.stringValue
    @site = site_field.stringValue
    
    @site.match(/(?:http[s]?:\/\/)?(.*).campfirenow.com/) do |m|
      @site = m[1]
    end

    request = Request.get("https://#{@site}.campfirenow.com/users/me.json", delegate:self, callback:"triedLogin:", site:nil, options:{"username" => @username, "password" => @password})
  end
  
  # Take action on response received from trying to get API token for a site
  def triedLogin request    
    # Successful request
    if request.responseStatusCode == 200 && !request.responseHash["user"].nil?
      user = request.responseHash["user"]
      
      @site_info = {}
      @site_info["title"] = @site
      @site_info["user_id"] = user["id"]
      @site_info["api_token"] = user["api_auth_token"]
      @site_info["name"] = user["name"]
      @site_info["username"] = @username
      
      # Add site to user defaults and create object
      Preferences.sharedPreferences.addSite @site, @site_info

      # Close sheet
      closeSheet self
      
    # Unsuccessful request
    else
      if request.responseStatusCode == 0 || request.responseStatusCode == 404
        login_label.stringValue = "Could not connect to #{@site}.campfirenow.com"                
      elsif request.responseStatusCode == 401
        login_label.stringValue = "Invalid username or password"
      else 
        login_label.stringValue = "Could not login. Please try again."
      end

      # Reenable fields and put error message
      username_field.setEnabled true
      password_field.setEnabled true
      site_field.setEnabled true
      login_spinner.setHidden true
      login_label.setHidden false
    end
  end
  
  def cancelSheet sender
    NSApp.endSheet @sheet
  end
  
  def closeSheet sender
    NSApp.endSheet @sheet

    # Add site to Campfire
    NSApplication.sharedApplication.delegate.windowController.addSite @site, @site_info
  end

end
