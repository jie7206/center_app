require 'functions'

class Member < ActiveRecord::Base
    
    has_one :trace, :dependent => :destroy
    has_one :account, :dependent => :destroy
    has_many :histories, :dependent => :destroy
    has_many :questions, :dependent => :destroy
    has_many :pay_logs, :dependent => :destroy
    has_many :donations, :dependent => :destroy
    before_validation :set_order_num, :check_blessing_number
    after_create :create_trace, :correct_father_id
    
    def total_points
        History.find_by_sql("select sum(points) as total_points from histories where member_id = #{id} and is_passed = 't'")[0].total_points
    end
    
    def get_picture
        picture && picture.index('.') ? picture : 'blank.jpg'
    end
    
    def get_conductor
       if conductor_id
         conductor = Member.first( :conditions => [ "id = ?", conductor_id] )
         if conductor
           return conductor.name
         else
          return '未知'
        end
      else
        return '未知'
      end        
    end

    def get_introducer
       if introducer_id
         introducer = Member.first( :conditions => [ "id = ?", introducer_id] )
         if introducer
           return introducer.name
         else
          return '未知'
        end
      else
        return '未知'
      end
    end
    
    def get_introducer_id
       if introducer_id
         introducer = Member.first( :conditions => [ "id = ?", introducer_id] )
         if introducer
           return introducer.id
         else
          return 0
        end
      else
        return 0
      end      
    end
    
    def get_birthday
      if birthday_still_unknow
        return birthday ? birthday.strftime("%Y") : Time.now.strftime("%Y")
      else
        return birthday.strftime("%Y-%m-%d")
      end
    end

    def get_birthday_short
       birthday_still_unknow ? '' : birthday.strftime("%m-%d")
    end
    
    def get_age
      Time.now.year.to_i - get_birthday.to_s[0,4].to_i
    end
    
    def correct_father_id
      Member.update_all( "father_id = 0", "father_id is null" )
    end
    
    def create_trace
        Trace.create(
                    :member_id => id, 
                    :status_num => 0, 
                    :last_class_date => Time.now, 
                    :next_class_date => Time.now, 
                    :last_class_title => '',
                    :next_class_title => '',
                    :star_level => '1.0' )
    end
    
    def histories_count
      History.count( :conditions => "member_id = #{id}")      
    end

    # 取出最近一堂课的资料(不受traces更新顺序的影响，因为有时候补过去的资料而造成错误)
    def get_last_class
      return History.first( :order => 'class_date desc', :conditions => ["member_id = ?", id] )
    end

    # 统计该会员每月參加公活動的次数
    def histories_count_month
      History.count( :conditions => [ "member_id = ? and is_public_class = ? and class_date >= ?", id, true, (Time.now-1.month).to_s(:db) ] )
    end

    # 统计该会员每3個月參加公活動的次数
    def histories_count_3month
      History.count( :conditions => [ "member_id = ? and is_public_class = ? and class_date >= ?", id, true, (Time.now-3.month).to_s(:db) ] )
    end

    # 统计该会员每6個月參加公活動的次数
    def histories_count_6month
      History.count( :conditions => [ "member_id = ? and is_public_class = ? and class_date >= ?", id, true, (Time.now-6.month).to_s(:db) ] )
    end     

    # 如果是祝福会员，必须提供祝福对数(blessing_number)，否则家庭报表会出错
    def check_blessing_number
      # 如果是祝福会员，但是没有祝福对数(blessing_number)的值
      if self.career == '0' and !self.blessing_number
        errors.add(:blessing_number, "如果是祝福会员，必须提供祝福的对数，否则家庭报表会出错！" ); return false
      end
    end

    def set_order_num
      self.order_num = 999 if not self.order_num
    end
    
    #回传灵或肉子女的个数
    def children_count
      num = Member.count( :conditions => [ "introducer_id = ?", id ] )
      if num < 1 and spouse_id
        num = Member.count( :conditions => [ "introducer_id = ?", spouse_id ] )
      end
      return num
    end

    #回传该会员的奉献次数(资料笔数)
    def donation_total_times
      Donation.total_times( id )
    end

    #回传该会员的奉献总额
    def donation_total_amount
      Donation.total_amount( id )
    end

    #回传该会员几个月内的奉献总额(预设回传本季度的总额)
    def donation_total_amount_recently( month_num = 3 )
      Donation.total_amount( id, month_num )
    end    

    # 回传该会员奉献的年度平均(有误,占时不用)
    def donation_month_ave_in_this_year
      Donation.month_ave_in_this_year( id )
    end

    # 回传该会员奉献的年度平均
    def donation_month_ave
      Donation.month_ave( id )
    end

    # 回传该会员的奉献次数(预设3个月内)
    def donated_count( month_num = 3 )
        count = Donation.total_times_in_months( id, month_num )
        if spouse_id and spouse_id > 0
          return count + Donation.total_times_in_months( spouse_id, month_num )
        end
        return count
    end

    # 回传该会员的半年内的奉献次数
    def donated_count_6months
        return donated_count 6
    end

    # 是否为新进会员(入会日在这个月)
    def is_new_member
      if spiritual_birthday and !spiritual_birthday.empty?
        sdate = spiritual_birthday.to_date
        today = Date.today
        if sdate.year == today.year and sdate.month == today.month
          return true
        end
      end
      return false
    end

    # 是否为奉獻会员(0-18歲可不計算奉獻,19歲以上:有做什一奉獻(家庭為單位))
    def is_donated
      # 该会员半年内的奉献总额 > 0
      if donation_total_amount_recently > 0
        return true
      # 该会员配偶半年内的奉献总额 > 0
      elsif spouse_id and spouse_id > 0 and Member.find(spouse_id).donation_total_amount_recently > 0
        return true
      else
        return false
      end
    end

    def star_level
      trace.star_level
    end

    def last_class_date
      trace.last_class_date
    end

    def self.get_team_members( conductor_id )
      result = [ conductor_id ]
      members = all( :conditions => [ "conductor_id = ? or introducer_id = ?", conductor_id, conductor_id ] )
      if members
        return result + members.map { |m| m.id }
      else
        return result
      end
    end
        
    def self.find_by_step( step_id )
      member_ids = []
      members = all( :include => :trace, :conditions => [ "classification != '0'"] )
      for member in members
        member_ids << member.id if step_id.to_i == member.trace.last_step_id
      end
      find_by_sql("select * from members where id in (#{member_ids.join(',')})")
    end
    
    def self.find_by_next_step( next_step_id )
      member_ids = []
      members = all( :include => :trace, :conditions => [ "classification != '0'"] )
      for member in members
        member_ids << member.id if next_step_id.to_i == member.trace.next_step_id
      end
      find_by_sql("select * from members where id in (#{member_ids.join(',')})")
    end    

    def self.all_pass_steps( step_id )
      member_ids = []
      members = all( :include => :trace, :conditions => [ "classification != '0'"] )
      for member in members
        member_ids << member.id if member.trace.steps.include?(step_id)
      end
      find_by_sql("select * from members where id in (#{member_ids.join(',')})")
    end
    
    def self.all_on_table
      all( :include => :trace, :conditions => [ "is_on_table = ? and classification != '0'", true] )
    end
    
    def self.sum_by_cid( cid )
      count( :conditions => sum_by_cid_select( cid ) )
    end

    def self.sum_by_cid_and_aid( cid, aid )
      count( :conditions => sum_by_cid_and_aid_select( cid, aid ) )
    end

    def self.total_local_count( aid )
      count( :conditions => total_local_count_select( aid ) )
    end
 
    def self.total_local_effect_count( aid )
      count( :conditions => total_local_effect_count_select( aid ) )
    end

    def self.total_local_leader_count( aid )
      count( :conditions => total_local_leader_count_select( aid ) )
    end
    
    def self.total_local_staff_count( aid )
      count( :conditions => total_local_staff_count_select( aid ) )
    end
    
    def self.total_local_family_count( aid )
      find_blessed_family( aid ).size
    end

    def self.total_local_core_family_count( aid )
      count( :conditions => total_local_core_family_count_select( aid ) )
    end

    def self.db_total_count
      count( :conditions => db_total_count_select )
    end
    
    def self.total_count
      count( :conditions => total_count_select )
    end

    def self.total_local_g21_count( aid )
      members = all( :conditions => [ "career = ? and area_id = ?", 5, aid ] )
      num = 0
      members.each do |m|
        if m.get_age >= g2_age_arr[0][0] and m.get_age <= g2_age_arr[0][1]
          num = num + 1
        end
      end
      return num
    end

    def self.total_local_g22_count( aid )
      members = all( :conditions => [ "career = ? and area_id = ?", 5, aid ] )
      num = 0
      members.each do |m|
        if m.get_age >= g2_age_arr[1][0] and m.get_age <= g2_age_arr[1][1]
          num = num + 1
        end
      end
      return num
    end

    def self.total_local_g23_count( aid )
      members = all( :conditions => [ "career = ? and area_id = ?", 5, aid ] )
      num = 0
      members.each do |m|
        if m.get_age >= g2_age_arr[2][0] and m.get_age <= g2_age_arr[2][1]
          num = num + 1
        end
      end
      return num
    end

    def self.total_local_supporters_count( aid ) 
      count( :conditions => [ "classification = ? and area_id = ?", 4, aid ] )
    end

    def self.total_local_blessedable_count( aid )
      count( :conditions => total_local_blessedable_count_select( aid ) )
    end

    def self.get_local_g21_records( aid )
      members = all( :conditions => [ "career = ? and area_id = ?", 5, aid ] )
      result = []
      members.each do |m|
        if m.get_age >= g2_age_arr[0][0] and m.get_age <= g2_age_arr[0][1]
          result << m
        end
      end
      return result
    end

    def self.get_local_g22_records( aid )
      members = all( :conditions => [ "career = ? and area_id = ?", 5, aid ] )
      result = []
      members.each do |m|
        if m.get_age >= g2_age_arr[1][0] and m.get_age <= g2_age_arr[1][1]
          result << m
        end
      end
      return result
    end

    def self.get_local_g23_records( aid )
      members = all( :conditions => [ "career = ? and area_id = ?", 5, aid ] )
      result = []
      members.each do |m|
        if m.get_age >= g2_age_arr[2][0] and m.get_age <= g2_age_arr[2][1]
          result << m
        end
      end
      return result
    end

    def self.get_local_supporter_records( aid )
      all( :conditions => [ "classification = ? and area_id = ?", 4, aid ] )
    end

    def self.is_on_table_count
      count( :conditions => is_on_table_count_select )
    end

    def self.is_brother_count( aid )
      count( :conditions => is_brother_count_select( aid ) )
    end
    
    def self.find_blessed_family( aid, order_str = 'members.name' )
      result = all( :order => order_str, :include => :trace, :conditions => total_local_family_count_select( aid ) )
      female_members = all( :order => order_str, :include => :trace, :conditions => [ "sex_id = ? and career = '0' and area_id = ?", 0, aid ] )
      female_members.each do |m|
        if m.spouse_id and m.spouse_id > 0
          if find(m.spouse_id).area_id.to_i != aid.to_i
            result << m
          end
        end
      end
      return result
    end

    def self.find_core_blessed_family( aid )
      all( :include => :trace, :order => 'traces.last_class_date', :conditions => total_local_core_family_count_select( aid ) )
    end

    def self.find_core_members( aid )
      all( :include => :trace, :order => 'traces.last_class_date desc', :conditions => total_local_core_members_count_select( aid ) )
    end

    def self.find_single_members( aid )
      all( :order => default_order_for_member_list, :include => :trace, :conditions => total_local_single_members_count_select( aid ) )
    end

    def self.find_disconnect_members( aid )
      all( :include => :trace, :order => 'career', :conditions => total_local_disconnect_members_count_select( aid ) )
    end

    def self.total_core_members_count( aid )
      count( :conditions => total_local_core_members_count_select( aid ) )
    end    

    def self.total_disconnect_members_count( aid )
      count( :conditions => total_local_disconnect_members_count_select( aid ) )
    end    
    
    def self.total_single_members_count( aid )
      count( :conditions => total_local_single_members_count_select( aid ) )
    end

    # 新人
    def self.find_new( aid )
      all( :order => default_order_for_member_list, :include => :trace, :conditions => total_local_new_count_select( aid ) )
    end

    # 新人总计
    def self.total_new_count( aid )
      count( :conditions => total_local_new_count_select( aid ) )
    end     

    def ename
      english_name ? english_name : ''
    end
        
end
