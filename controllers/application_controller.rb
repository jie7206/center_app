# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'lib/functions.rb'

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time
  before_filter :ini_var #所有全域参数在此设定
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  before_filter :authorize, :except => [:login, :forgot_password, :process_forgot_password, :renew_password_form, :renew_password, :xml_list]

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def authorize
    session[:role] = 'admin'
    # if session[:role].nil?
    #   redirect_to :controller => 'main', :action => 'login'
    # end
  end
  
  # 所有全域参数在此设定
  def ini_var
  	# 預設為北京地区:亲友99大中華圈0中國大陸1北京2上海3廣州4武漢5大連6天津7廈門8首爾9官校10
    session[:default_area_id] ||= value_of('default_area_id')
    # 载入人員报表栏位的中文标题
    member_report_field_titles
    @all_title = '全部'
    @local_sum_title = ''
    @local_effect_title = '地區有效'
    @local_leader_title = @mr_titles[:leader_count]
    @local_staff_title = @mr_titles[:staff_count]
    @local_family_title = @mr_titles[:family_count]
    @generation2_title_1 = @mr_titles[:generation2_1_count]
    @generation2_title_2 = @mr_titles[:generation2_2_count]
    @blessedable_title = @mr_titles[:blessedable_count]
    @pray_list_title = '重點培養'
    set_center_name #管理系统的标题
    @my_photo_path = value_of('my_photo_path') #我的生活照片读取路径
    @activities_photo_path = value_of('activities_photo_path') #中心活动的相片读取路径
    @verse_collect_for_me_title = '好句收藏' # 情緒管理中的收藏使用
    @verse_collect_for_ppt_title = '教材备选' # 情緒管理中的收藏使用
  end

  # 人員报表栏位的中文标题
  def member_report_field_titles
    @mr_titles = {
      :leader_count => "公職",
      :staff_count => "献身",
      :family_count => "家庭",
      :supporter_count => "學員",
      :student_member_count => "學生會員",
      :worker_member_count => "職工會員",
      :generation2_1_count => "小二世",
      :generation2_2_count => "中二世",
      :generation2_3_count => "大二世",
      :student_new_count => "學生學員",
      :worker_new_count => "職工學員",
      :blessedable_count => "可祝福",
      :m_core_student => "男核學生",
      :m_core_young => "男核青年",
      :m_core_adult => "男核成年",
      :m_core_college => "男核大學",
      :f_core_student => "女核學生",
      :f_core_young => "女核青年",
      :f_core_adult => "女核成年",
      :f_core_college => "女核大學",
      :m_new_student => "男新學生",
      :m_new_young => "男新青年",
      :m_new_adult => "男新成年",
      :m_new_college => "男新大學",
      :f_new_student => "女新學生",
      :f_new_young => "女新青年",
      :f_new_adult => "女新成年",
      :f_new_college => "女新大學",
      :m_normal_student => "男普學生",
      :m_normal_young => "男普青年",
      :m_normal_adult => "男普成年",
      :m_normal_college => "男普大學",      
      :f_normal_student => "女普學生",
      :f_normal_young => "女普青年",
      :f_normal_adult => "女普成年",
      :f_normal_college => "女普大學"
    }
  end

  def order_index_field( record_set )
    #if params[:order_method] && params[:include_trace]
    #  record_set.sort! { |x,y| x.trace.send(params[:order_method]) <=> y.trace.send(params[:order_method]) }
    #elsif params[:order_method]
      record_set.sort! { |x,y| x.send(params[:order_method]) <=> y.send(params[:order_method]) }
    #end
    record_set.reverse! if params[:order_desc]
  end
  
  def set_center_name
    @area_name = area_arr.rassoc(session[:default_area_id].to_i)[0]
    @center_name = @area_name + "神愛之家"
  end
  
  def redirect_to_index
    if session[:last_url]
      redirect_to session[:last_url]
    else
      redirect_to :controller => :main, :action => 'life_chart'
    end
  end

  def exe_order_up( class_name, object_id, order_field = "order_num" )
    @ids = []
    class_name.find(:all, :order => order_field).each {|d| @ids << d.id}
    @ori_index = @ids.index(object_id.to_i)
    if @ori_index != 0 then
      @ids[@ori_index] = @ids[@ori_index-1]
      @ids[@ori_index-1] = object_id.to_i
      exe_update_order_num( class_name, order_field, @ids )
    end
  end
  
  def exe_order_down( class_name, object_id, order_field = "order_num" )
    @ids = []
    class_name.find(:all, :order => order_field).each {|d| @ids << d.id}
    @ori_index = @ids.index(object_id.to_i)
    if @ori_index != @ids.size-1 then
      @ids[@ori_index] = @ids[@ori_index+1]
      @ids[@ori_index+1] = object_id.to_i
      exe_update_order_num( class_name, order_field, @ids )
    end
  end

  def exe_update_order_num( class_name, order_field = "order_num", ids = class_name.find(:all, :order => order_field) )
    ids.each {|i| class_name.find(i).update_attribute( order_field, ids.index(i)+1 )}
  end

  def update_life_goal_order_num
    exe_update_order_num LifeGoal, "order_num", LifeGoal.find(:all, :order => "order_num", :conditions => ["is_todo = ?",false]) 
  end

  def update_todo_list_order_num
    exe_update_order_num LifeGoal, "order_num", LifeGoal.find(:all, :order => "order_num", :conditions => ["is_todo = ? and is_pass = ?",true,false])     
  end

  def exe_update_table_field_value( class_name )
    class_name.find(params[:id]).update_attribute(params[:field_name],params[:field_value])
    @msg = "已於#{Time.now.to_s(:db)}將#{params[:field_name]}更新為#{params[:field_value]}"
  end

  def exe_update_table_fields_values( class_name, id, data )
    class_name.find(id).update_attributes(data)
    @msg = "已於#{Time.now.to_s(:db)}將资料内容更新}"
  end  
  
  def order_index_field( records_array )
    if params[:order_method]
    	case params[:order_method]
			when "life_catalog.line_order_num"
				records_array.sort! { |x,y| x.life_catalog.line_order_num <=> y.life_catalog.line_order_num }
			else
      	records_array.sort! { |x,y| x.send(params[:order_method]) <=> y.send(params[:order_method]) }
  		end
    end
    records_array.reverse! if params[:order_desc]
  end
  
  def reset_order_num( class_name )
    n=1
    class_name.find(:all, :order => 'order_num').each do |d|
      d.order_num = n
      d.save
      n+=1
    end
  end

  def show_appointment_promised( appointment_promise )
    appointment_promise ?  "<img src='/images/icon/handshake.png' align='absmiddle' title='對方已承諾赴約' />" : ''
  end

  def show_appointment_info( member )
    if member.trace
      if member.trace.appointment_made && member.trace.next_class_date && member.trace.next_class_date >= Date.today && member.trace.next_class_teacher && member.trace.next_class_title && member.trace.appointment_promise
        text_str = "<a href='/traces/appointment'>#{member.trace.next_class_date}</a>"
      elsif member.trace.appointment_made && member.trace.next_class_date && member.trace.next_class_date <= Date.today
        text_str = "<a href='/traces/#{member.trace.id}/edit'><span class='next_class_date_already_expired'>約好但時間已過</span></a>"
      elsif member.trace.appointment_made && (!member.trace.appointment_promise)
        text_str = "<a href='/traces/#{member.trace.id}/edit'>對方沒承諾赴約</a>"
      elsif !member.trace.appointment_made
        text_str = "<a href='/traces/#{member.trace.id}/edit'>還沒開始約</a>"
      end
      return text_str
    end      
  end  
  
  def get_next_class_desr( trace )
    if not trace.next_class_title.empty?
      "預計在 [#{trace.next_class_date}] 由 [#{trace.next_class_teacher}] 負責 [#{trace.next_class_title}]"
    else
      "下次見面的時間或內容還沒安排好!"
    end
  end
  
  def get_start_date( from_date, days, week )
    target_date = from_date.to_date + days
    while target_date.wday > week
      target_date -= 1
    end
    return target_date
  end

  def get_mids_for_login_session
