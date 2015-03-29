require 'minitest_helper'

describe "docker" do
  let(:collection) {
    Dockyard::Docker::Collection.new
  }

  def docker
    @docker ||= Dockyard::Docker.new do |config|
      config.use_plugin Dockyard::Boot2Docker.new
      config.verbose = true
    end
  end

  after do
    collection.images.each do |image|
      docker.rm_image image
    end
  end

  it "creates a new image" do
    Dir.mktmpdir do |dir|
      dockerfile = File.join(dir, "Dockerfile")
      File.write(dockerfile, <<-EOF.indent_heredoc)
          FROM busybox
          RUN echo A TEST STRING > /foobar
        EOF

      image = collection.gen_image
      docker.build_image image, dir
      docker.images_names.must_include ""
    end
  end
end

