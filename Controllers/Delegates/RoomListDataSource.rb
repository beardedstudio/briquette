# RoomListDataSource.rb
# briquette
#
# Created by Dominic Dagradi on 6/18/11.
# Copyright 2011 Bearded. All rights reserved.

class RoomListDataSource

  attr_accessor :windowController

  def numberOfSectionsInListView listView
    return 0 if windowController.nil?
    count = windowController.children.count
    count
  end
    
  def listView(listView, numberOfViewsInSection:sectionIndex)
    return 0 if windowController.nil? || windowController.childAt(sectionIndex).nil?
    count = windowController.childAt(sectionIndex).children.count
    count
  end

  def listView(listView, sectionHeaderViewForSection:sectionIndex)
    view = windowController.childAt(sectionIndex).listItemView
    view
  end

  def listView(listView, viewForSection:sectionIndex, index:index)
    section = windowController.childAt(sectionIndex)    
    view = section.childAt(index).listItemView
    view
  end

end
