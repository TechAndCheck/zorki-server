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
        file = File.open(file_name).read
        Base64.encode64(file)
      end
    end

    to_return
  end

  field :video_file do |tweet|
    to_return = nil
    if tweet.video_file_names.empty? == false && tweet.aws_video_key.blank?
      file = File.open(tweet.video_file_names.first.first[:url]).read
      to_return = Base64.encode64(file)
    end

    to_return
  end

  field :video_preview_image do |tweet|
    to_return = nil
    if tweet.video_file_names.empty? == false && tweet.aws_video_preview_key.blank?
      file = File.open(tweet.video_file_names.first.first[:preview_url]).read
      to_return = Base64.encode64(file)
    end

    to_return
  end

  field :screenshot_file do |tweet|
    if tweet.aws_screenshot_key.blank?
      file = File.open(tweet.screenshot_file).read
      Base64.encode64(file)
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
