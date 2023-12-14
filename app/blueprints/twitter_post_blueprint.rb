class TwitterPostBlueprint < Blueprinter::Base
  identifier :id

  fields  :id,
          :text,
          :language,
          :created_at

  association :author, blueprint: TwitterUserBlueprint

  field :object_type do |tweet|
    "twitter"
  end

  field :image_files do |tweet|
    to_return = nil
    if tweet.image_file_names.nil? == false && tweet.aws_image_keys.blank?
      to_return = tweet.image_file_names.map do |file_name|
        base64_temp = nil
        File.open(file_name) { |file| base64_temp = Base64.encode64(file.read) }
        base64_temp
      end
    end

    to_return
  end

  field :video_file do |tweet|
    to_return = nil
    if tweet.video_file_names.empty? == false && tweet.aws_video_key.blank?
      base64_temp = nil
      File.open(tweet.video_file_names.first) { |file| base64_temp = Base64.encode64(file.read) }
      base64_temp
    end

    to_return
  end

  field :video_preview_image do |tweet|
    to_return = nil
    if tweet.video_file_names.empty? == false && tweet.aws_video_preview_key.blank?
      base64_temp = nil
      File.open(tweet.video_preview_image) { |file| base64_temp = Base64.encode64(file.read) }
      base64_temp
    end

    to_return
  end

  field :screenshot_file do |tweet|
    if tweet.aws_screenshot_key.blank?
      base64_temp = nil
      File.open(tweet.screenshot_file) { |file| base64_temp = Base64.encode64(file.read) }
      base64_temp
    end
  end

  field :aws_video_key do |tweet|
    tweet.aws_video_key()
  end

  field :aws_video_preview_key do |tweet|
    tweet.aws_video_preview_key()
  end

  field :aws_image_keys do |tweet|
    tweet.aws_image_keys()
  end

  field :aws_screenshot_key do |tweet|
    tweet.aws_screenshot_key()
  end
end
