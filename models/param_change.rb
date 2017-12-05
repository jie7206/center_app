class ParamChange < ActiveRecord::Base

	belongs_to :param
	before_validation :check_if_value_is_nil
	after_create :update_param_value
	after_update :if_newest_value_then_update
	# validates_numericality_of :change_value, :value, :only_integer => true, :message => '數值變化和當前數值的值只能是整數!'

	# 自动写入當前數值(value)的值
	def check_if_value_is_nil
		if Param.find(self.param_id).rec_change and !self.value or self.value.nil?
			self.value = Param.find(self.param_id).value.to_i + self.change_value.to_i
		end
	end

	def update_param_value
		Param.find(self.param_id).update_attribute(:value, self.value.to_i)
	end

	def if_newest_value_then_update
		update_param_value if ParamChange.last(:conditions => ["param_id=?",self.param_id]).id == self.id
	end

end
