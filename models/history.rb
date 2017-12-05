class History < ActiveRecord::Base
  belongs_to :member
  validates_presence_of :class_date, :class_teacher, :class_title, :message=> '日期、老师和标题不能空白!'

  def self.class_count_by_area_and_type( area_id, class_type )
  	count( :conditions => [ "area_id = ? and class_type = ?", area_id, class_type ] )
  end

  def self.class_count_by_months_and_area_and_type( num_month_ago, area_id, class_type )
  	count( :conditions => [ "area_id = ? and class_type = ? and class_date >= ?", area_id, class_type, (Time.now-(num_month_ago.to_i).month).strftime("%Y-%m-01") ] )
  end

  def self.class_count_by_teacher_and_area_and_type( class_teacher, area_id, class_type )
  	count( :conditions => [ "area_id = ? and class_type = ? and class_teacher = ? and name != ?", area_id, class_type, class_teacher, class_teacher ] )
  end

end
