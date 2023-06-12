class TwitterUserBlueprint < Blueprinter::Base
  identifier :username

  fields  :name,
          :username,
          :id,
          :created_at,
          :description,
          :url,
          :profile_image_url,
          :location,
          :followers_count,
          :following_count,
          :aws_profile_image_key

  field :profile_image do |user|
    to_return = nil
    if user.profile_image_file_name.nil? == false && user.aws_profile_image_key.blank?
      file = File.open(user.profile_image_file_name).read
      to_return = Base64.encode64(file)
    end

    to_return
  ensure
    file.close! unless file.nil? || file.closed? == false
  end
end
