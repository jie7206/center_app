class Course < ActiveRecord::Base
  
    before_validation :set_order_num
    
    def set_order_num
        self.order_num = 999 if not self.order_num
    end
    
end
