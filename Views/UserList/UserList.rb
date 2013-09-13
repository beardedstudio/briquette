# UserList.rb
# briquette
#
# Created by Dominic Dagradi on 1/2/11.
# Copyright 2011 Bearded. All rights reserved.

class UserList < NSTableView

  include KeyboardHelper

  def highlightSelectionInClipRect rect
    selectedRow = self.selectedRow
    return if selectedRow == -1

    drawingRect = self.rectOfRow(selectedRow)  
    NSColor.colorWithDeviceRed(0.78, :green => 0.83, :blue => 0.87, :alpha => 1.0).set
    NSRectFill(drawingRect)
  end

end