module Signatory
  class Document < API::Base
    private
    def self.instantiate_record(record, opts = {})
      record['recipients'] = [record['recipients']['recipient']].flatten unless record['recipients'].nil? || record['recipients'].is_a?(Array)

      doc = super(record, opts)
      doc.recipients.each {|r| r.document = doc } if doc.respond_to?(:recipients)
      doc
    end
  end
end