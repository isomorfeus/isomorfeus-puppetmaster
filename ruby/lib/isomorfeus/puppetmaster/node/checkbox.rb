module Isomorfeus
  module Puppetmaster
    class Checkbox < Isomorfeus::Puppetmaster::Input
      def check
        @driver.check(self)
      end

      def checked?
        !!self[:checked]
      end

      def uncheck
        @driver.uncheck(self)
      end
    end
  end
end