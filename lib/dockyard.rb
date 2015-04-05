# encoding: UTF-8
require "dockyard/version"

module Dockyard
  # Your code goes here...
  require 'pry'
  require 'open3'
  require 'json'

  class CLI
    # todo check cli version?

    def initialize opts={}
      @verbose = opts.fetch :verbose, false
    end

    def init_vars
      docker_running = ->{ /running/.match `boot2docker status 2>&1` }

      @initted ||=
        begin
          unless docker_running.call
            puts "boot2docker vm not running. attempting to start boot2docker..."
            `boot2docker up 2>&1`
            puts "rechecking..."
            if docker_running.call
              puts "successfully started boot2docker."
            else
              raise "Unable to start boot2docker; Aborting."
            end
          end

          `boot2docker shellinit 2>&1`
        end
    end

    def shell_init
      init_vars.split("\n").select {|it| it =~ /export /}
    end

    def env_vars
      @env_vars ||=
        begin
          env = shell_init.map { |export|
            data = export.match(/export (.*)=(.*)/)
            [data[1], data[2]]
          }
          Hash[env]
        end
    end

    def run(cmd, &block)
      if @verbose
        puts "RUN: #{cmd}"
      end
      Open3.popen3 env_vars, *cmd do |i, o, e, t|
        if block
          block.call i, o, e, t
        elsif @verbose
          puts "OUTPUT: #{o.read}"
          puts "EXIT: #{t.value}"
        end
      end
    end

    class GetImages
      def initialize(cli)
        @cli = cli
      end

      def call
        image_shas = @cli.run(%W{docker images -a}) {|i, o, e, t|
          o.read.split "\n"
        }[1..-1].map { |line|
          entries = line.split(/[[:space:]]+/)
          image_data = {
            :repository => entries[0],
            :tag => entries[1],
            :id => entries[2],
            :created => entries[3..5],
            :virtual_size => entries[6..7],
          };
          Docker::Image.new(image_data)
        }
      end
    end
  end

  class Docker
    class Config
      attr_reader :plugins
      attr_accessor :verbose
      def initialize
        @plugins = []
        @verbose = false
      end

      def use_plugin p
        @plugins << p
      end
    end

    def initialize
      @config = Config.new

      @cli = CLI.new

      yield @config
    end

    def run command, &block
      @cli.run command, &block
    end

    def build_image name, dockerfile
      run %W{docker build -t #{name} #{dockerfile}}
    end

    def images
      CLI::GetImages.new(self).call
    end

    def rm_image name
      run %W"docker rmi #{name}"
    end

    def create_container opts={}
      args = []

      if opts[:name]
        args << "--name"
        args << opts[:name]
      end

      if opts[:volume]
        args << "-v"
        args << opts[:volume]
      end

      if opts[:volumes_from]
        args << "--volumes-from"
        args << opts[:volumes_from]
      end

      args << opts.fetch(:image)

      docker.run %W"docker create -i --cidfile='./image.cid' #{args.join ' '}"
    end

    class Image
      attr_reader :repository, :tag, :id, :created, :virtual_size, :details

      def initialize(opts={})
        @repository = opts.fetch :repository
        @tag = opts.fetch :tag
        @id = opts.fetch :id
        @created = opts.fetch :created
        @virtual_size = opts.fetch :virtual_size
        @details = opts.fetch :details, {}
      end
    end
  end

  class Docker::Plugin
    def before_start
    end

    def after_start
    end

    def around_start
    end
  end

  class Boot2Docker < Docker::Plugin
  end
end