#    if session[:login_role] != 'admin'
      session[:tids_for_login] = session[:mids_for_login]  = Member.get_team_members( session[:login_mid] )
#    end
  end
    
  def check_if_your_members
    if (session[:login_role] != 'admin') && params[:id] && session[:mids_for_login]
      if not session[:mids_for_login].index(params[:id].to_i)
        flash[:notice] = "您不能編輯該會員的資料喔! ^^"
        redirect_to :controller => 'main', :action => 'show_warning'
      end
    end
  end

  def check_if_your_traces
    if (session[:login_role] != 'admin') && params[:id] && session[:tids_for_login]
      if not session[:tids_for_login].index(params[:id].to_i)
        flash[:notice] = "您不能編輯該會員的進度喔! ^^"
        redirect_to :controller => 'main', :action => 'show_warning'
      end
    end
  end
  
  def check_if_your_question
    if (session[:login_role] != 'admin') && params[:id]
      if Question.find(params[:id]).member_id != session[:login_mid]
        flash[:notice] = "您不能編輯別人發起的問題喔! ^^"
        redirect_to :controller => 'main', :action => 'show_warning'
      end
    end    
  end
  
  def check_if_your_history
    return true
    if (session[:login_role] != 'admin') && params[:id]
      if not session[:mids_for_login].index(History.find(params[:id]).member_id)
        flash[:notice] = "您不能編輯別的小組的紀錄喔! ^^"
        redirect_to :controller => 'main', :action => 'show_warning'
      end
    end    
  end
  
  def check_if_your_pay_log
    if (session[:login_role] != 'admin') && params[:id]
      if PayLog.find(params[:id]).member_id != session[:login_mid] && Account.find_by_member_id(session[:login_mid]).is_accountant != true
        flash[:notice] = "您不能編輯別人申請的報銷喔! ^^"
        redirect_to :controller => 'main', :action => 'show_warning'
      end
    end    
  end
  
  def check_if_admin
    if session[:login_role] != 'admin'
        flash[:notice] = "您不能編輯該頁面喔! ^^"
        redirect_to :controller => 'main', :action => 'show_warning'
    end    
  end
  
  def life_rec_start_date
    Param.find_by_name('life_rec_start_date').value
  end

  def life_rec_goal_minutes
    Param.find_by_name('life_rec_goal_minutes').value
  end
      
  # 將課程紀錄存入session,以便快速新增課程紀錄
  def set_auto_history_session( class_date, class_teacher, class_title, class_type, area_id, is_public_class )
    session[:class_date] = class_date
    session[:class_teacher] = class_teacher
    session[:class_title] = class_title
    session[:class_type] = class_type
    session[:class_area_id] = area_id
    session[:is_public_class] = is_public_class
  end

  # 按性别、会员分类、年龄、是否为大学生等属性值 赋予 结果集合值
  def set_result_value_by_atts( mid, sex_id, classification, age, is_college )
    return true if classification == 0 # 遇到不列计算的分类则不处理
    sex = sex_id == 1 ? "m" : "f"
    # 处理会员种类的部分
    case classification
      when '1' : ctype = 'core' # 核心會員
      when '2' : ctype = 'new' # 新進會員
      when '3' : ctype = 'normal' # 一般會員
      when '5' : ctype = 'registered' # 登記會員
      when '6' : ctype = 'inactive' # 休眠會員
      when '4' : ctype = 'supporter' # 慕道学員(SUPPORTERS)
    end
    # 处理年龄层的部分
    case_str = "case age\n"
    value_of("member_age_classify_str").split(",").each do |item|
      age_code , age_range = item.split(":")
      case_str += "when (#{age_range})\n"
      case_str += '@result["#{sex}_#{ctype}_' + age_code + '".to_sym] += 1' + "\n"
      case_str += '@result["#{sex}_#{ctype}_' + age_code + '_ids".to_sym] += "#{mid},"' + "\n"
    end
    case_str += "end\n"
    eval case_str
    # 处理大学生的部分
    if is_college
      @result["#{sex}_#{ctype}_college".to_sym] += 1
      @result["#{sex}_#{ctype}_college_ids".to_sym] += "#{mid},"
    end
  end  

  # 取出人員分类的人数统计字典
  def get_classification_counts( members )   
    # 结果集合
    @result = {}
    # 结果集合初始化
    # 男女性别
    %w(m f).each do |sex|
      # 会员分类
      %w(core normal registered inactive new supporter).each do |ctype|
        # 年龄层 + 是否为大学生
        %w(student young adult old college).each do |age|
          @result["#{sex}_#{ctype}_#{age}".to_sym] = 0           # 人数统计初始化
          @result["#{sex}_#{ctype}_#{age}_ids".to_sym] = ""      # 会员id初始化
        end
      end
    end
    members.each do |m|
      # 按性别、会员分类、年龄、是否为大学生等属性值 赋予 结果集合值
      set_result_value_by_atts m.id, m.sex_id, m.classification, m.get_age, m.is_college
    end
    return @result
  end 

  # 更新或新建人員分布报表
  def update_or_create_member_report
    area_id = 2 #session[:default_area_id] 目前只有北京需要出报表，为了避免错误，一律设置成2(北京)
    rec_date = Time.now.strftime("%Y-%m-%d")
    report = MemberReport.find_by_area_id_and_rec_date( area_id, rec_date )
    classification_counts = get_classification_counts( Member.find(:all, :conditions => ["area_id = ? and classification != ?",area_id,0]) )
    input_params = {
                          :family_count => Member.total_local_family_count(area_id),
                          :student_member_count => Member.sum_by_cid_and_aid(1, area_id),
                          :worker_member_count => Member.sum_by_cid_and_aid(2, area_id),
                          :generation2_1_count => Member.total_local_g21_count(area_id),
                          :generation2_2_count => Member.total_local_g22_count(area_id),
                          :generation2_3_count => Member.total_local_g23_count(area_id),
                          :student_new_count => Member.sum_by_cid_and_aid(6, area_id),
                          :worker_new_count => Member.sum_by_cid_and_aid(7, area_id),
                          :blessedable_count => Member.total_local_blessedable_count(area_id),
                          :leader_count => Member.total_local_leader_count(area_id),
                          :staff_count => Member.total_local_staff_count(area_id)}
    # 依分类加入
      # 男女性别
      %w(m f).each do |sex|
        # 会员分类 + 礼拜活动 + 慕道群眾(SUPPORTERS)
        %w(core normal registered inactive new sunday supporter).each do |ctype|
          # 年龄层 + 大学生
          %w(student young adult old college).each do |age|
            key1 = "#{sex}_#{ctype}_#{age}".to_sym           # 人数统计
            key2 = "#{sex}_#{ctype}_#{age}_ids".to_sym    # 会员id
            if ctype != "sunday"  # 会员分类统计资料
              input_params[key1] = classification_counts[key1]
              input_params[key2] = classification_counts[key2]
            elsif ctype == "sunday"  # 出席礼拜统计资料
              # 依照计算标准(每月最高兩次人數的平均)+传入的key值(年龄层、大学生)来取回最近一个月内的礼拜出席次数
              input_params[key1] = get_last_month_sunday_service_count_by key1
            end                
          end
        end
      end

    if report
      report.update_attributes( input_params )
      flash[:notice] = '今天的人員報表已 【更新】 成功!'
    else
      input_params[:area_id] = area_id
      input_params[:rec_date] = rec_date
      MemberReport.create( input_params )
      flash[:notice] = '今天的人員報表已 【新增】 成功!'
    end
  end

  # 依照计算标准(每月最高兩次人數的平均)+传入的key值(年龄层、大学生)来取回最近一个月内的礼拜出席次数
  def get_last_month_sunday_service_count_by ( key )
    # 依据key中的值分别计算--注意：ctype 一定等于 sunday
    sex, ctype, age = key.to_s.split( "_" )
    # 预备性别参数、年龄范围及结果值
    sex_id = sex == "m" ? 1 : 0
    s = value_of("member_age_classify_str")
    age_range = s[s.index(age)+age.length+1,6] if age != "college"  # 大学生的部分必须另外算
    result_count = 0    
    # 取出每月最高兩次人數的礼拜日期
    service_days = History.all( :select => "class_date, count(*) as counts", :conditions => [ "(class_type = ? or class_type = ? ) and class_date >= ? and area_id = ?", "sunday_service", "sunday_service_2g", Date.today - 1.month, session[:default_area_id] ], :group => "class_date", :order => "counts desc" )
    max_2_service_days = []
    if service_days.size >= 2
      max_2_service_days << service_days[0].class_date << service_days[1].class_date
    elsif service_days.size == 1
      max_2_service_days << service_days[0].class_date
    end
    # 按日期计算此年龄层的人数
    max_2_service_days.each do |class_date|
      histories = History.all( :include => :member, :conditions => [ "(class_type = ? or class_type = ? ) and class_date = ? and area_id = ?", "sunday_service", "sunday_service_2g", class_date, session[:default_area_id] ] )
      # 逐一查看符合的资料笔数
      histories.each do |h|
        if age != "college" and h.member.sex_id == sex_id and h.member.area_id == session[:default_area_id].to_i and eval(age_range).include?(h.member.get_age)
          result_count += 1
        elsif age == "college" and h.member.sex_id == sex_id and h.member.area_id == session[:default_area_id].to_i and h.member.is_college
          result_count += 1
        end
      end      
    end
    result_count /= 2 if max_2_service_days.size == 2  # 每月最高兩次人數的平均
    return result_count
