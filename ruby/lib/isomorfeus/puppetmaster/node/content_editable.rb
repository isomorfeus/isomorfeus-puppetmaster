module Isomorfeus
  module Puppetmaster
    class ContentEditable < Isomorfeus::Puppetmaster::Node
      node_forward %i[
                      disabled?
                      value
                      value=
                   ]

      def readonly?
        !!self[:readOnly]
      end

      alias_method :text, :value
      alias_method :text=, :value=
    end
  end
end