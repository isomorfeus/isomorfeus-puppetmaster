module Isomorfeus
  module Puppetmaster
    class Radiobutton < Isomorfeus::Puppetmaster::Input
      def choose
        @driver.choose(self)
      end

      def chosen?
        @driver.chosen?(self)
      end
    end
  end
end