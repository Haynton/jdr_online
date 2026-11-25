# The picture of an account or of a character, stored by Active Storage (on disk locally, Cloudinary in production).
# The page frames it and shrinks it to a square of 384 px before sending it (avatar_cropper_controller.js); without
# JavaScript, the picture is sent as it is, hence the 2 MB, and the page crops its centre.
# Changing it only checks the picture: the rest of the record is saved as it was, even if it would no longer pass
# its own validations (a sheet made with an older template)
module HasAvatar
  extend ActiveSupport::Concern

  AVATAR_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  AVATAR_MAX_SIZE = 2.megabytes

  included do
    has_one_attached :avatar
  end

  def change_avatar(file)
    errors.clear
    self.avatar = file if file.present?
    check_avatar(file)
    errors.none? && save(validate: false)
  end

  def remove_avatar
    avatar.purge if avatar.attached?
  end

  private

  def check_avatar(file)
    return errors.add(:avatar, :blank) if file.blank?

    errors.add(:avatar, :content_type) unless AVATAR_CONTENT_TYPES.include?(avatar.blob.content_type)
    errors.add(:avatar, :too_big, count: AVATAR_MAX_SIZE / 1.megabyte) if avatar.blob.byte_size > AVATAR_MAX_SIZE
  end
end
