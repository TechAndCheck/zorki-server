class FacebookPostBlueprint < Blueprinter::Base
  identifier :url

  fields  :url,
          :text,
          :created_at,
          :num_comments,
          :num_views,
          :num_shares,
          :reactions,
          :id

  association :user, blueprint: UserBlueprint

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

