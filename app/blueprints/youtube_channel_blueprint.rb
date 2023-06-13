class YoutubeChannelBlueprint < Blueprinter::Base
  identifier :id

  fields  :id,
          :title,
          :created_at,
          :video_count,
          :subscriber_count,
          :view_count,
          :description,
          :made_for_kids,
          :channel_image_file,
          :aws_profile_image_key

  field :channel_image_file do |channel|
    to_return = nil
    if channel.channel_image_file.nil? == false && channel.aws_profile_image_key.blank?
      File.open(channel.channel_image_file) { |file| to_return = Base64.encode64(file.read) }
    end

    to_return
  end
end
