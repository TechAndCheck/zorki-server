class UserBlueprint < Blueprinter::Base
  identifier :username

  fields  :name,
          :number_of_posts,
          :number_of_followers,
          :number_of_following,
          :verified,
          :profile,
          :profile_link,
          :profile_image,
          :profile_image_url

  field :profile_image do |user|
    to_return = nil
    unless user.profile_image.nil?
      file = File.open(user.profile_image).read
      to_return = Base64.encode64(file)
    end

    to_return
  end
end
