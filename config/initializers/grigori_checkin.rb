# This will error out, but we can see it! so it's fine
logger.info "Sending check-in to Grigori"
request = Typhoeus::Request.new("http://10.211.55.2:2345/tests_completed",
headers: { "Content-Type": "application/json" },
method: :post,
body: { vm_id: ENV["VM_NAME"], status_code: status_code, status_message: status_message }.to_json)

request.run
# response = request.response

logger.info "Check-in sent"
logger.debug(request.response)
