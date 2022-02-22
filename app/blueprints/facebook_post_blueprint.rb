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
    unless post.image_file.nil?
      file = File.open(post.image_file).read
      Base64.encode64(file)
    end
  end

  field :video_file do |post|
    unless post.video_file.nil?
      file = File.open(post.video_file).read
      Base64.encode64(file)
    end
  end

  field :video_preview_image_file do |post|
    unless post.video_preview_image_file.nil?
      file = File.open(post.video_preview_image_file).read
      Base64.encode64(file)
    end
  end
end
