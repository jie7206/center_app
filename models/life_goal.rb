class LifeGoal < ActiveRecord::Base

	belongs_to :param
	before_validation :set_default
	validates_presence_of :title, :minutes, :message => '标题和分钟数不能空白!'
	validates_numericality_of :minutes, :message => '分钟数只能是數字!'

  def set_default
    self.order_num = LifeGoal.last.id.to_i+1 if not self.order_num
    self.completed_minutes = 0 if not self.completed_minutes
  end

end
