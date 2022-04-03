class YoutubeVideoBlueprint < Blueprinter::Base
  identifier :id

  fields  :title,
          :created_at,
          :language,
          :duration,
          :num_views,
          :num_likes,
          :num_comments,
          :live,
          :video_preview_image_file,
          :video_file,
          :made_for_kids

  association :channel, blueprint: YoutubeChannelBlueprint

  field :video_preview_image_file do |video|
    unless video.video_preview_image_file.nil?
      file = File.open(video.video_preview_image_file).read
      Base64.encode64(file)
    end
  end

  field :video_file do |video|
    unless video.video_file.nil?
      file = File.open(video.video_file).read
      Base64.encode64(file)
    end
  end
end

