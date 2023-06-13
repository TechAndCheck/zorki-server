class FacebookPostBlueprint < Blueprinter::Base
  identifier :id

  fields  :url,
          :text,
          :created_at,
          :num_comments,
          :num_views,
          :num_shares,
          :reactions,
          :id

  association :user, blueprint: FacebookUserBlueprint

  field :image_file do |post|
    to_return = nil
    if post.image_file.nil? == false && post.aws_image_keys.blank?
      File.open(post.image_file) { |file| to_return = Base64.encode64(file.read) }
    end

    to_return
  end

  field :video_file do |post|
    to_return = nil
    if post.video_file.nil? == false && post.aws_video_key.blank?
      File.open(post.video_file) { |file| to_return = Base64.encode64(file.read) }
    end

    to_return
  end

  field :video_preview_image_file do |post|
    to_return = nil
    if post.video_preview_image_file.nil? == false && post.aws_video_preview_key.blank?
      File.open(post.video_preview_image_file) { |file| to_return = Base64.encode64(file.read) }
    end

    to_return
  end

  field :screenshot_file do |post|
    to_return = nil
    if post.aws_screenshot_key.blank?
      File.open(post.screenshot_file) { |file| to_return = Base64.encode64(file.read) }
    end

    to_return
  end

  field :aws_video_key do |post|
    post.aws_video_key()
  end

  field :aws_video_preview_key do |post|
    post.aws_video_preview_key()
  end


  field :aws_image_keys do |post|
    post.aws_image_keys()
  end

  field :aws_screenshot_key do |post|
    post.aws_screenshot_key()
  end
end
