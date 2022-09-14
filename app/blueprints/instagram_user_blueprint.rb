class InstagramUserBlueprint < Blueprinter::Base
  identifier :username

  fields  :name,
          :username,
          :number_of_posts,
          :number_of_followers,
          :number_of_following,
          :verified,
          :profile,
          :profile_link,
          :profile_image,
          :profile_image_url,
          :aws_profile_image_key

  field :profile_image do |user|
    to_return = nil
    if user.profile_image.nil? == false && user.aws_profile_image_key.blank?
      file = File.open(user.profile_image).read
      to_return = Base64.encode64(file)
    end

    to_return
  end
end
