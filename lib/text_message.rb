# frozen_string_literal: true

require_relative '../secrets' # The constants below must be specified in secrets.rb

class TextMessage
  def initialize
    raise ArgumentError, "Recipient phone numbers must be specified" unless ENV['PHONE_NUMBERS'].present?

    @client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_AUTH_TOKEN)
    @phone_numbers = ENV['PHONE_NUMBERS'].split(',').map(&:strip)
  end

  def send(body:)
    @phone_numbers.each do |number|
      @client.messages.create(
        from: TWILIO_NUMBER,
        to: number,
        body: body
      )
    end
  end
end
