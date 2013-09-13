#
#  BRAnchoredButton.rb
#  briquette
#
#  Created by Dominic Dagradi on 8/29/11.
#  Copyright 2011 Bearded. All rights reserved.
#

class BRAnchoredButton < BWAnchoredButton
  def initWithInfo offset, image, action
    self.init

    self.setFrame NSMakeRect(offset, 0, 23, 23)
    self.setImage NSImage.imageNamed image
    self.setBezelStyle NSShadowlessSquareBezelStyle
    
    self
  end
end