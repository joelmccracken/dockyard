require 'minitest_helper'


class DockyardTest < IntegrationTest
  it "creates a new named image" do
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

