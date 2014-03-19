class Author < ActiveRecord::Base
    has_many :sources
    has_many :snippets, through: :sources
end
