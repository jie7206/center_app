require 'functions'

class Donation < ActiveRecord::Base
  belongs_to :member
  before_create :set_default

  def set_default
    if title.empty?
      self.title = "#{accounting_date.year}年#{accounting_date.month}月份#{donation_catalog_arr.rassoc(catalog_id)[0]}"
    end
  end

  def self.total_times( member_id )
    count( :conditions => ["member_id = ?", member_id] )
  end

  def self.total_times_in_months( member_id, month_num )
    # 若备注有跨月份的记录，则month_num_plus用来计算应该补上多少次
    month_num_plus = 0
    rs = all( :conditions => ["member_id = ? and created_at >= ?", member_id, (Date.today-month_num.month).to_s(:db)] )
    rs.each do |r|
        # 看备注是否有～符号来计算跨月份的次数
        if !r.note.empty? and !r.note.index("～").nil?
            temp_arr = r.note.strip.gsub!('月分','').split("～")  # strip remove leading and trail whitespace
            if temp_arr.size > 0
                num1 = temp_arr[0].to_i ; num2 = temp_arr[1].to_i
                if num1 > 0 and num2 > 0 and num2 > num1
                    month_num_plus += num2 - num1  # 例如：1～3月分
                elsif num1 > 0 and num2 > 0 and num2 < num1
                    month_num_plus += (num2+12) - num1  # 例如：12～2月分
                end
            end
        end
    end
    return rs.size + month_num_plus
  end
      
  def self.total_amount( member_id, month_num = nil )
    if month_num
      result = find_by_sql("SELECT SUM(amount) AS total_amount FROM donations WHERE catalog_id=1 and member_id=#{member_id} and created_at >= '#{(Time.now-month_num.month).to_s(:db)}'")[0][:total_amount]
    else
      result = find_by_sql("SELECT SUM(amount) AS total_amount FROM donations WHERE catalog_id=1 and member_id=#{member_id}")[0][:total_amount]
    end  
    if result
      return result.to_i
    else
      return 0
    end
  end

  def self.month_ave_in_this_year( member_id )
    result = find_by_sql("SELECT SUM(amount) AS total_amount FROM donations WHERE catalog_id=1 and member_id=#{member_id} AND accounting_date >= '2014-01-01'")[0][:total_amount]
    if result
      return (result.to_f/11).to_i
    else
      return 0
    end
  end

  def self.month_ave( member_id )
    result = find_by_sql("SELECT SUM(amount) AS total_amount FROM donations WHERE catalog_id=1 and member_id=#{member_id}")[0][:total_amount]
    if result and result.to_i > 0
      # 计算到底有几个月分
      month_num = month_diff( Donation.first(:order => "accounting_date",:conditions => ["catalog_id=1 and member_id=?",member_id] ).accounting_date, Date.today ).to_i
      return (result.to_f/month_num).to_i
    else
      return 0
    end
  end

end
