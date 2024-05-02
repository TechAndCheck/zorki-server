# This will error out, but we can see it! so it's fine
Rails.logger.info "********************************************************************"
Rails.logger.info "Sending check-in to Grigori"
request = Typhoeus::Request.new("http://10.211.55.2:2345/tests_completed",
headers: { "Content-Type": "application/json" },
method: :post,
body: { vm_id: ENV["VM_NAME"], status_code: 100, status_message: "Successfully booted" }.to_json)

request.run
# response = request.response

Rails.logger.info "Check-in sent. Response Code: #{request.response.code}"
Rails.logger.info "********************************************************************"
