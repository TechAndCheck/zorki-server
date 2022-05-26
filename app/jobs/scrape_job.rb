require "sidekiq/api"

class ScrapeJob < ApplicationJob
  sidekiq_options retry: 10
  queue_as :default

  sidekiq_retries_exhausted do |message, error|
    puts "Exhausted retries trying to scrape url #{message['arguments'].first}. Error: #{error}"
    Typhoeus.post("#{callback_url}/archive/scrape_result_callback",
                  headers: { "Content-Type": "application/json" },
                  body: { scrape_id: callback_id, scrape_result: "[]" })
  end

  def perform(url, callback_id = nil, callback_url = nil)
    # If there's no callback id or the callback url isn't set, then ignore this
    # Otherwise, send it back to the source
    return if callback_id.blank? || (Figaro.env.ZENODOTUS_URL.blank? && callback_url.blank?)

    results = MediaSource.scrape!(url, callback_id, callback_url)

    print "\nFinished scraping #{url}\n"
    print "\n********************\n"

    unless Figaro.env.AWS_REGION.blank?
      logger.debug "Beginning uploading of files to S3 bucket #{Figaro.env.AWS_S3_BUCKET_NAME}"
      logger.debugger "\n********************\n"
      results = results.map do |result|
        # Let's see if it's a video or images, and upload them
        if result.image_file_names.blank? == false
          aws_image_keys = result.image_file_names.map do |image_file_name|
            logger.debug "\nUploading #{image_file_name}\n"
            object = AwsObjectUploadFileWrapper.new(image_file_name)
            object.upload_file
            object.object.key
          end
          result.instance_variable_set("@aws_image_keys", aws_image_keys)
        elsif result.video_file_name.blank? == false
          object = AwsObjectUploadFileWrapper.new(result.video_file_name)
          object.upload_file
          result.instance_variable_set("@aws_video_key", object.object.key)
        end

        result
      end
      logger.debugger "\n********************\n"


      # TODO: Deal with video preview images too
    end

    print "Sending callback to #{callback_url}\n"
    print "\n********************\n"

    params = { scrape_id: callback_id, scrape_result: PostBlueprint.render(results) }

    Typhoeus.post("#{callback_url}/archive/scrape_result_callback",
        headers: { "Content-Type": "application/json" },
        body: params.to_json)
  rescue Zorki::RetryableError, Forki::RetryableError, YoutubeArchiver::RetryableError => e
    e.set_backtrace([])
    raise e
  rescue StandardError => e # If we run into an error retries can't fix, don't retry the job
    puts "#{e} for url #{url}"
  end
end
