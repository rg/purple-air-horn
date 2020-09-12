# frozen_string_literal: true

require_relative '../secrets' # The constants below must be specified in secrets.rb

class TextMessage
  def initialize
    @client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_AUTH_TOKEN)
  end

  def send(body:)
    DISTRIBUTION_LIST.each do |number|
      @client.messages.create(
        from: TWILIO_NUMBER,
        to: number,
        body: body
      )
    end
  end
end
