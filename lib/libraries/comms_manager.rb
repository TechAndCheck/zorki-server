class CommsManager
  def self.send_boot_checkin
    # This will error out, but we can see it! so it's fine
    Rails.logger.info "********************************************************************"
    Rails.logger.info "Sending check-in to Grigori"
    request = Typhoeus::Request.new("#{Figaro.env.GRIGORI_CALLBACK_URL}/api/scraper/#{ENV["VM_NAME"]}/status_update",
    ssl_verifypeer: false, # This is to avoid SSL verification error
    ssl_verifyhost: 0, # This is to avoid SSL verification error since the self-signed cert is for 0.0.0.0
    timeout: 2, # This will be very quick normally, but when we're testing it'll hang for like 30 seconds otherwise
    headers: { "Content-Type": "application/json" },
    method: :post,
    body: { scraper: { vm_id: ENV["VM_NAME"], status: { code: 100, message: "Successfully booted" } } }.to_json)

    request.run
    # response = request.response

    Rails.logger.info "Check-in sent. Response Code: #{request.response.code}"
    Rails.logger.info "********************************************************************"
  end

  # Other things to send
  # - Scrape Status update
  # - Scrape Result
  # - Scrape Error
  # - Scrape Retry
  # - Scrape Retry Exhausted
  # - Scrape Retry Exhausted with Error
  # - Scraper shutting down

  def self.send_scrape_status_update(vm_id, status_code, body)
    Rails.logger.info "********************************************************************"
    Rails.logger.info "Sending status update to Grigori"
    request = Typhoeus::Request.new("#{Figaro.env.GRIGORI_CALLBACK_URL}/api/scraper/#{vm_id}/status_update",
    ssl_verifypeer: false, # This is to avoid SSL verification error
    ssl_verifyhost: 0, # This is to avoid SSL verification error since the self-signed cert is for

    headers: { "Content-Type": "application/json" },
    method: :post,
    body: { scraper: { vm_id: vm_id, status: { code: status_code, body: body } } }.to_json)

    request.run

    Rails.logger.info "Status update sent. Response Code: #{request.response.code}"
    Rails.logger.info "********************************************************************"
  end
end
