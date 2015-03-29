$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dockyard'

require 'minitest/autorun'

class String
  def indent_heredoc
    gsub(/^#{scan(/^\s*/).min_by{|l|l.length}}/, "")
  end
end
