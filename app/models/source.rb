class Source < ActiveRecord::Base

    belongs_to :author
    has_many :snippets
    has_many :words, through: :snippets

end
