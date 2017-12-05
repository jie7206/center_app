require 'net/http'
require 'rexml/document'

class MainController < ApplicationController
  
  RSS_URL = [ '/news/marquee/ddt.xml',      #新闻要闻
                         '/news/world/focus15.xml',     #国际要闻
                         '/news/china/focus15.xml',     #国内要闻
                         '/news/society/focus15.xml',  #社会要闻
                         '/roll/finance/hot_roll.xml',     #财经要闻汇总
                         '/news/allnews/games.xml',    #游戏焦点新闻
                         '/ent/hot_roll.xml',                     #娱乐要闻汇总
                         '/news/china/hktaiwan15.xml',     #港澳台新闻
                         '/news/society/wonder15.xml'     #奇闻轶事
                        ]
  
  def login
    if params[:username] && params[:password] && pass_login( params[:username], params[:password] )
      #update_rss_files
      redirect_to_index
    else
      render :layout => "login"      
    end
  end

  def logout
    reset_session
    redirect_to :action => 'login'
  end  
  
  def pass_login( username, password )
    if username == 'admin' && password == '1mickey'
      #管理员身份
      session[:role] = 'admin'
      return true
    else
      #Guest身份
      session[:role] = 'guest'
      return true
    end
  end
  
  def show_warning
    @message = flash[:notice]
  end

  def show_message
    @message = flash[:notice]
    render :action => 'show_warning'
  end

  def auto_insert_members_from_remote

    members_xml_data = get_remote_files('localhost', '/members/index_simple.xml?cid=all', '', 3000, false)
    histories_xml_data = get_remote_files('localhost', '/histories.xml', '', 3000, false)
    @default_area_id = value_of('default_area_id')

    if members_xml_data and !members_xml_data.empty? and histories_xml_data and !histories_xml_data.empty?
      
      # 新增会员基本资料     
      h_members = Hash.from_xml(members_xml_data)
      n_members = 0
      h_members["members"].each do |m|
        if m["name"] != '林仕傑' and m["name"] != '林仕杰' and !Member.find_by_name(m["name"])
          Member.create( 
            :birthday => m["birthday"],
            :birthday_still_unknow => m["birthday_still_unknow"],
            :career => classification_mapping_to_career( m["classification"] ),
            :email => m["email"],
            :school => m["school"],
            :introducer_id => get_member_id( m["introducer_name"] ),
            :interest => m["interest"],
            :is_on_table => m["is_on_table"],
            :memo => m["memo"],
            :mobile => m["mobile"],
            :name => m["name"],
            :picture => m["picture"],
            :pray_note => m["pray_note"],
            :sex_id => m["sex"] == '男' ? 1 : 0,
            :area_id => @default_area_id )
          n_members += 1
        end
      end

      # 新增会员活动资料
      h_histories = Hash.from_xml(histories_xml_data)
      n_histories = n_traces = 0
      h_histories["histories"].each do |h|
        if !h["class_date"].nil? and h["class_date"] > value_of('class_date_start_date').to_date and h["class_teacher"] != '林仕傑' and !History.find(:first, :conditions => ["name = ? and class_date = ? and class_title = ?", h["name"], h["class_date"], h["class_title"]])
          h["name"] = '林仕傑' if h["name"] == '林仕杰'
          member_id = get_member_id(h["name"])
          History.create( 
            :member_id => member_id,
            :area_id => @default_area_id,
            :name => h["name"], 
            :class_date => h["class_date"], 
            :class_teacher => h["class_teacher"], 
            :class_title => h["class_title"], 
            :class_feel => h["class_feel"], 
            :class_type => get_class_type(h["class_type"]) )
          n_histories += 1
          n_traces += 1 if update_trace_data(member_id,h)
        end
      end
      flash[:notice] = "已成功新增#{n_members}笔会员基本资料，新增#{n_histories}笔会员活动资料，更新#{n_traces}笔会员进度资料！"
    else
      flash[:notice] = "服务器连线有问题!请确认localhost:3000/members/index_simple.xml?cid=all及localhost:3000/histories.xml能正常读取!此次自动更新并未执行!"
    end
    redirect_to :controller => :members, :action => :index
  end

  def classification_mapping_to_career( classification_value )
    # from: ['群眾基台','0'],['學生學員','1'],['職工學員','1.5'],['學生會員','2'],['職工會員','3'],['獻身會員','4']
    # to: ['祝福会员','0'],['二世子女','5'],['单身公职','3'],['學生會員','1'],['職工會員','2'],['學生學員','6'],['職工學員','7'],['群眾','99']
    case classification_value
      when '0'
        '99'
      when '1'
        '6'
      when '1.5'
        '7'
      when '2'
        '1'
      when '3'
        '2'
      when '4'
        '3'
      else
        '99'
    end      
  end

  def get_member_id( name )
    if name and !name.empty?
      m = Member.find_by_name(name)
      m ? m.id : nil
    end
  end

  def get_class_type( class_type_code )
    if class_type_code and !class_type_code.empty?
      class_type_code
    else
      value_of 'default_class_type_code'
    end
  end

  def update_trace_data( member_id, h )
    trace = Trace.find_by_member_id(member_id)
    if trace and trace.update_attributes(
            :aid => @default_area_id,
            :last_class_date => h["class_date"], 
            :last_class_teacher => h["class_teacher"], 
            :last_class_title => h["class_title"], 
            :class_feel => h["class_feel"], 
            :class_type => get_class_type(h["class_type"]) )
      return true
    end
    return false
  end

  def update_rss_files
    @remote_server_disconnect = false
    RSS_URL.each do |url|
      get_remote_files( 'rss.sina.com.cn',  url, RAILS_ROOT+'/public/rss/'+url.split('/').join('_').slice(1..-1) ) if not @remote_server_disconnect
    end
  end
  
  def forgot_password
    render :layout => "login"
  end
  
  def process_forgot_password
    if params[:email] && params[:username] && acc_id = Account.check_account_exist( params[:email], params[:username] )
      Notifier.deliver_renew_password_confirm(params[:email],params[:username],acc_id,Account.create_hash_key(params[:username]))
      render :text => "請到#{params[:email]}收取郵件，點按郵件中的連結重設密碼！"
   else
      flash[:notice] = "所輸入的郵箱或帳號有誤，請重新輸入！"
      redirect_to :action => "forgot_password"
    end
  end
    
  def renew_password_form
    if params[:aid] && params[:key] && acc = Account.check_hash_key( params[:aid], params[:key] )
      @acc_id = acc.id
      @username = acc.username      
      render :layout => "login"     
    else
      render :text => "申請新密碼資料有誤或已經過期！請重新申請。"
    end
  end
  
  def renew_password
    if params[:acc_id] && params[:new_password] && params[:new_password].size >= 4 && params[:new_password_check] && params[:new_password_check].size >= 4 && ( params[:new_password] == params[:new_password_check] )
      Account.renew_password( params[:acc_id], params[:new_password] )
      flash[:notice] = "密碼已經更新，請以新的密碼重新登入！"
      redirect_to :action => "login"
    else
      @acc_id = params[:acc_id]
      @username = params[:username]     
      flash[:notice] = "密碼長度過短(少於四位數)或輸入的新密碼和確認密碼不同，請重新輸入！"
      render :action => "renew_password_form", :layout => "login"
    end
  end

  # 更新某项资产的值
  def update_asset_item_amount
    if params[:new_amount].to_f != params[:ori_amount].to_f
      @asset_item = AssetItem.find(params[:id])
      @asset_item.update_attribute(:amount,params[:new_amount])      
      auto_create_or_update_asset_item_detail( params[:id], params[:new_amount] ) if params[:new_amount] != params[:ori_amount]
      # 当我的家庭流动资产变化的时候，自动更新Param中与资产相关的项目，并自动加入或更新ParamChange以追踪变化记录
      update_my_assets_and_insert_change_record if @asset_item.asset_belongs_to_id == 1
      flash[:notice] = "已成功更新为#{params[:new_amount]}"
    end
    redirect_to(asset_items_url)
  end


  def update_param_value
    @param = Param.find(params[:id])
    params[:field_name] ||= 'value'
    @param.update_attribute(params[:field_name],params[:new_value])
    if params[:field_name] == 'value' and @param.rec_change and params[:new_value] != params[:ori_value]
      auto_create_param_change( params[:id], params[:new_value], params[:ori_value] )
    end    
    flash[:notice] = "第#{@param.order_num}项已更新为#{params[:new_value]}"
    redirect_to(params_url)
  end 

  def life_chart
    # 取出生活项目的资料记录
    @histories = get_life_interest_records
    @max_record_num_for_chart = params[:limit] ? params[:limit] : 50000
    @addition_note = ""
    if @histories.size > @max_record_num_for_chart.to_i
      @addition_note = "[共有#{@histories.size}筆，但因效能限制，最多只能顯示#{@max_record_num_for_chart}筆]"
      @histories = @histories[0,@max_record_num_for_chart]      
    end
    @names = []
    @dates = []
    # 决定日期表格资料的起始日与最终日并设定好dates_arr的内容
    @dates = prepare_dates_arr_data( @dates, @histories, 'rec_date', 'desc', true )

    # 計算家庭資產報表參數
    prepare_my_asset_var
    # 取出歷史上的今天的资料
    @today_in_histories = History.find_by_sql("select class_date,class_teacher,name,class_title from histories where name != '林仕傑' and strftime('%m-%d',class_date)='#{Date.today.to_s(:db)[5,5]}' and strftime('%Y',class_date)<'#{Date.today.year}' group by 'class_title' order by 'class_date'")
    @today_in_param_changes = ParamChange.find_by_sql("select rec_date,title,change_value from param_changes where change_value >= #{value_of('mins_of_show_today_event')} and length(title) > 3 and strftime('%m-%d',rec_date)='#{Date.today.to_s(:db)[5,5]}' and strftime('%Y',rec_date) < '#{Date.today.year}' order by 'rec_date'")   
    @today_images_in_folder = get_file_names "public/images/#{@my_photo_path}", "_#{add_zero(Date.today.month,2)}#{add_zero(Date.today.day,2)}_"
  end

  def life_list
    # 取出生活项目的资料记录
    @life_interest_records = get_life_interest_records
    @enjoy_life_title = value_of('enjoy_life_title')
  end

  def life_list_on_day
    life_interest_ids = Param.all( :conditions => "name like 'life_interest_%'" ).collect {|p| [ p.id ] }.join(',')
    @life_interest_records = ParamChange.all( :conditions => "change_value > 0 and param_id in ("+life_interest_ids+") and rec_date = '#{params[:rec_date]}'", :order => "created_at", :include => :param )
    @enjoy_life_title = value_of('enjoy_life_title')
    render :action => 'life_list'
  end

  def enjoy_life_list( limit = 50000 )
    # 取出千金難買的生活资料记录
    @life_interest_records = ParamChange.all( :limit => limit, :conditions => [ "is_enjoy = ?", true ], :order => "rec_date desc, title" )
    @enjoy_life_title = value_of('enjoy_life_title')
    @dont_show_check_box = 'yes'
    render :action => 'life_list'
  end

  # 将自我主管起算日设为今天
  def set_three_control_then_free_to_today
    update_param_record_to_today( 'max_record_days_for_three_control', 'three_control_then_free_start_date' )
    redirect_to :action => 'life_chart'
  end

  # 将亲密关系起算日设为今天
  def set_sex_life_to_today
    update_param_record_to_today( 'max_record_days_for_sex_life', 'free_life_from' )
    redirect_to :action => 'life_chart'
  end  

  # 将與日期相關的起算日设为今天並自動累計日期記錄
  def update_param_record_to_today( max_record_days, start_date )
    # 如果创新高则更新最高记录
    max_record_days_for_three_control = value_of(max_record_days).to_i
    free_life_from = day_diff( value_of(start_date), Time.now - 8.hours ).to_i
    if free_life_from > max_record_days_for_three_control
      Param.find_by_name(max_record_days).update_attribute( :value, free_life_from.to_s )
    end
    # 将起算日设为今天並自動累計日期記錄
    p = Param.find_by_name(start_date)
    today = Date.today.to_s(:db)
    note = today + "\n" + p.content
    p.update_attributes( :value => today, :content => note )
  end

  # 将所选资料列入千金難買
  def mutli_update_is_enjoy
    pcids = params[:pcids].to_a
    count = 0
    pcids.each do |pc_id|
      ParamChange.find(pc_id).update_attribute( :is_enjoy, true )
      count += 1
    end
    flash[:notice] = "#{count}笔紀錄更新成功！"
    redirect_to :action => 'life_list'
  end

  # 根据生活类别自动更新资料列入千金難買
  def auto_mutli_update_is_enjoy
    pids = [73,78,56,77,32,81,44,36,35,76,66,45,93]
    count = 0
    pids.each do |pid|
      ParamChange.all( :conditions => [ "param_id = ?", pid ] ).each do |pc|
        pc.update_attribute( :is_enjoy, true )
        count += 1
      end
    end
    render :text => "#{count}笔紀錄更新成功！"
  end

  # 显示组织架构图
  def show_structure
  end

  # 购屋试算
  def buy_house_plan

  end

  # 执行购屋试算的计算(开始年度, 指定年度，结束年度, 房产总价, 每月存款, 保单贷款, 贷款利率, 每月出租, 增值利率, 退休年份, 指定哪一年的存款(例如2029)，指定年的存款利率, 退休每月保费直到指定年, 退休月生活费最大值直到指定年，购房前存款)
  def exe_cal_house_plan(begin_year, save_year, end_year, house_value, month_save, loan_total, loan_rate, month_rent, added_rate, retire_year, save_rate, insurance_after_retire, expenses_after_retire, ori_save_money)

    #建立基础变数

      #年度阵列
      years = (begin_year..end_year).to_a

      #金如意按年还本 2016:10000+30560(小虎的保险还本+解约)=40560+47000-23412*3(=70236健康险)-3000*2(金如意附约)=11324-->10000(剩余可还爸妈的钱) 还差10万以后再想办法还(ex:2017还1万+2018还2万+2019还3万+2020还4万=10万)
      #如果买房，则2016年先不还爸妈10万，但若不买房，则需还爸妈10万，但是需加上已有的存款252000元和经过一年的利息
      money_backs_tw_2016 = house_value > 0 ? 300000 : 200000 + ori_save_money*(1+(save_rate/100))

      money_backs_tw = [money_backs_tw_2016,0,0,291000,0,0,291000,0,0,291000,0,0,291000,0,0,97000,97000,97000,97000,97000,97000,97000,97000,97000,300000,0,0,300000,0,0,300000,0,0,300000,0,0,300000,0,0]
      #最末年的一諾中档 + 社保还本换算成新台币的值，以下是2030年的值
      money_backs_cn = ( 10863 + 18000 ) * @exchange_rates_MCY
      #以下是2031年的值
      money_backs_cn_2031 = ( 11047 + 18270 ) * @exchange_rates_MCY
      
      #工资存款阵列(换算成新台币/年)
      month_saves = []
      work_save_ntd = (month_save*12*@exchange_rates_MCY).to_i
      (begin_year...retire_year).each { month_saves << work_save_ntd }
      (retire_year..end_year).each { month_saves << 0 }
      
      #房租收益阵列(换算成新台币/年)
      year_rent = month_rent*12*@exchange_rates_MCY #第一年的房租
      house_rents = [year_rent]
      years[1..-1].each do
        this_year_rent = year_rent * ( 1 + added_rate/100 )
        house_rents << this_year_rent
        year_rent = this_year_rent
      end

      #房产总值阵列(换算成新台币/年)
      year_value = house_value
      house_values = [year_value]
      years[1..-1].each do
        this_year_value = (year_value*(1+added_rate/100)).to_i
        house_values << this_year_value
        year_value = this_year_value
      end      

    ########## 计算贷款利息总值 ##########

      #当年收入阵列(换算成新台币/年)
      year_incomes = cal_year_incomes(begin_year,end_year,month_saves,house_rents,money_backs_tw)

      #保单贷款本金阵列 及 保单贷款利息阵列(换算成新台币/年)
      loan_totals = [loan_total.to_i]    #本金阵列
      loan_interests = [0]               #利息阵列
      if loan_total > 0 #如果有贷款
        i=0
        (begin_year+1..save_year).each do
          loan_total_value = (loan_totals[i]-(year_incomes[i]-loan_interests[i])).to_i
          loan_total_value > 0 ? loan_totals << loan_total_value : loan_totals << 0
          loan_interest_value = (loan_totals[i]*(loan_rate/100)).to_i  
          loan_interest_value > 0 ? loan_interests << loan_interest_value : loan_interests << 0
          i += 1
        end
      end

      #贷款利息总值
      sum_of_loan_interests = loan_interests.sum
    
    ########## 计算贷款还清年份 ##########

      #贷款还清年份
      end_year_of_loan_total = begin_year #如果没有贷款
      end_year_of_loan_total = years[loan_totals.index(0)-1] if loan_total > 0 #如果有贷款

      #计算出最早的退休年份值为贷款还清年份的下一年
      min_retire_year = end_year_of_loan_total + 1
      #如果使用者输入的退休年份小于min_retire_year，则更新退休年份为min_retire_year
      if retire_year < min_retire_year
        retire_year = min_retire_year
        #更新工资存款阵列
        (begin_year...retire_year).each { |y| month_saves[years.index(y)] = work_save_ntd }
        (retire_year..end_year).each { |y| month_saves[years.index(y)] = 0 }
        #更新当年收入阵列
        year_incomes = cal_year_incomes(begin_year,end_year,month_saves,house_rents,money_backs_tw)
      end

    ########## 计算指定年存款总值 ##########

      #计算从哪一年开始有存款，亦即计算那一年的 当年收入 - 当年支出 > 保单贷款本金

        #计算贷款还清年份的那一年，剩余多少存款
        #第一年开始有存款的值 = 当年收入 - 当年保单贷款利息 - 保单贷款本金
        yindex = years.index(end_year_of_loan_total)
        first_save_money = year_incomes[yindex] - loan_interests[yindex] - loan_totals[yindex]

        #计算退休之前的总存款
        save_money_before_retire = first_save_money
        if (retire_year - end_year_of_loan_total) >= 1
          (end_year_of_loan_total+1...retire_year).each do |y|
            yindex = years.index(y)
            loan_interest_in_this_year = loan_interests[yindex] ? loan_interests[yindex] : 0
            #退休之前的总存款 = 上一年的存款和利息 + (本年度收入 - 本年度应缴的贷款利息)
            save_money_before_retire = (save_money_before_retire*(1+(save_rate/100))).to_i + (year_incomes[yindex] - loan_interest_in_this_year)
          end
        end

        #计算从退休之年开始，直到指定年的剩余贷款利息
        remain_loan_interest = loan_interests[years.index(min_retire_year)] ? loan_interests[years.index(min_retire_year)] : 0
        #若退休当年还有贷款利息要缴，则退休之前的总存款必须扣除此笔贷款利息才会正确
        if (retire_year - end_year_of_loan_total) == 1
          save_money_before_retire  = save_money_before_retire - remain_loan_interest        
        end

      #计算从退休之年开始，直到指定年的总存款值
      #分两种情况，一种是买房，另一种是不买房

      #买房的情况：不需要计算存款利息，因为存款利息太少
