#
#  TranscriptView.rb
#  briquette
#
#  Created by Dominic Dagradi on 7/31/11.
#  Copyright 2011 Bearded. All rights reserved.
#

class TranscriptView < SearchView

  def awakeFromNib
    super
    @html_type = "transcript" 
  end
  
  def setTerm term, transcript = nil
    @term = term
    @transcript_name = transcript
    @breadcrumbView.delegate = @controller
    @breadcrumbView.setCrumbs breadcrumbs
  end
  
  def breadcrumbs
    crumbs = [{:title => "Search", :callback => "leaveTranscript:"}]
    crumbs << {:title => @term, :callback => "leaveTranscript:"} unless @term.nil?
    crumbs << {:title => @transcript_name, :callback => ""} unless @transcript_name.nil?
    
    crumbs
  end  

end