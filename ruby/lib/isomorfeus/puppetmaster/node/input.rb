module Isomorfeus
  module Puppetmaster
    class Input < Isomorfeus::Puppetmaster::Node
      node_forward %i[
                      disabled?
                      value
                      value=
                   ]

      attr_accessor :type

      def multiple?
        !!self[:multiple]
      end

      def readonly?
        !!self[:readOnly]
      end
    end
  end
end