#      if house_value > 0

        #起始存款
        balance_save_until_save_year = save_money_before_retire
        #每年固定的支出
        year_expenses = (expenses_after_retire+insurance_after_retire)*12*@exchange_rates_MCY
        (retire_year..save_year).each do |y|
          #当年的存款总值 = 上一年的存款和利息 + 当年收入 - (内地每月保费+每月生活费)*12*汇率
          balance_save_until_save_year = balance_save_until_save_year*(1+(save_rate/100)) + year_incomes[years.index(y)] - year_expenses
        end
        balance_save_until_save_year = balance_save_until_save_year.to_i

=begin
        #计算从退休之年开始，直到指定年的总收入
        total_income_until_save_year = 0
        (retire_year..save_year).each { |y| total_income_until_save_year += year_incomes[years.index(y)] }

        #计算从退休之年开始，直到指定年的每年应缴保费总值
        total_insurance_until_save_year = 0
        if retire_year < save_year
          (retire_year..save_year).each { |y| total_insurance_until_save_year += (insurance_after_retire*12*@exchange_rates_MCY).to_i }
        end

        #计算从退休之年开始，直到指定年的每年生活费总值
        total_expenses_until_save_year = 0
        if retire_year < save_year

          #计算是否有剩余存款：总收入 + 退休之前的总存款 - 剩余贷款利息 - 应缴保费总值
          remain_save_money_for_retire_expenses = total_income_until_save_year + save_money_before_retire - remain_loan_interest - total_insurance_until_save_year
          if remain_save_money_for_retire_expenses > 0
            remain_years_until_save_year = save_year-(retire_year-1)
            if remain_years_until_save_year > 0
              #最低增减单位为100元
              expenses_after_retire = (remain_save_money_for_retire_expenses.to_f/(remain_years_until_save_year*12*@exchange_rates_MCY.to_f)/100.0).to_i * 100
              
              #有输入(指定)生活费最大值的情况
              if expenses_after_retire_max > 0 and expenses_after_retire >= expenses_after_retire_max
                expenses_after_retire = expenses_after_retire_max
              end
            end
            total_expenses_until_save_year = (expenses_after_retire*12*@exchange_rates_MCY).to_i * (save_year-(retire_year-1))
          end

        end

        #从退休之年开始，直到指定年的总存款值 = 总收入 + 退休之前的总存款 - ( 应缴保费总值 + 每年生活费总值 )
        balance_save_until_save_year = total_income_until_save_year + save_money_before_retire - ( total_insurance_until_save_year + total_expenses_until_save_year )

      #不买房的情况：需要计算存款利息
      else

        #起始存款
        balance_save_until_save_year = save_money_before_retire
        #每年固定的支出
        expenses_after_retire = expenses_after_retire_max
        year_expenses = (expenses_after_retire+insurance_after_retire)*12*@exchange_rates_MCY
        (retire_year..save_year).each do |y|
          #当年的存款总值 = 上一年的存款和利息 + 当年收入 - (内地每月保费+每月生活费)*12*汇率
          balance_save_until_save_year = balance_save_until_save_year*(1+(save_rate/100)) + year_incomes[years.index(y)] - year_expenses
        end
        balance_save_until_save_year = balance_save_until_save_year.to_i
        
      end
