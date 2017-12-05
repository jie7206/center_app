class Step < ActiveRecord::Base

    before_validation :set_order_num
    
    
    def set_order_num
        self.order_num = 999 if not self.order_num
    end
    
    def member_count_all
	    member_ids = []
	    member_ids_total = []
	    members = Member.all( :include => :trace, :conditions => [ "classification != '0'"] )
	    for member in members
	      member_ids << member.id if self.id == member.trace.last_step_id
	      member_ids_total << member.id if member.trace.steps.include?(self.id.to_s)
      end
      return member_ids.size.to_s + "/" + member_ids_total.size.to_s
    end

    def self.next_step_id( last_step_id )
      steps = all( :order => 'order_num' )
      return steps[0].id if !last_step_id or last_step_id == 0
      find_flag = false
      for step in steps
        return step.id if find_flag
        find_flag = (step.id == last_step_id) ? true : false
      end
      return 0
    end

    def self.next_step( last_step_id )
      next_step_id = Step.next_step_id(last_step_id)
      next_step_id > 0 ? Step.find(next_step_id).name.sub("已","") : ""
    end
    
end
