class LifeCatalog < ActiveRecord::Base
    has_many :life_items, :dependent => :destroy  
    before_validation :set_order_num

    def set_order_num
        self.order_num = 999 if not self.order_num
    end

    def total_goal_minutes
    	if use_life_catalog_goal_minutes?
    		return self.goal_minutes
		else
	        result = 0 
	        self.life_items.each { |life_item| result += life_item.goal_minutes if life_item.is_goal and life_item.goal_minutes.to_i > 0 }
	        return result
        end
    end

end
