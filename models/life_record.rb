class LifeRecord < ActiveRecord::Base
  belongs_to :life_item
  before_save :check_rec_date_format
  after_save :update_life_item_total_minutes, :check_if_all_goal_of_today_completed
  after_destroy :update_life_item_total_minutes
  
  def update_life_item_total_minutes
    life_item = LifeItem.first( :conditions => ["id = ?", self.life_item_id], :include => :life_records )
    total_minutes = 0
    life_item.life_records.each { |r| total_minutes += r.used_minutes if r.is_not_goal != true and r.rec_date.to_s >= Param.find_by_name('life_rec_start_date').value }
    life_item.update_attribute( :total_minutes, total_minutes )
  end
  
  def check_rec_date_format
    self.rec_date = self.rec_date.to_date.to_s(:db).slice(0..9)
  end
  
  def check_if_all_goal_of_today_completed
	completed_goal_count = 0
    life_catalogs = LifeCatalog.all( :conditions => [ "goalable = ?", true] )
    life_catalogs.each { |c| completed_goal_count += 1 if remain_minutes_of_life_catalog(c.id)[:remain_minutes] <= 0 }
    add_date_to_all_goal_of_today_completed_data( self.rec_date ) if completed_goal_count == life_catalogs.size
  end
    
end
