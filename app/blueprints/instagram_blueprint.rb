class InstagramBlueprint < Blueprinter::Base
  identifier :id

  fields  :id,
          :text,
          :date,
          :number_of_likes

  association :user, blueprint: UserBlueprint

  field :object_type do |post|
    "instagram"
  end

  field :image_files do |post|
    to_return = nil
    unless post.image_file_names.nil?
      to_return = post.image_file_names.map do |file_name|
        file = File.open(file_name).read
        Base64.encode64(file)
      end
    end

    to_return
  end

  field :video_file do |post|
    to_return = nil
    unless post.video_file_name.nil?
      file = File.open(post.video_file_name).read
      to_return = Base64.encode64(file)
    end

    to_return
  end

  field :video_preview_image do |post|
    to_return = nil
    unless post.video_preview_image.nil?
      file = File.open(post.video_preview_image).read
      to_return = Base64.encode64(file)
    end

    to_return
  end
end
