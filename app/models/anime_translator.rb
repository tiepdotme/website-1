class AnimeTranslator < ApplicationRecord
  belongs_to :anime
  has_many :episodes
end