=begin
    # 以下代码为只要这个月有来一次的全都算入，好处是可以传回会员ID，但由于不是报表规定的计算标准，所以暂时不用
    # 取出最近一个月内所有的礼拜活动记录(包含大人和二世)，为了计算年龄必须 :include => :member
    histories = History.all( :include => :member, :conditions => [ "(class_type = ? or class_type = ? ) and class_date >= ? and area_id = ?", "sunday_service", "sunday_service_2g", Date.today - 1.month, session[:default_area_id] ], :order => "class_date" )
    # 逐一查看符合的资料笔数
    result_mids = []
    histories.each do |h|
      if age != "college" and h.member.sex_id == sex_id and h.member.area_id == session[:default_area_id].to_i and eval(age_range).include?(h.member.get_age)
         if not result_mids.include?(h.member_id)
          result_count += 1
          result_mids << h.member_id
        end
      elsif age == "college" and h.member.sex_id == sex_id and h.member.area_id == session[:default_area_id].to_i and h.member.is_college
        if not result_mids.include?(h.member_id)
          result_count += 1
          result_mids << h.member_id
        end
      end
    end
    return result_count, result_mids.join(",")
=end
  end

  # 自动新增一笔资产变化明细
  def auto_create_asset_item_detail( asset_item_id, new_amount, ori_amount = 0, asset_item_detail_catalog_id = 8 ) #8为自动写入
    AssetItemDetail.create( 
      :asset_item_id => asset_item_id,
      :asset_item_detail_catalog_id => asset_item_detail_catalog_id,
      :change_amount => new_amount.to_f - ori_amount.to_f, 
      :balance => new_amount.to_f )
  end


  # 读取asset_item_details在今天以前最后的值，以便计算change_amount
  def last_amount_before_today( asset_item_id )
    # 1.先确定有没有今天以前的记录
      before_today_record = AssetItemDetail.first(:order => "created_at desc, id desc", :conditions => ["asset_item_id = ? and created_at < ?", asset_item_id, "#{Date.today} 00:00:00".to_time])
    # 2.如果有，则取出最后那一笔的值
      return before_today_record.balance if before_today_record
    # 3.如果没有，则返回0
      return 0 if not before_today_record
  end  

  # 自动新增或更新一笔资产变化明细
  def auto_create_or_update_asset_item_detail( asset_item_id, new_amount, asset_item_detail_catalog_id = 8 ) #8为自动写入
      # 转型
      new_amount = new_amount.to_f
    # 1.先确定有没有今天的记录
      today_record = AssetItemDetail.last(:conditions => ["asset_item_id = ? and created_at > ?", asset_item_id, "#{Date.today} 00:00:00".to_time])
    # 2.如果确有今天的记录，change_value的值要和昨天的比较，然后将value和change_value的值更新
      if today_record
        # change_value的值要和前一天的比较
        change_amount = new_amount - last_amount_before_today(asset_item_id).to_f
        # 将value和change_value的值更新
        today_record.update_attributes(
          :change_amount => change_amount,
          :balance => new_amount
        )
      end
    # 3.如果没有今天的记录，change_value的值要和前一天的比较，然后将value和change_value的值新增
      if not today_record
        # change_value的值要和前一天的比较
        change_amount = new_amount - last_amount_before_today(asset_item_id).to_f
        # 将value和change_value的值新增
        new_record = AssetItemDetail.create( 
          :asset_item_id => asset_item_id,
          :asset_item_detail_catalog_id => asset_item_detail_catalog_id,
          :title => '自动',
          :change_amount => change_amount, 
          :balance => new_amount
        )   
      end
  end

  # 自动新增一笔参数变化明细
  def auto_create_param_change( param_id, new_value, ori_value = 0, if_to_i = true )
    change_value = if_to_i ? (new_value.to_i - ori_value.to_i) : (new_value.to_f - ori_value.to_f)
    new_value = if_to_i ? new_value.to_i : new_value.to_f
    if change_value != 0
      ParamChange.create( 
        :param_id => param_id, 
        :rec_date => Date.today.to_s(:db),
        :title => '自动', 
        :change_value => change_value, 
        :value => new_value )
    end
  end

  # 读取ParamChange在今天以前最后的值，以便计算change_value
  def last_value_before_today( param_id )
    # 实现步奏
    # 1.先确定有没有今天以前的记录
      before_today_record = ParamChange.first(:order => "rec_date desc, id desc", :conditions => ["param_id = ? and rec_date != ?", param_id, Date.today.to_s(:db)])
      # flash[:notice] = "before_today_record.id=#{before_today_record.id}已经找到！"
    # 2.如果有，则取出最后那一笔的值
      return before_today_record.value if before_today_record
    # 3.如果没有，则返回0
      return 0 if not before_today_record
  end

  # 自动新增或更新一笔参数变化明细
  def auto_create_or_update_param_change( param_id, new_value )
    # 实现步奏
      # 转成整数型
      # new_value = new_value.to_i
    # 1.先确定有没有今天的记录
      today_record = ParamChange.last(:conditions => ["param_id = ? and rec_date = ?", param_id, Date.today.to_s(:db)])
    # 2.如果确有今天的记录，change_value的值要和前一天的比较，然后将value和change_value的值更新
      if today_record
        # change_value的值要和前一天的比较
        change_value = new_value - last_value_before_today(param_id).to_i
        # 将value和change_value的值更新
        today_record.update_attributes(:change_value => change_value,:value => new_value) if today_record.change_value != change_value
      end
    # 3.如果没有今天的记录，change_value的值要和前一天的比较，然后将value和change_value的值新增
      if not today_record
        # change_value的值要和前一天的比较
        change_value = new_value - last_value_before_today(param_id).to_i
        # 将value和change_value的值新增
        new_record = ParamChange.create( 
          :param_id => param_id, 
          :rec_date => Date.today.to_s(:db),
          :title => '自动', 
          :change_value => change_value, 
          :value => new_value
        )
      end
  end

  def get_linshijie_total_histories_count
    History.count(:conditions => linshijie_total_histories_select )
  end

  # 计算生活项目各得多少总分并写入数据库
  def update_life_interest_values
    total_mins_of_life_interest = 0
    Param.all( :conditions => life_interest_select, :order => "name" ).each {|p| total_mins_of_life_interest += p.value.to_i }
    insert_param_change_record('count_mins_of_life_interest',total_mins_of_life_interest)
    Param.find_by_name('count_mins_of_life_interest').update_attribute(:value,total_mins_of_life_interest)
    update_life_catalog_values
    return total_mins_of_life_interest
  end

  # 计算生活类目各得多少总分并写入数据库
  def update_life_catalog_values
    Param.all( :conditions => life_catalog_select, :order => "name" ).each do |p|
      # 计算生活类目各得多少总分
      life_catalog_value = 0
      p.content.split(',').each {|num| life_catalog_value += value_of('life_interest_'+num).to_i }
      # 将生活类目各得多少总分写入数据库
      p.update_attribute(:value,life_catalog_value)
    end
  end

  # 取出生活项目的资料记录
  def get_life_interest_records( limit = value_of('get_life_interest_records_limit').to_i )
    # 预设为取一年内的资料
    params[:num_month_ago] ||= 12
    # 预设的资料排序
    order_str = "rec_date desc, title"
    if params[:param_id]
      result = ParamChange.all( :limit => limit, :conditions => ["change_value > 0 and param_id = ? and rec_date >= ?", params[:param_id], (Time.now-(params[:num_month_ago].to_i).month).strftime("%Y-%m-01")], :order => order_str, :include => :param )
    elsif params[:life_catalog_id]
      life_interest_ids = ''
      Param.find(params[:life_catalog_id]).content.split(',').each do |num|
        life_interest_ids += Param.find_by_name('life_interest_'+num).id.to_s + ','
      end
      result = ParamChange.all( :limit => limit, :conditions => "change_value > 0 and param_id in ("+life_interest_ids[0..-2]+") and rec_date >= '#{(Time.now-(params[:num_month_ago].to_i).month).strftime("%Y-%m-01")}'", :order => order_str, :include => :param )
    else
      life_interest_ids = Param.all( :conditions => "name like 'life_interest_%'" ).collect {|p| [ p.id ] }.join(',')
      result = ParamChange.all( :limit => limit, :conditions => "change_value > 0 and param_id in ("+life_interest_ids+") and rec_date >= '#{(Time.now-(params[:num_month_ago].to_i).month).strftime("%Y-%m-01")}'", :order => order_str, :include => :param )
    end
    return result
  end

  # 新增變化紀錄
  def insert_param_change_record( param_name, new_value, to_f = false )
    if to_f
      new_value = new_value.to_f
      ori_value = value_of(param_name).to_f
    else
      new_value = new_value.to_i
      ori_value = value_of(param_name).to_i
    end
    if new_value - ori_value != 0
      auto_create_param_change( Param.find_by_name(param_name).id, new_value, ori_value )
    end
  end

  # 新增或更新變化紀錄
  def insert_or_update_param_change_record( param_name, new_value, to_f = true )
    new_value = to_f ? new_value.to_f : new_value.to_i
    auto_create_or_update_param_change( Param.find_by_name(param_name).id, new_value )
  end

  # 取出资产所属的ID 1:家庭资产 2:中心资产
  def get_asset_belongs_to_id   
    if params[:asset_belongs_to_id]
      session[:asset_belongs_to_id] = @asset_belongs_to_id = params[:asset_belongs_to_id]
    elsif session[:asset_belongs_to_id]
      @asset_belongs_to_id = session[:asset_belongs_to_id]
    else
      session[:asset_belongs_to_id] = @asset_belongs_to_id = 1
    end
  end

  # 计算救急基金的总值
  def sum_of_emergency( currency = 'NTD' )
    # 取出可用于紧急预备金的资产项目
    emergency_records = AssetItem.all( :conditions => ["asset_belongs_to_id = ? and is_emergency = ?", 1, true] )
    # 依据要求的币别计算总值
    result = 0
    emergency_records.each do |r|
      case r.currency
        when 'NTD'
          exchange_rate = value_of('exchange_rates_NTD').to_f
        when 'MCY'
          exchange_rate = value_of('exchange_rates_MCY').to_f
        when 'USD'
          exchange_rate = value_of('exchange_rates_USD').to_f
        when 'KRW'
          exchange_rate = value_of('exchange_rates_KRW').to_f
      end      
      result += r.amount*exchange_rate 
    end
    return result / value_of('exchange_rates_'+currency).to_f
  end

  # 从网路获取最新房价资讯
  def get_today_house_price_str
    exchange_rates_MCY = value_of("exchange_rates_MCY").to_f
