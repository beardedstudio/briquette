# ConnectionManager.rb
# briquette
#
# Created by Dominic Dagradi on 5/6/11.
# Copyright 2011 Bearded. All rights reserved.

class ConnectionManager
  
  @@manager = nil
  
  def initialize
    @networkQueue = []
    
    NSTimer.scheduledTimerWithTimeInterval(150, target:self, selector:NSSelectorFromString("emptyQueue"), userInfo:nil, repeats:true)
  end

  def queueRequest selector, onObject:object, withOptions:options
    options ||= []
    @networkQueue << {:selector => selector, :object => object, :options => options}
  end
  
  def emptyQueue
    until @networkQueue.empty? do
      q = @networkQueue.shift
      q[:object].send q[:selector], *q[:options]
    end
  end
  
  ####################################
  # Shared manager object
  ####################################
  
  def self.sharedManager
    if @@manager.nil?
      @@manager = ConnectionManager.new
    end
    
    @@manager
  end
  
end
