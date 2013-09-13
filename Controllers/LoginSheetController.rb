# LoginSheetController.rb
# briquette
#
# Created by Dominic Dagradi on 12/29/10.
# Copyright 2010 Bearded. All rights reserved.

require 'SiteSheetController'

class LoginSheetController < SiteSheetController
  
  def closeSheet sender
    super
  end
  
  def cancelSheet sender
    super
    NSApp.terminate nil
  end

end