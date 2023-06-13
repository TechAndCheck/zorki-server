class FacebookUserBlueprint < Blueprinter::Base
  identifier :id

  fields  :profile_link,
          :name,
          :id,
          :profile,
          :number_of_followers,
          :number_of_likes,
          :verified,
          :profile_image_file,
          :profile_image_url,
          :aws_profile_image_key

  field :profile_image_file do |user|
    to_return = nil
    if user.profile_image_file.nil? == false && user.aws_profile_image_key.blank?
      File.open(user.profile_image_file) { |file| to_return = Base64.encode64(file.read) }
    end

    to_return
  end
end
