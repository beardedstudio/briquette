# SidebarView.rb
# briquette
#
# Created by Dominic Dagradi on 12/26/10.
# Copyright 2010 Bearded. All rights reserved.

class SidebarView < NSView

  include BackgroundImage

  def drawRect rect
    super rect
    NSColor.colorWithDeviceRed(0.914, :green => 0.933, :blue => 0.949, :alpha => 1.0).set          
    NSRectFill rect
  end
  
end