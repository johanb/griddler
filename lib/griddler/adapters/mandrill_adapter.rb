module Griddler
  module Adapters
    class MandrillAdapter
      def initialize(params)
        @params = params
      end

      def self.normalize_params(params)
        adapter = new(params)
        adapter.normalize_params
      end

      def normalize_params
        events.map do |event|
          {
            to: recipients(event),
            from: event[:from_email],
            subject: event[:subject],
            text: event[:text],
            html: event[:html],
            raw_body: event[:raw_msg],
            attachments: attachment_files(event),
            charsets: extract_charsets(event)
          }
        end
      end

      private

      attr_reader :params

      def events
        @events ||= ActiveSupport::JSON.decode(params[:mandrill_events]).collect do |event|
          event['msg'].with_indifferent_access
        end
      end

      def recipients(event)
        event[:to].map { |recipient| full_email(recipient) }
      end

      def full_email(contact_info)
        email = contact_info[0]
        if contact_info[1]
          "#{contact_info[1]} <#{email}>"
        else
          email
        end
      end

      def extract_charsets(event)
        mail = Mail.read_from_string event[:raw_msg]
        if !mail.parts.empty?
          charsets = { 'html' => 'binary', 'text' => 'binary' }
          charsets.keys.each do |type|
            if part = find_part_type(mail, type)
              charsets[type] = part.content_type_parameters['charset']
            end
          end
          ActiveSupport::JSON.encode charsets
        else
          nil
        end
      end

      def find_part_type(mail, type)
        types = {
          'html' => /^text\/html/,
          'text' => /^text\/plain/
        }
        mail.parts.find {|p| p.content_type =~ types.fetch(type) }
      end

      def attachment_files(event)
        attachments = event[:attachments] || Array.new
        attachments.collect do |key, attachment|
          ActionDispatch::Http::UploadedFile.new({
            filename: attachment[:name],
            type: attachment[:type],
            tempfile: create_tempfile(attachment)
          })
        end
      end

      def create_tempfile(attachment)
        filename = attachment[:name]
        tempfile = Tempfile.new(filename, Dir::tmpdir, encoding: 'ascii-8bit')
        tempfile.write(Base64.decode64(attachment[:content]))
        tempfile.rewind
        tempfile
      end
    end
  end
end