#=begin    
    houses = value_of("my_houses_names").split(",")
    prices = value_of("my_houses_prices").split(",")
    sizes = value_of("my_houses_sizes").split(",")
    new_amounts = []
    result = ""
    houses.each_index do |i|
      new_amount = prices[i].to_f*sizes[i].to_f
      new_amounts << new_amount
      result += "#{houses[i]}：#{prices[i]}/m² 大小：#{sprintf("%0.02f",sizes[i])}m² 總價：#{new_amount.to_i} (#{(new_amount*exchange_rates_MCY).to_i})\n"
    end
    # 更新固定资产(燕大星苑·红树湾)的值 #asset_item_id=93
    @asset_item = AssetItem.find(93) # id=93 为燕大星苑·红树湾固定资产项目
    if @asset_item.amount.to_i != new_amounts[0].to_i # 如果值不相等则更新
      @asset_item.update_attribute(:amount,new_amounts[0].to_i)
      auto_create_or_update_asset_item_detail(93, new_amounts[0].to_i)
      update_my_assets_and_insert_change_record # 自动更新Param中与我的资产相关的项目，并自动加入或更新ParamChange以追踪变化记录
    end    
    return result + "當前匯率：#{exchange_rates_MCY}"
#=end    
=begin
    # 从安居客获取燕大星苑·红树湾最新房价(每平米单价) 
    # http://qinhuangdao.anjuke.com/community/trends/387687
    ave_unit_price = get_house_price_from_web( 'qinhuangdao.anjuke.com', '/community/trends/387687', 'price_now' )
    new_amount = (ave_unit_price*49.47).to_i
    total_price = (new_amount*exchange_rates_MCY).to_i
    @asset_item = AssetItem.find(93) # id=93 为燕大星苑·红树湾固定资产项目
    if ave_unit_price > 0
      # 更新固定资产(燕大星苑·红树湾)的值 #asset_item_id=93      
      if @asset_item.amount.to_f != new_amount.to_f # 如果值不相等则更新
        @asset_item.update_attribute(:amount,new_amount)
        auto_create_or_update_asset_item_detail(93, new_amount)
        update_my_assets_and_insert_change_record # 自动更新Param中与我的资产相关的项目，并自动加入或更新ParamChange以追踪变化记录
      end
      return "安居客每平方米：#{ave_unit_price} 房屋總價：#{new_amount}(#{total_price}) 當前匯率：#{exchange_rates_MCY}"
    else
      return "由于无法连上网路，暂时没有新的报价，目前纪录的每平方米均价为#{(@asset_item.amount.to_f/house_size).to_i}元人民币"
    end
