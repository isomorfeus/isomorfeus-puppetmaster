module Isomorfeus
  module Puppetmaster
    module SelfForwardable
      def self.extended(base)
          base.define_singleton_method(:document_forward) do |methods|
            methods.each do |method|
              define_method(method) do |*args, &block|
                @driver.send("document_#{method}", self, *args, &block)
              end
            end
          end

          base.define_singleton_method(:frame_forward) do |methods|
            methods.each do |method|
              define_method(method) do |*args|
                @driver.send("frame_#{method}", self, *args)
              end
            end
          end

          base.define_singleton_method(:node_forward) do |methods|
            methods.each do |method|
              define_method(method) do |*args|
                @driver.send("node_#{method}", self, *args)
              end
            end
          end
      end
    end
  end
end