class Asset < ActiveRecord::Base
  has_many :asset_items, :dependent => :destroy
end
