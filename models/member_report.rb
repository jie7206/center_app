class MemberReport < ActiveRecord::Base

  def self.month_report
    result = []
    month_flag = 0
    all( :order => "rec_date desc", :limit => 400 ).each do |p|
      rec_month = p.rec_date.month
      if rec_month != month_flag
        result << p
        month_flag = rec_month
      end
    end
    return result
  end

  def self.year_report( year )
    result = []
    month_flag = 0
    all( :conditions => ["rec_date >= ?", "#{year}-01-01" ],:order => "rec_date desc" ).each do |p|
      rec_month = p.rec_date.month
      if rec_month != month_flag
        result << p
        month_flag = rec_month
      end
    end
    return result
  end

  def self.get_count( field_key, area_id )
    mp = first( :order => "rec_date desc", :conditions => ["area_id = ?" , area_id ] )
    if mp 
      return mp.send(field_key)
    else
      return 0
    end
  end

  def supporter_count
    if !m_supporter_student.nil? and !m_supporter_young.nil? and !m_supporter_adult.nil? and !m_supporter_old.nil? and !f_supporter_student.nil? and !f_supporter_young.nil? and !f_supporter_adult.nil? and !f_supporter_old.nil?
      return m_supporter_student + m_supporter_young + m_supporter_adult + m_supporter_old + f_supporter_student + f_supporter_young + f_supporter_adult + f_supporter_old
    else
      return 0
    end
  end

end
