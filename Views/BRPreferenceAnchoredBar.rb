# BRPreferenceAnchoredBar.rb
# briquette
#
# Created by Dominic Dagradi on 6/12/11.
# Copyright 2011 Bearded. All rights reserved.

class BRPreferenceAnchoredBar < BWAnchoredButtonBar  
  def awakeFromNib
    self.isResizable = false
    self.isAtBottom = false
  end
end
