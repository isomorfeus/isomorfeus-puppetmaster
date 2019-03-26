module Isomorfeus
  module Puppetmaster
    class Iframe < Isomorfeus::Puppetmaster::Node

      frame_forward %i[
                      body
                      focus
                      head
                      html
                      title
                      url
                      visible_text
                    ]

    end
  end
end