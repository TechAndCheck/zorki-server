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
          :following_count

  field :profile_image do |user|
    to_return = nil
    unless user.profile_image_file_name.nil?
      file = File.open(user.profile_image_file_name).read
      to_return = Base64.encode64(file)
    end

    to_return
  end
end
