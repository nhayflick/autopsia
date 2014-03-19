class Word < ActiveRecord::Base
    has_many :snippets
    has_many :sources, through: :snippets
end
