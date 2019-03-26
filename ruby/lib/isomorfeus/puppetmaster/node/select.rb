module Isomorfeus
  module Puppetmaster
    class Select < Isomorfeus::Puppetmaster::Input

      class Option
        def select
          @driver.select(self)
        end

        def selected?
          !!self[:selected]
        end

        def unselect
          @driver.unselect(self)
        end
      end

      def select(option)
        # find option.select
      end

      def selected
        # find selected options
      end

      def selected?(option)
        # find option.selected?
      end

      def unselect
        # find option.unselect
      end
    end
  end
end