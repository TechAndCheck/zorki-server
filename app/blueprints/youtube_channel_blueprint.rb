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
      file = File.open(channel.channel_image_file).read
      to_return = Base64.encode64(file)
    end

    to_return
  ensure
    file.close! unless file.nil? || file.closed? == false
  end
end
