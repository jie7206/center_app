class Trace < ActiveRecord::Base
  
    belongs_to :member
    before_validation :set_default_teacher
    
    def set_default_teacher
        self.last_class_teacher = '未指定' if self.last_class_teacher && self.last_class_teacher.empty?
        self.next_class_teacher = '未指定' if self.next_class_teacher && self.next_class_teacher.empty?
    end
      
    def steps
      step_ids ? step_ids.split(",") : []
    end
    
    def last_step_name 
      step_ids ? Step.find(steps.last.to_i).name : ""
    end

    def next_step_name
      step_ids ? Step.next_step( last_step_id ) : ""
    end

    def last_step_id
      step_ids ? steps.last.to_i : 0
    end

    def next_step_id
      step_ids ? Step.next_step_id( last_step_id ) : 0
    end
    
end
