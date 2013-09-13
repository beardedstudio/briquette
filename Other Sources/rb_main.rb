#
# rb_main.rb
# briquette
#
# Created by Dominic Dagradi on 10/23/10.
# Copyright Bearded 2010. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'Cocoa'

# Loading all the Ruby project files.
main = File.basename(__FILE__, File.extname(__FILE__))
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation

# Load JAListView bridge support file
load_bridge_support_file(File.join(dir_path,"JASectionedListView.bridgesupport"))

Dir.glob(File.join(dir_path, '*.{rb,rbo}')).map { |x| File.basename(x, File.extname(x)) }.uniq.each do |path|
  require path if path != main
end

# Starting the Cocoa main loop.
NSApplicationMain(0, nil)
