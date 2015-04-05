$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dockyard'

require 'minitest/autorun'

class String
  def indent_heredoc
    gsub(/^#{scan(/^\s*/).min_by{|l|l.length}}/, "")
  end
end


class IntegrationTest < Minitest::Spec
  before do
    @namegen = FriendlyNamesGenerator.new
    @repo_names = []
    @container_names = []
  end

  def docker
    @docker ||= Dockyard::Docker.new do |config|
      config.use_plugin Dockyard::Boot2Docker.new
      config.verbose = true
    end
  end

  def gen_repo_name
    name = @namegen.gen_name
    @repo_names << name
    name
  end

  def gen_container_name
    name = @namegen.gen_name
    @container_names << name
    name
  end

  after do
    @repo_names.each do |name|
      docker.rm_image name
    end
  end
end

class FriendlyNamesGenerator

  def initialize
    adjective = %W{
      nostalgic
      morose
      hungry
      gaunt
      satisfied
      puzzled
      perplexed
      jumbo
      nebby
      yinz
      ham-barbecue
      studious
      erudite
      dandy
      slippy
      janky
    }
    subject = %W{
      bigfoot
      yetti
      bessie
      chupacabra
      goblin
      jersey-devil
      thunder-bird
      okapi
      mothman
      unicorn
      sewer-alligator
      spring-heeled-jack
      tahoe-tessie
      sasquatch
      yowie
      nessie
      jackelope
      dropbear
      hoop-snake
      wild-haggis
      snipe
    }
    @randoms = adjective.product(subject).shuffle

    @used = []
  end

  def gen_name
    if @randoms.length == 0
      raise "Ran out of random names!"
    end

    @randoms.shift.join "-"
  end
end