=end

    ########## 计算最末年的房产总值 ##########

      #最末年的房产总值
      house_value_to_end_year = house_values[years.index(end_year)]

    ########## 计算最末年起月收入 ##########

      #最末年起月收入(出租) = 房租收益 + 在台保险 + 一諾中档 + 社保还本 + 定存利息
      month_income_to_end_year_ntd = ((house_rents[years.index(end_year)] + money_backs_tw[years.index(end_year)] + money_backs_cn + balance_save_until_save_year*(save_rate/100))/12).to_i
      #最末年起月收入(自住) = 在台保险 + 一諾中档 + 社保还本 + 定存利息
      month_income_to_end_year_ntd_self_live = ((money_backs_tw[years.index(end_year)] + money_backs_cn + balance_save_until_save_year*(save_rate/100))/12).to_i
      #最末年起月收入(卖出) = 在台保险 + 一諾中档 + 社保还本 + 定存利息(包含指定年的房价) 
      month_income_to_end_year_ntd_sell_house = ((money_backs_tw[years.index(end_year)] + money_backs_cn + (balance_save_until_save_year+house_values[years.index(save_year)])*(save_rate/100))/12).to_i


    ####################  回传结果 ####################

    result = {}

      #退休年龄
      result[:retire_year] = retire_year
      #房产总价
      result[:house_value] = house_value
      #每月存款
      result[:month_save] = month_save
      #贷款总额
      result[:loan_total] = loan_total
      #利息总额
      result[:sum_of_loan_interests] = sum_of_loan_interests
      #每月出租
      result[:month_rent] = month_rent
      #增值利率
      result[:added_rate] = added_rate
      #还清年份
      result[:end_year_of_loan_total] = end_year_of_loan_total
      #退休年份
      result[:retire_year] = retire_year
      #每月可用
      result[:expenses_after_retire] = expenses_after_retire
      #存款总值
      result[:balance_save_until_save_year] = balance_save_until_save_year
      #房产总值
      result[:house_value_to_end_year] = house_value_to_end_year
      #出租月入
      result[:month_income_to_end_year_ntd] = month_income_to_end_year_ntd
      #自住月入
      result[:month_income_to_end_year_ntd_self_live] = month_income_to_end_year_ntd_self_live
      #卖出月入
      result[:month_income_to_end_year_ntd_sell_house] = month_income_to_end_year_ntd_sell_house
      #退休之前的总存款
      result[:save_money_before_retire] = save_money_before_retire
      #退休当年房租 (人民币/年)
      result[:house_rent_at_retire_year] = (house_rents[years.index(retire_year)]/@exchange_rates_MCY).to_i

    return result

  end

  # 计算购屋试算结果
  def cal_house_plan

    #人民币兑换新台币汇率
    @exchange_rates_MCY = value_of('exchange_rates_MCY').to_f

    #获取和设定所有参数
    house_value = (params["house_value"].to_f*10000*@exchange_rates_MCY).to_i     #购房总价(万人民币转成新台币)
    month_save = params["month_save"].to_i                                        #每月存款(人民币)
    ori_save_money = params["ori_save_money"].to_i                                #购房前的存款
    self_money = params["self_money"].to_f*@exchange_rates_MCY + ori_save_money   #自备购房款(万人民币)
    #if house_value > 0
    #  loan_total = (params["house_value"].to_f*10000*@exchange_rates_MCY-self_money).to_i  #贷款总额(万人民币转成新台币)
    #else
    #  loan_total = 0
    #end
    loan_total = params["loan_total"].to_i    #贷款总额(新台币)
    loan_rate = params["loan_rate"].to_f     #贷款利率
    month_rent_begin = params["month_rent_begin"].to_i    #每月出租(开始)
    month_rent_end = params["month_rent_end"].to_i        #每月出租(结束)
    month_rent_step = params["month_rent_step"].to_i      #每月出租(幅度)
    added_rate_begin = params["added_rate_begin"].to_f    #增值利率(开始)
    added_rate_end = params["added_rate_end"].to_f        #增值利率(结束)
    added_rate_step = params["added_rate_step"].to_f      #增值利率(幅度)
    retire_year_begin = params["retire_year_begin"].to_i  #退休年份(开始)
    retire_year_end = params["retire_year_end"].to_i      #退休年份(结束)
    expenses_after_retire_begin = params["expenses_after_retire_begin"].to_i    #退休月生活费(开始)
    expenses_after_retire_end = params["expenses_after_retire_end"].to_i        #退休月生活费(结束)
    expenses_after_retire_step = params["expenses_after_retire_step"].to_i      #退休月生活费(幅度)
    save_rate = params["save_rate"].to_f                  #2029年存款利率
    insurance_after_retire = params["insurance_after_retire"].to_i        #退休每月保费 直到2029
    begin_year = 2016
    save_year = 2029
    end_year = 2031

    @results = []
    @house_value = params["house_value"] #购房总价
    @loan_total = sprintf("%0.00f",loan_total/10000/@exchange_rates_MCY.to_f)  #贷款总额(万人民币)
    @save_rate = save_rate    #2029年存款利率
    @self_money = (self_money/10000*@exchange_rates_MCY).to_i  #自备购房款(万人民币)
    @added_rate_begin = added_rate_begin #增值利率(开始)
    @expenses_after_retire_max = expenses_after_retire_begin #退休月生活费 直到2029
    month_rents = month_rent_begin > 0 ? build_increase_array( month_rent_begin, month_rent_end, month_rent_step ) : [0]
    added_rates = added_rate_begin > 0 ? build_increase_array( added_rate_begin, added_rate_end, added_rate_step ) : [0]
    retire_expenses = build_increase_array( expenses_after_retire_begin, expenses_after_retire_end, expenses_after_retire_step )
    (retire_year_begin..retire_year_end).each do |retire_year|
      month_rents.each do |month_rent|
        added_rates.each do |added_rate|
          retire_expenses.each do |expenses_after_retire_max|
            result = exe_cal_house_plan(begin_year, save_year, end_year, house_value, month_save, loan_total, loan_rate, month_rent, added_rate, retire_year, save_rate, insurance_after_retire, expenses_after_retire_max, ori_save_money)
            #将2029存款总值>0的加入回传阵列
            @results << result if result[:balance_save_until_save_year] > 0
          end
        end
      end
    end

    #设定网页标题
    @page_title = "購屋#{@house_value}萬貸款#{@loan_total}萬試算结果"
    render :layout => "login"
    #render :text => @t #@t=year_incomes[years.index(2016)];return
  end

  #建立容许小数点的利率渐增阵列
  def build_increase_array( begin_num, end_num, step_num )
    result = [begin_num]
    value = begin_num
    while value < end_num do
      value += step_num
      result << value if value < end_num
    end
    result << end_num
    return result
  end

  #计算当年收入阵列(换算成新台币/年)
  def cal_year_incomes(begin_year,end_year,month_saves,house_rents,money_backs_tw)
    year_incomes = []
    i = 0
    (begin_year..end_year).each do
      year_incomes << month_saves[i].to_i + house_rents[i].to_i + money_backs_tw[i].to_i
      i += 1
    end
    return year_incomes
  end

  # 为显示圣言预备参数
  def prepare_golden_verse_and_params
    if params[:main_keywords_for_search]
      keywords = params[:main_keywords_for_search]
    else
      keywords = params[:keywords] || nil
    end
    list_collect = params[:list_collect] || nil
    get_book_data # 读取书籍设定资料
    golden_verse_main_func(keywords,list_collect)
  end

  # 读取书籍设定资料
  def get_book_data
    @verse_book = Book.first( :conditions => ["is_default = ?", true] )
    @verse_book_name = @verse_book.name
    @verse_book_title = @verse_book.title
    @verse_book_filename = @verse_book.filename
    @verse_book_bg_filename = @verse_book.bg_filename
    if params[:for_ppt]
      @verse_book_collect = @verse_book.collect_for_ppt
      @save_collect_field = 'collect_for_ppt'
      @save_collect_title = @verse_collect_for_ppt_title
    else
      @verse_book_collect = @verse_book.collect_for_me
      @save_collect_field = 'collect_for_me'
      @save_collect_title = @verse_collect_for_me_title
    end
  end

  # 随即取出一句新版天圣经中的圣言
  def show_golden_verse
    prepare_golden_verse_and_params
  end

  # 在固定好看的背景中显示圣言
  def show_golden_verse_with_fix_bg
    prepare_golden_verse_and_params
    @bg_image = @verse_book_bg_filename
    @verse ||= @verses[@index]
    render :layout => 'fix_bg'
  end

  # 显示所有收藏的圣言
  def show_golden_verse_collection
    golden_verse_main_func( nil, true )
    render :template => 'main/show_golden_verse'
  end

  # 清空所有收藏的圣言
  def delete_all_verse_collection
    get_book_data
    @verse_book.update_attribute(@save_collect_field,'')
    flash[:notice] = "已清空在#{@save_collect_title}里所有的内容！"
    redirect_to :action => :show_golden_verse_collection, :for_ppt => params[:for_ppt]
  end  

  # 收藏某句圣言
  def collect_golden_verse
    if params[:i] and params[:i].to_i >= 0
      save_collect_arr( get_collect_arr << params[:i] )
    end
    flash[:notice] = "索引值为#{params[:i]}的金句已在#{@save_collect_title}里收藏成功！"
    action_name = params[:rta] || "show_golden_verse"
    redirect_to :action => action_name, :i => params[:i].to_i+1, :for_ppt => params[:for_ppt]
  end

  # 删除某句圣言
  def delete_collect
    collect_arr = get_collect_arr
    collect_arr.delete(params[:i])
    save_collect_arr( collect_arr )
    flash[:notice] = "索引值为#{params[:i]}的内容已在#{@save_collect_title}里删除成功！"
    action_name = params[:rta] || "show_golden_verse_collection"
    redirect_to :action => action_name, :list_collect => true, :for_ppt => params[:for_ppt]
  end

  # 取出储存圣句资料的阵列
  def get_collect_arr
    get_book_data if !@verse_book
    if @verse_book_collect
      return @verse_book_collect.split(",")
    else
      return []
    end
  end

  # 储存圣句资料的阵列
  def save_collect_arr( collect_arr )
    get_book_data
    collect_arr.uniq!
    @verse_book.update_attribute(@save_collect_field,collect_arr.join(","))
  end

  # 将某金句储存的次序移动到最上面
  def verse_collect_order_top
    collect_arr = get_collect_arr
    i = collect_arr.index(params[:i])
    if i != 0
      collect_arr.delete(params[:i])
      collect_arr = [params[:i]] + collect_arr
      save_collect_arr( collect_arr )
      flash[:notice] = "索引值为#{params[:i]}的金句已移动到最上面！"
    end
    after_verse_order_then_redirect_to
  end

  # 将某金句储存的次序移动到最底部
  def verse_collect_order_bottom
    collect_arr = get_collect_arr
    i = collect_arr.index(params[:i])
    if i != collect_arr.size-1
      collect_arr.delete(params[:i])
      collect_arr << params[:i]
      save_collect_arr( collect_arr )
      flash[:notice] = "索引值为#{params[:i]}的金句已移动到最底部！"
    end
    after_verse_order_then_redirect_to
  end

  # 将某金句储存的次序往上移动
  def verse_collect_order_up
    collect_arr = get_collect_arr
    i = collect_arr.index(params[:i])
    if i != 0
      temp_value = collect_arr[i-1]
      collect_arr[i-1] = params[:i]
      collect_arr[i] = temp_value
      save_collect_arr( collect_arr )
      flash[:notice] = "索引值为#{params[:i]}的金句已上移成功！"
    end
    after_verse_order_then_redirect_to
  end

  # 将某金句储存的次序往下移动
  def verse_collect_order_down
    collect_arr = get_collect_arr
    i = collect_arr.index(params[:i])
    if i != collect_arr.size-1
      temp_value = collect_arr[i+1]
      collect_arr[i+1] = params[:i]
      collect_arr[i] = temp_value
      save_collect_arr( collect_arr )
      flash[:notice] = "索引值为#{params[:i]}的金句已下移成功！"
    end
    after_verse_order_then_redirect_to
  end

  def after_verse_order_then_redirect_to
    redirect_to :action => 'show_golden_verse_collection', :list_collect => true, :for_ppt => params[:for_ppt]
  end

  # 随即取出一句新版天圣经中的圣言(主程序)
  def golden_verse_main_func( keywords = nil, list_collect = false, min_length = 40, max_length = 2000 )
    get_book_data if !@verse_book
    @golden_verse_title = @verse_book_title
    @collect_arr = get_collect_arr # 无论怎样都得用，故放此
    source = ''
    File.open(RAILS_ROOT+"/txt/#{@verse_book_filename}") {|f| source = f.read}
    if not source.empty?
      @verses = [] ; result_arr = [] ; i = 0
      source.each_line do |line|
        pattern_begin = //
        pattern_end = /(。)$+|(？)$+|(”)$+|(！)$+|(」)$+/
        if line.length >= min_length and line.length <= max_length and line.index(pattern_end)         
          if keywords and !keywords.empty? # 如果有输入搜索关键字
            if line.index(keywords)
              @verses << line.sub(pattern_begin,'')
              result_arr << i              
            end
          elsif list_collect
            order_i = @collect_arr.index(i.to_s)
            @verses[order_i] = line.sub(pattern_begin,'') if order_i
          else
            @verses << line.sub(pattern_begin,'')
          end
          i += 1
        end
      end
    end
    if keywords and !keywords.empty? # 如果有输入搜索关键字
      @index = params[:i] ? params[:i].to_i : 0
      @index = check_index_boundary(@index, @verses.size)
      @keywords = keywords
      @verses_index = result_arr
    elsif list_collect
      @list_collect = list_collect # 是否显示收藏 (True/False)
      order_verses_by_addin? false # 是否最后加入的金句显示在第一个
      @index = params[:i] ? params[:i].to_i : @verses_index[0].to_i
    else
      if @collect_arr.size > 0 and params[:rand_collect]
        @index = rand(@collect_arr.size-1)
        @verse = @verses[@collect_arr[@index].to_i] # 收藏里显示单句
      else
        @index = params[:i] ? params[:i].to_i : rand(@verses.size-1) # @index = 159 #(1147)    
        @verse = @verses[check_index_boundary(@index,@verses.size)] # 随机里显示单句
      end      
    end
  end 

  # 是否最后加入的金句显示在第一个
  def order_verses_by_addin?( flag )
    if flag == true
      @verses = @verses.reverse
      @verses_index = @collect_arr.reverse
    else
      @verses_index = @collect_arr
    end
  end

  # 视频字幕自动加上开始时间表单
  def auto_add_str_start_time_form

  end
 
  # 处理视频字幕自动加上开始时间
  def auto_add_str_start_time_result
    source = params[:text_content]
    @result = "" ; sub_flag = false 
    end_time = params[:start_time] #"00:00:00,000"
    if not source.empty?
      source.each_line do |line|
        if line.index(/^(\d)/)
          if line.index(/^(00:00:00,000)/)
            #将文本的第二行的 00:00:00,000 强制改成 00:00:00,100，否则第二次执行会出错
            if sub_flag # 编号为1的下一行
              line.sub!('00:00:00,000','00:00:00,100')
              sub_flag = false
              @result += line
              next
            end
            @result += end_time + line[12..-1]
            end_time = line[17,12]
          #将文本的第二行的 00:00:00,000 强制改成 00:00:00,100，否则第二次执行会出错
          elsif line.index(/^1/) # 编号为1的下一行
            #sub_flag = true if line.to_i == 1
            @result += line
          else
            @result += line
          end
        elsif line.length > 1
          @result += line
        end
      end
    end    
  end

  # 显示退休试算表单/结果
  def cal_retire_day
  end

  # 执行收支试算并显示结果
  def cal_retire_plan
  end

end
