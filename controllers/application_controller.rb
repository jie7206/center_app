# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
# require 'lib/functions'

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time
  before_filter :ini_var #所有全域参数在此设定
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  before_filter :authorize, :except => [:login, :forgot_password, :process_forgot_password, :renew_password_form, :renew_password, :xml_list]

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def authorize
    #session[:role] = 'admin'
    if session[:role].nil?
       redirect_to :controller => 'main', :action => 'login'
     end
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
      #:staff_count => "献身",
      :family_count => "家庭",
      :supporter_count => "學員",
      #:student_member_count => "學生會員",
      :worker_member_count => "職工會員",
      :generation2_1_count => "小孩子",
      :generation2_2_count => "中孩子",
      :generation2_3_count => "大孩子",
      #:student_new_count => "學生學員",
      :worker_new_count => "職工學員",
      :blessedable_count => "可全职",
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
    @center_name = @area_name + "诚爱教育中心"
  end
  
  def redirect_to_index
    if session[:last_url]
      redirect_to session[:last_url]
    else
      redirect_to :root
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
        # 会员分类 + 分享活动 + 慕道群眾(SUPPORTERS)
        %w(core normal registered inactive new sunday supporter).each do |ctype|
          # 年龄层 + 大学生
          %w(student young adult old college).each do |age|
            key1 = "#{sex}_#{ctype}_#{age}".to_sym           # 人数统计
            key2 = "#{sex}_#{ctype}_#{age}_ids".to_sym    # 会员id
            if ctype != "sunday"  # 会员分类统计资料
              input_params[key1] = classification_counts[key1]
              input_params[key2] = classification_counts[key2]
            elsif ctype == "sunday"  # 出席分享统计资料
              # 依照计算标准(每月最高兩次人數的平均)+传入的key值(年龄层、大学生)来取回最近一个月内的分享出席次数
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

  # 依照计算标准(每月最高兩次人數的平均)+传入的key值(年龄层、大学生)来取回最近一个月内的分享出席次数
  def get_last_month_sunday_service_count_by ( key )
    # 依据key中的值分别计算--注意：ctype 一定等于 sunday
    sex, ctype, age = key.to_s.split( "_" )
    # 预备性别参数、年龄范围及结果值
    sex_id = sex == "m" ? 1 : 0
    s = value_of("member_age_classify_str")
    age_range = s[s.index(age)+age.length+1,6] if age != "college"  # 大学生的部分必须另外算
    result_count = 0    
    # 取出每月最高兩次人數的分享日期
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
    # 取出最近一个月内所有的分享活动记录(包含大人和孩子)，为了计算年龄必须 :include => :member
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
      session[:asset_belongs_to_id] = @asset_belongs_to_id = 2
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
      @fusion_charts_data += "<set label='#{date.strftime("%Y-%m-%d")}' value='#{this_value.to_i}' />"
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


# require 'lib/functions'#### functions.rb #######################

class Fixnum

    # 将人民币转成新台币
    def rmb_to_ntd
        ( self * value_of("exchange_rates_MCY").to_f ).round
    end

    # 将人民币转成美元
    def rmb_to_usd
        ( self * (value_of("exchange_rates_MCY").to_f/value_of("exchange_rates_USD").to_f) ).round
    end

    # 将美元转成人民币
    def usd_to_rmb
        ( self * (value_of("exchange_rates_USD").to_f/value_of("exchange_rates_MCY").to_f) ).round
    end
    
    # 将新台币转成人民币
    def ntd_to_rmb
        ( self * (value_of("exchange_rates_NTD").to_f/value_of("exchange_rates_MCY").to_f) ).round
    end

    # 将新台币转成美元
    def ntd_to_usd
        ( self * (value_of("exchange_rates_NTD").to_f/value_of("exchange_rates_USD").to_f) ).round
    end

