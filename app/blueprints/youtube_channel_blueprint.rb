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
          :channel_image_file

  field :channel_image_file do |channel|
    unless channel.channel_image_file.nil?
      file = File.open(channel.channel_image_file).read
      Base64.encode64(file)
    end
  end

end

