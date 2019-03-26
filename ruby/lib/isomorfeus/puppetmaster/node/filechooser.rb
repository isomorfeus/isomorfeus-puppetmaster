module Isomorfeus
  module Puppetmaster
    class Filechooser < Isomorfeus::Puppetmaster::Input
      def attach_file(file_path)
        @driver.attach_file(self, file_path)
      end
    end
  end
end