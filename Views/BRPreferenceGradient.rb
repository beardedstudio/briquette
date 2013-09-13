# BRPreferenceGradient.rb
# briquette
#
# Created by Dominic Dagradi on 6/12/11.
# Copyright 2011 Bearded. All rights reserved.

class BRPreferenceGradient < BWGradientBox
  def awakeFromNib
    self.hasTopBorder = true
    self.hasBottomBorder = true
    self.topBorderColor = NSColor.colorWithHexColorString "f2f2f2"
    self.bottomBorderColor = NSColor.colorWithHexColorString "d7d7d7"
  end
end
