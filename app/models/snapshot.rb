class Snapshot < ApplicationRecord
  belongs_to :project
  serialize :table, JSON
end