=end   
  end

  # 执行从网路获取最新房价资讯(目前由于网站会检查是否为机器人而无法使用2017.11.23)
  def get_house_price_from_web( host_name, url, keyword )
    download_data = get_remote_files(host_name,url,'',80,false)
    if !@remote_server_disconnect and download_data # 不管什么情况，如果发生异常，则返回历史值
      begin
        str = download_data[download_data.index(keyword),30]
        price_now = /(\d)+/.match(str)[0].to_i
        # 下列参数值已无用，可删
        # Param.find_by_name('hongshuwan_price_from_anjuke').update_attribute(:value, price_now) if price_now > 0
        return price_now
      rescue
        return value_of('hongshuwan_price_from_anjuke').to_i
      end
    else
      return value_of('hongshuwan_price_from_anjuke').to_i
    end
  end

  # 从网路获取最新的汇率值
  def get_exchange_rate_from_web( param_name = 'exchange_rates_MCY' )
    p = Param.first(:conditions => ["name = ?", param_name])
    return 1 if p.name == 'exchange_rates_NTD'
    host_name, url = p.content.split('//')[1].split('/')
    download_data = get_remote_files(host_name,"/#{url}",'',80,false)
    if !@remote_server_disconnect and download_data # 不管什么情况，如果发生异常，则返回0
      begin
        str = download_data[24000,200]
        return /(\d)+.(\d)+/.match(str)[0].to_f
      rescue
        return 0
      end
    else
      return 0
    end
  end

  # 更新各国货币的汇率
  def update_exchange_rates
    Param.all(:conditions => "name like 'exchange_rates_%'").each do |p|
      ori_value = p.value
      now_value = get_exchange_rate_from_web(p.name).to_f
      if now_value > 0 and ori_value != now_value
        p.update_attribute(:value, now_value)
        update_my_assets_and_insert_change_record # 自动更新Param中与我的资产相关的项目，并自动加入或更新ParamChange以追踪变化记录
      end
    end
  end

  # 新增變化紀錄
  def insert_param_change_record( param_name, new_value, to_f = false )
    if to_f
      new_value = new_value.to_f
      ori_value = value_of(param_name).to_f
    else
      new_value = new_value.to_i
      ori_value = value_of(param_name).to_i
    end
    if new_value - ori_value != 0
      auto_create_param_change( Param.find_by_name(param_name).id, new_value, ori_value )
    end
  end

  # 当我的家庭流动资产变化的时候，自动更新Param中流动资产的总值，并自动加入一笔ParamChange以追踪变化记录
  def update_my_assets_and_insert_change_record
    # 計算家庭資產報表參數
    prepare_my_asset_var
    # 新增或更新"我的现金資產總值"變化紀錄
    insert_or_update_param_change_record('my_total_flow_assets',@total_flow_assets)
    # 新增或更新"我的流動資產總值"變化紀錄
    insert_or_update_param_change_record('my_total_current_assets',@total_current_assets)
    # 新增或更新"我的資產總值(含固定资产)"變化紀錄
    insert_or_update_param_change_record('my_net_asset_value',@net_asset_value)
    # 新增或更新"可列为定存目标资产的总值"變化紀錄--2016.3.31 为了偿还贷款，此项已无意义而暂停使用
    # insert_or_update_param_change_record('my_total_money_for_goal',@total_money_for_goal)   
  end

  # 若分數足夠將生活目標的項目更新為已完成
  def update_life_goal_if_pass( change_value )
    life_goal = LifeGoal.find(params[:life_goal_id])
    if life_goal
      # 判断是否已经完成并更新资料栏位值
      completed_minutes = life_goal.completed_minutes + change_value
      is_pass = ( completed_minutes >= life_goal.minutes ) ? true : false
      life_goal.update_attributes( :completed_minutes => completed_minutes, :is_pass => is_pass )
      life_goal.update_attribute( :pass_date, Date.today ) if is_pass
    end
    # 如果全部都完成後，將其重置為全部沒有完成
    check_if_all_pass_then_reset
    # 若是待办事项，则自动将排序更新
    update_todo_list_order_num if life_goal.is_todo
  end

  # 依照會員在本月参加活动的次数，自动更新會員的所属类别
  def update_all_members_classification_by_histories_count_month

    Member.find(:all, :conditions => [ "area_id = ?", session[:default_area_id] ]).each do |m|

      if ( m.career != '6' and m.career != '7' and m.career != '99' )  # 不是 學生學員 職工學員 群眾
          
          # 新增會員：本月入会并聽完原理，开始出席公的活动，並至少做1次奉獻者   (公文：接受原理教育 + 做禮拜 + 奉獻)
          if m.is_new_member and m.histories_count_month >= 1 and m.donated_count >= 1 # <==在北京先不算奉献，因为难度太高
            m.update_attribute(:classification, '2')  # 2为新進會員
            next   
          # 核心會員：每三个月至少出席6次公的活动，並至少做2次奉獻者(主体对象合并计算，18岁以下不计算奉献)
          elsif ( m.get_age > 18 and m.histories_count_3month >= 6 and m.donated_count >= 2 ) or ( m.get_age <= 18 and m.histories_count_3month >= 6 )
            m.update_attribute(:classification, '1')  # 1为核心會員
            next
          # 一般會員：每三个月至少出席2次公的活动，並至少做1次奉獻者(主体对象合并计算，18岁以下不计算奉献)
          elsif ( m.get_age > 18 and m.histories_count_3month >= 2 and m.donated_count >= 1 ) or ( m.get_age <= 18 and m.histories_count_3month >= 2 )
            m.update_attribute(:classification, '3')  # 3为一般會員
            next
          # 登記會員：每6個月至少出席1次公的活动，或至少做1次奉獻者(主体对象合并计算，18岁以下不计算奉献)
          elsif ( m.get_age > 18 and m.histories_count_6month >= 1 or m.donated_count(6) >= 1 ) or ( m.get_age <= 18 and m.histories_count_6month >= 1 )
            m.update_attribute(:classification, '5')  # 5为登記會員
            next         
          # 休眠會員：過去6個月没有出席任何公的活动或做任何奉獻者
          else
            m.update_attribute(:classification, '6')  # 6为休眠會員
            next
          end

      elsif m.career != '99' and ( m.career == '6' or m.career == '7' ) # 不是群眾，且是學生學員或職工學員者
        m.update_attribute(:classification, '4')  # 4为慕道群眾
      else
        # 不是會員：检查到最后，未符合以上任何条件者
        m.update_attribute(:classification, '0')  # 0为不列计算
      end      
    end 
  end

  # 执行新增生活项目记录
  def create_new_param_change( data_from_traces_edit_form = nil )
    @param_change = ParamChange.new(params[:param_change])
    # 从人际管理的课程追踪而来
    if data_from_traces_edit_form and params[:trace][:last_class_teacher] == '林仕傑' and !data_from_traces_edit_form[:param_change][:param_id].empty?
      @param_change.param_id = data_from_traces_edit_form[:param_change][:param_id]
      begin_time = "#{params[:trace][:last_class_date]} #{params[:begin_time]}".to_time
      end_time = "#{params[:trace][:last_class_date]} #{params[:end_time]}".to_time
      @param_change.title = "[#{params[:begin_time]} - #{params[:end_time]}] #{params[:trace][:last_class_teacher]}对#{params[:member_name]}实施#{class_type_arr.rassoc(params[:trace][:class_type])[0]} - #{params[:trace][:last_class_title]}"
      @param_change.change_value = ((end_time-begin_time)/60).to_i
      @param_change.rec_date = params[:trace][:last_class_date]
    # 从时间管理的类别新增而来，提供经过的分钟数，然后由系统自动计算起始时间
    elsif @param_change.title.index("[xx:xx - ")
      end_time = "#{@param_change.rec_date} #{@param_change.title[9,5]}".to_time
      tmp_time = end_time - @param_change.change_value.to_i.minutes
      begin_time = "#{add_zero(tmp_time.hour,2)}:#{add_zero(tmp_time.min,2)}"
      @param_change.title = @param_change.title.sub('xx:xx',begin_time)
    # 从时间管理的类别新增而来，提供明确的起始时间，然后由系统自动计算经过的分钟数
    elsif @param_change.title.index(/^\[\d\d:\d\d - /)
      begin_time = "#{@param_change.rec_date} #{@param_change.title[1,5]}".to_time
      end_time = "#{@param_change.rec_date} #{@param_change.title[9,5]}".to_time
      @param_change.change_value = (end_time-begin_time)/60.to_i
    end
    if_saved = @param_change.save
    # 计算生活项目及类目得多少总分并写入数据库
    update_life_interest_values
    # 若分數足夠將生活目標的項目更新為已完成
    update_life_goal_if_pass(@param_change.change_value.to_i) if params[:life_goal_id]
    return if_saved
  end

  # 决定日期表格资料的起始日与最终日并设定好dates_arr的内容
  def prepare_dates_arr_data( dates_arr, records, field_name = 'rec_date', order = 'desc', include_today = false )
    if records.size > 0 and !include_today
      # 供查询用
      if order == 'desc'
        start_date = records.first.send(field_name).end_of_week
        start_date.downto(records.last.send(field_name).at_beginning_of_week) { |d| dates_arr << d.to_s(:db) }
      else
        start_date = records.first.send(field_name).at_beginning_of_week
        start_date.upto(records.last.send(field_name).end_of_week) { |d| dates_arr << d.to_s(:db) }
      end
    else
      # 预设的首页要能显示今天以方便记录
      if order == 'desc'
        start_date = Date.today.end_of_week
        start_date.downto((Date.today - value_of('day_num_in_life_chart').to_i).at_beginning_of_week) { |d| dates_arr << d.to_s(:db) }
      else
        start_date = Date.today.at_beginning_of_week
        start_date.upto((Date.today + value_of('day_num_in_life_chart').to_i).end_of_week) { |d| dates_arr << d.to_s(:db) }
      end
    end
    return dates_arr
  end

  def get_remote_files( host_name, url, save_file_path, port=80, exe_save=true )
    begin
      h = Net::HTTP.new host_name, port
      resp, data = h.get url, nil
      if resp.code == '200' #not data.empty?
        if exe_save
          f = File.open(save_file_path,'w')
          f.write(data)
          f.close
        end
        @remote_server_disconnect = false
        return data
      else
        @remote_server_disconnect = true
        return false 
      end
    rescue
    end
  end

  # 生成FusionCharts的XML资料
  def build_fusion_charts_vars_from( records, last_value, value_field_name = 'value', rec_date_field_name = 'rec_date' )
    @fusion_charts_data = ""
    today = Date.today
    start_date = today - (value_of('data_num_in_fusioncharts').to_i-1)
    data_arr = [] # 为了找出最大值和最小值
    start_date.upto(today) do |date|
      this_value = find_rec_date_value( records, date, value_field_name, rec_date_field_name )
      if this_value
        value = this_value
        last_value = this_value
      else
        this_value = last_value
      end
      data_arr << this_value.to_i
      @fusion_charts_data += "<set label='#{date.strftime("%m%d")}' value='#{this_value.to_i}' />"
    end
    # 设定最大值和最小值
    factor = 1.3 # 调整上下值，让图好看点
    min_value = data_arr.min ; max_value = data_arr.max ; mid_value = (max_value + min_value)/2.to_i
    # 与中轴距离 = 最大值-中间值
    center_diff = (max_value - mid_value).abs
    # 新最大值 = 中间值 + 与中轴距离* 调整因子 
    new_max_value = mid_value + center_diff*factor
    # 新最小值 = 中间值 - 与中轴距离* 调整因子
    new_min_value = mid_value - center_diff*factor
    
    @fusion_charts_yAxisMinValue = new_min_value.to_i
    @fusion_charts_yAxisMaxValue = new_max_value.to_i
  end

  # 生成FusionCharts的XML资料的辅助方法
  def find_rec_date_value( records, date, value_field_name, rec_date_field_name )
    records.each do |r|
      return r.send(value_field_name) if r.send(rec_date_field_name).to_date.to_s(:db) == date.to_s(:db) 
    end
    return nil
  end

end