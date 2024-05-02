# This will error out, but we can see it! so it's fine
Rails.logger.info "********************************************************************"
Rails.logger.info "Sending check-in to Grigori"
request = Typhoeus::Request.new("https://10.211.55.2:4000/tests_completed",
ssl_verifypeer: false, # This is to avoid SSL verification error
ssl_verifyhost: 0, # This is to avoid SSL verification error
headers: { "Content-Type": "application/json" },
method: :post,
body: { vm_id: ENV["VM_NAME"], status_code: 100, status_message: "Successfully booted" }.to_json)

request.run
# response = request.response

Rails.logger.info "Check-in sent. Response Code: #{request.response.code}"
Rails.logger.info "********************************************************************"
