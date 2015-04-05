# encoding: UTF-8
require "dockyard/version"

module Dockyard
  # Your code goes here...
  require 'pry'
  require 'open3'
  require 'json'

  class DockerGateway
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
      Open3.popen3 env_vars, *cmd, &block
    end

    class GetImages
      def initialize(cli)
        @cli = cli
      end

      def call
        image_shas = @cli.run(%W{docker images -a}) do |i, o, e, t|
          o.read.split "\n"
        end

        json = @cli.run(%W{docker inspect} + image_shas) do |_in, _out, _err, thread|
          tmp = _out.read.force_encoding(Encoding::UTF_8)
          JSON.parse(tmp)
        end

        json.map { |record|
          Image.new(record)
        }

        `docker images -a`.split("\n")[1..-1].map {|x| x.split(/[[:space:]]+/) }
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

      @cli = DockerGateway.new

      yield @config
    end

    def run command, &block
      puts "DOCKER RUN: #{command}"
      @cli.run command, &block
    end

    def build_image name, dockerfile
      run %W{docker build -t #{name} #{dockerfile}}
    end

    def images_names
      DockerGateway::GetImages.new(self).call
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
      def initialize(opts={})
        @repoitory = opts.fetch :repository
        @tag = opts.fetch :tag
        @inspect_details = opts.fetch :details
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