end

    def sex_arr
        [[ '男', 1 ],[ '女', 0 ]]
    end

    def classification_arr
        [ ['核心會員','1'],['新增會員','2'],['一般會員','3'],['登記會員','5'],['休眠會員','6'],['慕道學員','4'],['不列计算','0']]
    end
    
    def career_arr
        [ ['全职會員','0'],['孩子','5'],['群眾','99'],['單身公職','3'],['學生會員','1'],['職工會員','2'],['學生學員','6'],['職工學員','7']]
    end

    def career_arr_for_guest
        [ ['单身公职','3'],['學生會員','1'],['職工會員','2'],['學生學員','6'],['職工學員','7'],['群眾','99']]
    end

    def g2_age_arr
        [ [0,12], [13,18], [19,199] ] #[ [孩子-小学年龄区间], [孩子-中学年龄区间] ]
    end
    
    def area_arr
        [ ['親友',99],['中華',0],['中國',1],['北京',2],['上海',3],['廣州',4],['武漢',5],['山东',16],['大連',6],['珠海',13],['天津',7],['廈門',8],['香港',15],['台灣',14],['官校',10],['韩国',9],['日本',11],['菲律宾',12]]
    end
    
    def status_arr
        [ ['學習原理',0],['學習信仰',1],['禮拜奉獻',2],['信仰條件',3],['動員獻身',4],['海外募金',5],['韓國培訓',6],['開拓中心',7],['建立家庭',8]]
    end

    def star_arr
        [ ['幾乎沒來[1顆星]','1.0'],['偶而會來[2顆星]','2.0'],['定期會來[3顆星]','3.0'],['信仰穩定[3星半]','3.5'],['分擔使命[4顆星]','4.0'],['核心成員[4星半]','4.5'],['核心領導[5顆星]','5.0']]
    end
    
    def question_catalogs
      [ ['原理問題','0'],['個性問題','1'],['帶領問題','2'],['生活問題','3'],['建議事項','4']]
    end

    def roles_arr
      [ ['網站管理員','admin'],['愛心小組長','team_leader']]
    end

    def school_arr
        [ ['北大','0'],['清華','1'],['北航','2'],['農大','3'],['地大','4'],['林大','5'],['科大','6'],['人文','7'],['復旦','8']]
    end

    def class_type_arr
        [ ['训读会','read'],['小组分享','sunday_service'],['孩子分享','sunday_service_2g'],['室内活动','indoor'],['户外活动','outdoor'],['培训活动','training'],['一般讲课','normal'],['半日讲课','half'],['一日灵修','1day'],['两日灵修','2day'],['三日灵修','3day'],['四日灵修','4day'],['七日灵修','7day'],['十日灵修','10day'],['個別陪談','link'],['個別解惑','answer'],['養育課程','parenting'],['电话联系','tel'],['短信分享','wenxin'],['小组团契','association'],['小组会议','meeting'],['闲聊叙旧','keep_friendship']]
    end
    
    def main_teachers
      ['彭小鵬', '林仕傑', '洗敏瑩', '郭奕辰']
    end

    def activity_peroid_arr
      [ ['本月',0],['本季',3],['半年',6],['一年',12],['兩年',24],['三年',36] ]
    end

    def donation_catalog_arr
      [ ['十一奉献',1],['住宿奉献',4],['节日奉献',3],['感谢奉献',5],['特别奉献',6],['万物复归',7],['分享奉献',2] ]
    end

    def blessing_couple_arr
      [ ['1800對',10],['6500對',20],['3萬對(1992)',30],['36萬對(1995)',40],['360萬對(1997)',45],['4000萬對(1998)',50],['3億6千萬對(1999)',60],['4億對第1次(2000)',70],['4億對第2次(2001)',80],['4億對第3次(2002)',90],['4億對第4次(2003)',100],['4億對第5次(2004)',110],['4億對第6次(2005)',120],['2005.8國際全职式',125],['2005國際交叉全职',130],['2009國際全职式',140],['2010國際全职式',150],['2011國際全职式',160],['2012國際全职式',170],['2013國際全职式',180],['2014國際全职式',190],['2015國際全职式',200],['2016國際全职式',210],['2017國際全职式',220],['2018國際全职式',230],['2019國際全职式',240],['2020國際全职式',250],['2021國際全职式',260],['2022國際全职式',270] ]
    end

    def asset_belongs_to_arr
      [ ['自家資產',1],['中心資產',2] ]
    end

    def currency_arr
      [ ['人民幣','MCY'],['新台幣','NTD'],['美元','USD'],['韓圜','KRW']]
    end
        
    def day_diff( from_time, to_time = 0, include_seconds = false )
        from_time = from_time.to_time if from_time.respond_to?(:to_time)
        to_time = to_time.to_time if to_time.respond_to?(:to_time)
        return (((to_time - from_time).abs)/86400).round
    end  

    # 计算利息时的天数之差 logger.info "diff=#{day_diff( from_time, to_time - 2.days )}"
    def day_diff_for_loan( from_time, to_time, fix_days = 2 )
      to_time -= fix_days.days
      return (DateTime.parse(to_time.to_s)-DateTime.parse(from_time.to_s)).abs.to_i
    end
    
    def month_diff( from_time, to_time = 0, include_seconds = false )
        from_time = from_time.to_time if from_time.respond_to?(:to_time)
        to_time = to_time.to_time if to_time.respond_to?(:to_time)
        return (((to_time - from_time).abs)/(86400*31)).round
    end
    
    def year_diff( from_time, to_time = 0, include_seconds = false )
        from_time = from_time.to_time if from_time.respond_to?(:to_time)
        to_time = to_time.to_time if to_time.respond_to?(:to_time)
        return (((to_time - from_time).abs)/(86400*31*12)).round
    end

    def get_min_item_catalog_id
        LifeCatalog.first( :conditions => ["goalable = ?",true], :order => "total_minutes" ).id
    end

    def remain_minutes_of_life_catalog( cid )
        life_catalog = LifeCatalog.first( :include => :life_items, :conditions => [ "id = ?", cid ] )
        total_minutes_of_today = 0
        life_catalog.life_items.each do |life_item|
          if use_life_catalog_goal_minutes?
                life_records = LifeRecord.all( :conditions => ["life_item_id = ? AND rec_date = ? AND is_not_goal != ?",  life_item.id, Date.today.to_s(:db), true] )
                life_records.each { |r| total_minutes_of_today += r.used_minutes } if not life_records.empty?       
        else
            if life_item.is_goal
                total_minutes_of_this_item = 0
                life_records = LifeRecord.all( :conditions => ["life_item_id = ? AND rec_date = ? AND is_not_goal != ?",  life_item.id, Date.today.to_s(:db), true] )
                life_records.each { |r| total_minutes_of_this_item += r.used_minutes } if not life_records.empty?
                total_minutes_of_this_item = life_item.goal_minutes if life_item.goal_minutes.to_i > 0 and total_minutes_of_this_item > life_item.goal_minutes
                total_minutes_of_today += total_minutes_of_this_item
            end
          end
        end
        life_catalog_total_goal_minutes = life_catalog.total_goal_minutes
        remain_minutes = life_catalog_total_goal_minutes - total_minutes_of_today
        remain_minutes_percent = remain_minutes.to_f / life_catalog_total_goal_minutes
        return { :catalog_name => life_catalog.name, :remain_minutes => remain_minutes, :remain_minutes_percent => remain_minutes_percent }
    end

    def remain_minutes_of_life_item( item_id )
        life_item = LifeItem.find(item_id)
    total_minutes_of_this_item = 0
      life_records = LifeRecord.all( :conditions => ["life_item_id = ? AND rec_date = ? AND is_not_goal != ?",  item_id, Date.today.to_s(:db), true] )
      life_records.each { |r| total_minutes_of_this_item += r.used_minutes } if not life_records.empty?
      total_minutes_of_this_item = life_item.goal_minutes if life_item.goal_minutes.to_i > 0 and total_minutes_of_this_item > life_item.goal_minutes

        remain_minutes = life_item.goal_minutes - total_minutes_of_this_item
        remain_minutes_percent = remain_minutes.to_f / life_item.goal_minutes
        return { :item_name => life_item.name, :remain_minutes => remain_minutes, :remain_minutes_percent => remain_minutes_percent }
    end
    
  def add_date_to_all_goal_of_today_completed_data( rec_date )
    param = Param.find_by_name('all_goal_of_today_completed_data')
    all_goal_of_today_completed_arr = param.content.split(",")
    rec_date.gsub!('-','')
    if not all_goal_of_today_completed_arr.include?( rec_date )
        all_goal_of_today_completed_arr << rec_date
        param.update_attributes( :value => all_goal_of_today_completed_arr.size, :content => all_goal_of_today_completed_arr.join(",") )
    end   
  end
  
  def use_life_catalog_goal_minutes?
    value = Param.find_by_name('use_life_catalog_goal_minutes').value
    value == "true" ? true : false
  end

  def exe_update_life_catalog_total_minutes ( cid = [] )
    life_catalogs = LifeCatalog.all( :conditions => "id in ( #{cid.join(",")} )", :include => :life_items )
    life_catalogs.each do |life_catalog|
      total_minutes = 0
      life_catalog.life_items.each { |t| total_minutes += t.total_minutes }
      life_catalog.update_attribute( :total_minutes, total_minutes )
    end
  end
   
  def sum_by_cid_select( cid )
    [ "career = ?", cid]
  end

  def sum_by_cid_and_aid_select( cid, aid )
    [ "career = ? and area_id = ?", cid, aid ]
  end

  def total_local_count_select( aid )
    [ "career != 99 and area_id = ?", aid ]
  end

  def total_local_effect_count_select( aid )
    [ "classification != '4' and area_id = ?", aid ]
  end

  def total_local_leader_count_select( aid )
    [ "is_core_leader = ? and career != 99 and area_id = ?", true, aid ]
  end
    
  def total_local_staff_count_select( aid )
    [ "is_staff = ? and career != 99 and area_id = ?", true, aid ]
  end
  
  def total_local_family_count_select( aid )
    [ "sex_id = ? and career = '0' and area_id = ?", 1, aid ]
  end

  def total_local_core_family_count_select( aid )
    [ "is_core_family = ? and area_id = ?", true, aid ]
  end
  
  def total_local_core_members_count_select( aid )
    [ "classification = ? and area_id = ?", '1', aid ]
  end

  def total_local_disconnect_members_count_select( aid )
    [ "( career != '5' and career != '99' ) and classification = ? and area_id = ?", '4', aid ]
  end

  def total_local_single_members_count_select( aid )
    [ "( career = '1' or career = '2' or career = '3' or career = '5' ) and area_id = ?", aid ]
  end  
    
  def total_count_select
    "career != '99'"
  end
  
  def db_total_count_select
    "members.id > 0"
  end

  def is_on_table_count_select
    [ "career != '99' and is_on_table = ?", true]
  end  

  def is_brother_count_select( aid )
    [ "sex_id = ? and birthday_still_unknow = ? and birthday > ? and area_id = ? and career != ? and career != ?", 1, false, "1974-12-02".to_date, aid, '5', '99' ]
  end  

  def total_local_blessedable_count_select( aid )
    [ "blessedable = ? and career != 99 and area_id = ?", true, aid ]
  end

  def total_local_new_count_select( aid )
    [ "classification = '2' and area_id = ?", aid ]
  end

  def linshijie_total_histories_select
    "class_teacher = '林仕傑' and name != '林仕傑'"
  end

  def life_interest_select
    "name like 'life_interest_%'"
  end

  def life_catalog_select
    "name like 'life_catalog_%'"
  end

  def add_zero( num, pos = 3 )
    if num.to_i > 0
      result = num.to_s
      case pos 
        when 4
          if num < 1000 and num >=100
            result = "0"+result
          elsif num < 100 and num >=10
            result = "00"+result
          elsif num < 10
            result = "000"+result
          end
        when 3
          if num < 100 and num >=10
            result = "0"+result
          elsif num < 10
            result = "00"+result
          end
        when 2
          if num < 100 and num >=10
          elsif num < 10
            result = "0"+result
          end
      end
      return result
    else
      return "0"*pos
    end
  end

  def value_of( param_name )
    Param.find_by_name(param_name).value
  end

  def title_of( param_name )
    Param.find_by_name(param_name).title
  end  

  def content_of( param_name )
    Param.find_by_name(param_name).content
  end  

  def trip_title( title )
    return title.sub('【','').sub('】','')
  end  

  # 如果全部都完成後，將其重置為全部沒有完成
  def check_if_all_pass_then_reset
    life_goals_reset_everyday = value_of('life_goals_reset_everyday').to_i
    # 如果设定为"每日重头开始"，亦即只要是新的一天(定义是所有记录中最近完成日找不到一笔是今天的)，则重设目标(完成0分，已完成为假)
    if life_goals_reset_everyday > 0 and !LifeGoal.last( :order => "order_num", :conditions => [ "updated_at >= '#{Date.today.to_s(:db)}' and is_pass = ? and is_todo = ? and is_show = ?", true, false, true ] )
      exe_reset_life_goals #完成0分，已完成为假
    # 如果设定为"每日重头开始"，但是没有一项完成----待开发！
    # 如果全部通过且日期不为今日--(如果找不到任何一项没有通过的生活目标，就看最后一项生活目标的最近完成日是不是今天，如果不是则更新)
    elsif !LifeGoal.find_by_is_pass_and_is_todo_and_is_show(false,false,true) and LifeGoal.last( :order => "order_num", :conditions => [ "pass_date != '#{Date.today.to_s(:db)}' and is_todo = ? and is_show = ?", false,true ] )
      exe_reset_life_goals
    end
  end  

  # 执行生活目标的归零重置
  def exe_reset_life_goals
    LifeGoal.update_all( ["is_pass = ?", false], ["is_todo = ?", false] )
    LifeGoal.update_all( "completed_minutes = 0", ["is_todo = ?", false] )
  end

  # 会员列表的预设排序
  def default_order_for_member_list
    'members.classification,members.sex_id,members.birthday'
  end 

  # 避免超出索引值
  def check_index_boundary( index, size )
    if index <= -1
      return size-1
    else
      return index >= size ? 0 : index
    end
  end

  # 回传资料夹内包含match_str字串的档名
  def get_file_names( folder_path, match_str )
    result = []
    Dir.glob(Rails.root+folder_path+"*#{match_str}*.jpg").each do |filefullname|
      result << filefullname.sub(Rails.root+folder_path,'').sub('.jpg','')
    end
    return result
  end  

  # 计算某项资产的总值
  def sum_money_of( assets_code, currency = 'NTD', asset_belongs_to_id = 1, keyword = '', is_emergency = false, only_currency = '' )
    if not keyword.empty?
      asset_item_records = AssetItem.all( :include => :asset, :conditions => ["assets.code = ? and asset_belongs_to_id = ? and asset_items.title like '%"+keyword+"%'", assets_code, asset_belongs_to_id] )
    # 取出可用于紧急预备金的资产项目
    elsif is_emergency
      asset_item_records = AssetItem.all( :include => :asset, :conditions => ["assets.code = ? and asset_belongs_to_id = ? and is_emergency = ?", assets_code, asset_belongs_to_id, true] )
    # 只计算某种币别的资产
    elsif not only_currency.empty?
      asset_item_records = AssetItem.all( :include => :asset, :conditions => ["assets.code = ? and asset_belongs_to_id = ? and currency = ?", assets_code, asset_belongs_to_id, only_currency] )
    else
      asset_item_records = AssetItem.all( :include => :asset, :conditions => ["assets.code = ? and asset_belongs_to_id = ?", assets_code, asset_belongs_to_id] )
    end
    result = 0
    asset_item_records.each do |r|
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

  # 計算中心資產報表參數
  def prepare_center_asset_var
    get_asset_belongs_to_id
    # 流動資產总值
    @total_flow_assets = sum_money_of 'flow_assets', 'MCY', 2
    # 每月支出总额
    @total_month_use = sum_money_of 'month_use', 'MCY', 2
    # 预计收入总额
    @total_plan_get = sum_money_of 'plan_get', 'MCY', 2
    # 预计支出总额
    @total_plan_use = sum_money_of 'plan_use', 'MCY', 2
    # 计算家庭中心流动资产总值
    @total_family_center_assets = sum_money_of 'flow_assets', 'MCY', 2, '[家庭中心]'
    # 计算学生中心流动资产总值
    @total_student_center_assets = sum_money_of 'flow_assets', 'MCY', 2, '[学生中心]'
    # 计算家庭中心每月支出总值
    @total_family_center_month_use = sum_money_of 'month_use', 'MCY', 2, '[家庭中心]'
    # 计算学生中心每月支出总值
    @total_student_center_month_use = sum_money_of 'month_use', 'MCY', 2, '[学生中心]'
    # 计算中心每月收入总值
    @total_center_month_income = sum_money_of 'month_income', 'MCY', 2 
    # 資產净值
    @total_net_assets = @total_flow_assets + @total_plan_get - @total_plan_use
    # 若无收入，尚可支持几个月?
    @total_remain_cost_month = @total_net_assets / @total_month_use
  end  

  # 計算貸款利息总值
  def get_total_loan_interest_ntd_array( to_time = Time.now )
    total_loan_interests = []
    AssetItem.all(:include => :asset, :conditions => ["assets.code = ? and asset_belongs_to_id = ?", 'loan_items', 1]).each do |item|
      #計算每日利息
      day_interest = item.ntd_amount * (item.loan_interest_rate/100.0) / 365
      #計算已经经过的天数
      pass_days = day_diff_for_loan( item.loan_begin_date, to_time ) 
      #計算利息
      total_loan_interests << (day_interest * pass_days).round
    end
    return total_loan_interests
  end

  # 計算家庭資產報表參數
  def prepare_my_asset_var
    get_asset_belongs_to_id
    # 距离起日已有几日
    @start_count_date = value_of 'start_count_date'
    @start_count_diff = day_diff( @start_count_date, Time.now )
    # 距离退休还有几日
    @retire_date = value_of 'retire_date'
    @retire_date_diff = day_diff( Time.now - 8.hours, @retire_date )
    # 现金資產总值
    @total_flow_assets_ntd = sum_money_of 'flow_assets'
    @total_flow_assets = sum_money_of('flow_assets', 'NTD', 1)
    # 貸款項目总值
    @total_loan_items = sum_money_of('loan_items', 'NTD', 1)
    # 貸款利息总值
    @total_loan_interests_arr = get_total_loan_interest_ntd_array
    # 貸款本息总值
    @total_loan_value = @total_loan_items + @total_loan_interests_arr.sum.to_i
    # 救急基金总值
    @total_emergency_flow_assets = sum_of_emergency()
    # 每月支出总额
    @total_month_use = sum_money_of('month_use', 'NTD', 1)
    @total_month_use_mcy = @total_month_use / value_of('exchange_rates_MCY').to_f 
    # 计算救急基金可以维持家庭开销几个月
    @money_remain_months = sprintf("%0.1f", @total_emergency_flow_assets/@total_month_use.to_i)
    # 预计收入总额
    @total_plan_get = sum_money_of('plan_get', 'NTD', 1)
    # 预计支出总额
    @total_plan_use = sum_money_of('plan_use', 'NTD', 1)
    # 实际可用现金資產總值(不含固定资产)
    @total_net_assets = @total_flow_assets + @total_plan_get - @total_plan_use
    # 流動資產總值
    @total_current_assets = ((@total_flow_assets - @total_plan_use) - @total_loan_value).to_i
    # 固定資產总值
    @total_fixed_assets = sum_money_of('fixed_assets', 'NTD', 1)
    # 資產净值(流動資產總值+固定資產总值)
    @net_asset_value = @total_current_assets + @total_fixed_assets
    # 每月最多能存多少新台币
    @month_save_money_max = value_of('month_save_money_max').to_i * value_of('exchange_rates_MCY').to_f
    # 若无收入，尚可支持几个月?(包含预计的)
    @total_remain_cost_month = @total_net_assets / @total_month_use
    # 若无收入，尚可支持几个月?(不包含预计的)
    @total_remain_cost_month_real = @total_emergency_flow_assets / ( value_of('total_month_use_basic').to_f )
    # 退休后每日的生活费目标(新台币)
    @retire_daily_money = value_of 'retire_daily_money'
    # 台新银行年定存利率
    @year_rate = value_of('taixin_year_rate').to_f
    # 台新银每年定存目标
    @money_save_goals = value_of('money_save_goals').split(',')
    # 计算可列为定存目标的资产项目的总合
    @total_money_for_goal = AssetItem.total_money_for_goal     
    # 储蓄目标总值
    @total_goal_money = @retire_daily_money.to_i * @retire_date_diff.to_i
    # 尚需多少资金
    @total_remain_money = (@total_goal_money.to_i - @total_net_assets.to_i)
    # 尚需存款几个月/几年
    @total_remain_save_month = @total_remain_money / @month_save_money_max
    @total_remain_save_year = @total_remain_save_month / 12
    # 取出生活项目总分
    @total_mins_of_life_interest = value_of('count_mins_of_life_interest')
    # 千金難買的天數計算
    @total_days_of_life_interest = sprintf("%0.2f", value_of('count_mins_of_life_interest').to_f / 60 / 24)
    # 已經自由的天數計算
    @free_life_from_date = value_of 'free_life_from'
    @already_free_days = day_diff( @free_life_from_date, Time.now - 8.hours )   
    # 三不無影的天數計算
    @three_control_then_free_start_date = value_of 'three_control_then_free_start_date'
    @free_life_from = day_diff( @three_control_then_free_start_date, Time.now - 8.hours )    
    @rmb_rate = value_of('exchange_rates_MCY').to_f
  end
 
  ######################### 以下由模擬系統專用 #########################

  def sim_identity_arr
    [ ['學員','student'],['會員','member'],['全职會員','blessed_member'],['全职家庭','blessed_family']]
  end

  def sim_occupation_arr
    [ ['待業',0],['學生',1],['職工',2],['動員',3],['公職者',4],['指導者',5] ]  
  end

  def sim_blessing_arr
    [ ['2005全职式',100],['2009全职式',140],['2010全职式',150],['2011全职式',160],['2012全职式',170],['2013全职式',180],['2014全职式',190],['2015全职式',200],['2016全职式',210] ]
  end

  def sim_school_name_arr
    [ ['北京大学','1'],['清华大学','2'],['中国人民大学','3'],['北京师范大学','4'],['北京航空航天大学','5'],['北京理工大学','6'],['中国农业大学','7'],['北京协和医学院','8'],['北京科技大学','9'],['北京交通大学','10'],['北京邮电大学','11'],['中国政法大学','12'],['北京化工大学','13'],['中央财经大学','14'],['中央民族大学','15'],['北京林业大学','16'],['对外经济贸易大学','17'],['华北电力大学','18'],['北京工业大学','19'],['首都师范大学','20'],['其他學校','99'] ]
  end 

  def sim_school_major_arr
    [ ['哲学系','0101'],['经济学系','0201'],['财政学系','0202'],['金融学系','0203'],['经济与贸易','0204'],['法学系','0301'],['政治学系','0302'],['社会学系','0303'],['民族学系','0304'],['马克思主义理论系','0305'],['公安学系','0306'],['教育学系','0401'],['体育学系','0402'],['中国语言文学系','0501'],['外国语言文学系','0502'],['新闻传播学系','0503'],['历史学系','0601'],['数学系','0701'],['物理学系','0702'],['化学系','0703'],['天文学系','0704'],['地理科学系','0705'],['大气科学系','0706'],['海洋科学系','0707'],['地球物理学系','0708'],['地质学系','0709'],['生物科学系','0710'],['心理学系','0711'],['统计学系','0712'],['力学系','0801'],['机械系','0802'],['仪器系','0803'],['材料系','0804'],['能源动力系','0805'],['电气系','0806'],['电子信息学系','0807'],['自动化学系','0808'],['计算机学系','0809'],['土木工程学系','0810'],['水利工程学系','0811'],['测绘系','0812'],['化工与制药学系','0813'],['地质学系','0814'],['矿业学系','0815'],['纺织学系','0816'],['轻工学系','0817'],['交通运输学系','0818'],['海洋工程学系','0819'],['航空航天学系','0820'],['兵器学系','0821'],['核工程学系','0822'],['农业工程学系','0823'],['林业工程学系','0824'],['环境科学与工程学系','0825'],['生物医学工程学系','0826'],['食品科学与工程学系','0827'],['建筑学系','0828'],['安全科学与工程学系','0829'],['生物工程学系','0830'],['公安技术学系','0831'],['植物生产学系','0901'],['自然保护与环境生态','0902'],['动物生产学系','0903'],['动物医学系','0904'],['林业学系','0905'],['水产学系','0906'],['草学系','0907'],['基础医学系','1001'],['临床医学系','1002'],['口腔医学系','1003'],['中医学系','1005'],['公共卫生与预防医学','1004'],['中西医结合学系','1006'],['药学系','1007'],['中药学系','1008'],['法医学系','1009'],['医学技术学系','1010'],['护理学系','1011'],['管理科学与工程学系','1201'],['工商管理学系','1202'],['农业经济管理学系','1203'],['公共管理学系','1204'],['图书情报与档案管理','1205'],['物流管理与工程学系','1206'],['旅游管理学系','1209'],['工业工程学系','1207'],['电子商务学系','1208'],['艺术学理论学系','1301'],['音乐与舞蹈学系','1302'],['戏剧与影视学系','1303'],['美术学系','1304'],['设计学系','1305'] ]
  end

  def sim_educational_background_arr
    [ ['小學',1],['初中',2],['高中',3],['專科',4],['大學',5],['碩士',6],['博士',7] ]
  end