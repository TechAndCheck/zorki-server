class UserBlueprint < Blueprinter::Base
  identifier :name
  fields :name

  field :user do |user|
    to_return = nil

    case user.class.to_s # This is converted to a string because apparently comparing classes breaks
    when "Forki::User"
      to_return = FacebookUserBlueprint.render_as_hash(user)
    when "Zorki::User"
      to_return = InstagramUserBlueprint.render_as_hash(user)
    else
      raise "Unsupported class for a user passed into UseBlueprint"
    end

    to_return
  end
end
