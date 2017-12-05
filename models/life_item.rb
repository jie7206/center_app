class LifeItem < ActiveRecord::Base
  belongs_to :life_catalog
  has_many :life_records, :dependent => :destroy
  after_save :update_life_catalog_total_minutes  #, :keep_max_value
  before_validation :ini_params
  
  def self.update_all_total_minutes
    life_items = all( :include => :life_records )
    life_items.each do |life_item|
      total_minutes = 0
      life_item.life_records.each { |r| total_minutes += r.used_minutes if r.rec_date.to_s >= Param.find_by_name('life_rec_start_date').value }
      life_item.update_attribute( :total_minutes, total_minutes )
    end
  end
  
  def update_life_catalog_total_minutes
  	exe_update_life_catalog_total_minutes [ self.life_catalog_id ]
  end
 
  def keep_max_value( cid_arr = [ 1, 9 ] )
    max_total_minutes = LifeCatalog.first( :conditions => ["goalable = ?", true], :order => "total_minutes desc" ).total_minutes
    cid_arr.each do |cid|    
      target_life_catalog  = LifeCatalog.find(cid)
      target_life_catalog.update_attribute( :weight, sprintf('%.3f', max_total_minutes.to_f / target_life_catalog.total_minutes) ) if target_life_catalog.total_minutes > 0
    end
  end    

  def ini_params
    self.order_num = 1 if not self.order_num
    self.total_minutes = 0 if not self.total_minutes
    self.is_goal = true if not self.is_goal
  end
      
end
