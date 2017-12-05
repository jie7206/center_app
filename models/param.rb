class Param < ActiveRecord::Base

	has_many :param_changes
	has_many :life_goals
	validates_uniqueness_of :name, :on => :create, :message => "參數名稱不可以重複!"
	before_destroy :cant_destroy_id_in_using

	def cant_destroy_id_in_using
		if rec_change
			raise "无法删除帶有記錄變化的參數!"
		end
	end

	def get_life_interests_str
		result = ''
		if self.content.include?(',') or self.content.to_i > 0
			self.content.split(',').each do |num|
				p = Param.find_by_name('life_interest_'+num)
				result += trip_title(p.title) + p.value + '分，'
			end
		end
		return result[0..-2]
	end

end
