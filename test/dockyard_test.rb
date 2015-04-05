require 'minitest_helper'


class DockyardTest < IntegrationTest
  it "creates a new named image" do
    Dir.mktmpdir do |dir|
      dockerfile = File.join(dir, "Dockerfile")
      File.write(dockerfile, <<-EOF.indent_heredoc)
        FROM busybox
        RUN echo A TEST STRING > /foobar
      EOF

      repo = gen_repo_name
      docker.build_image repo, dir
      images = docker.images

      assert images.find {|img| img.repository == repo }, "image was not found"
    end
  end
end

