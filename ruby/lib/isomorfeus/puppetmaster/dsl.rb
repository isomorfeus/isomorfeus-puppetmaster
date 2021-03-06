module Isomorfeus
  module Puppetmaster
    module DSL
      def default_document
        @puppetmaster_default_document ||= get_default_document
      end

      def goto(uri)
        puppetmaster_session.document_goto(default_document, uri)
        @puppetmaster_default_document
      end
      alias_method :visit, :goto

      def on_server(ruby_source = '', &block)
        Isomorfeus::Puppetmaster.served_app.on_server(ruby_source, &block)
      end

      def open_new_session(app = nil, driver = nil)
        Isomorfeus::Puppetmaster.drivers[driver ? driver : Isomorfeus::Puppetmaster.driver].call(app ? app : Isomorfeus::Puppetmaster.served_app)
      end

      def open_new_document(uri = nil)
        puppetmaster_session.document_open_new_document(nil, uri)
      end

      def reset_session!
        @@puppetmaster_session = nil
      end

      private

      def get_default_document
        doc = puppetmaster_session.default_document
        return doc if doc
        puppetmaster_session.document_open_new_document('about:blank')
      end

      def puppetmaster_session
        @@puppetmaster_session ||= open_new_session(Isomorfeus::Puppetmaster.served_app)
      end

    end
  end
end
