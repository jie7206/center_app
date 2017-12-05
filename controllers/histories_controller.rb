class HistoriesController < ApplicationController
  
  def index
    @histories = session[:role] == 'admin' ? History.all( :order => 'class_date desc', :limit => 100000 ) : []

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @histories }
    end
  end

  def index_for_member
    @histories = History.all( :order => 'class_date desc', :conditions => "member_id = #{params[:mid]}")
    render :action => 'index'
  end

  def index_for_today
    @histories = History.find_by_sql("select * from histories where name != '林仕傑' and strftime('%m-%d',class_date)='#{Date.today.to_s(:db)[5,5]}' and strftime('%Y',class_date)<'#{Date.today.year}' order by 'class_date'")
    render :action => 'index'
  end  

  def index_for_class_type
    @histories = History.all( :order => 'class_date desc', :conditions => [ "area_id = ? and class_type = ?", session[:default_area_id], params[:class_type] ] )
    @sub_title = class_type_arr.rassoc(params[:class_type])[0]
    render :action => 'index'
  end

  def index_by_month_peroid
    session[:show_histories_chart] = false
    build_index_by_month_peroid
    render :action => 'index'
  end

  def update_ctypes
    n = 0
    
    # Member.update_all("classification='4'")
    # Trace.update_all("is_public_class='1'")
    # History.update_all("is_public_class='1'")
=begin    
    str = ""
    (3492..3521).each do |n|
      str = str + n.to_s + ','
    end
    str = str[0..-2]
    n = 0
    History.find_by_sql("select * from histories where id in (#{str})").each do |h|
      h.update_attribute( :class_type, 'sunday_service')
      n += 1
    end

    Member.find(:all).each do |m|
      if m.get_birthday_short == '01-01'
        m.update_attribute( :birthday_still_unknow, '1')
        n += 1
      end
    end   
=end     
    render :text => n.to_s
  end

  def chart_index_by_month_peroid
    session[:show_histories_chart] = true
    build_index_by_month_peroid
    build_data_for_chart_index    
    render :action => 'chart_index'
  end
  
  def build_index_by_month_peroid
    params[:num_month_ago] ||= 0
    params[:sub_title] ||= '本月'
    session[:period_title] = params[:sub_title]
    @histories = History.all( :order => 'class_date desc, class_title', :conditions => [ "area_id = ? and class_date >= ?", session[:default_area_id], (Time.now-(params[:num_month_ago].to_i).month).strftime("%Y-%m-01") ] )
    @sub_title = params[:sub_title] + '的'
    today = Date.today
    previous_month = today - 1.month
    @act_year = previous_month.year
    @act_month = previous_month.month
    @list_type = "rec" # plan:表示计划表 | rec:表示记录表
    calculate_uniq_student_count
  end

  def prepare_activities_report_data( num )
    previous_month = Date.today - num.to_i.month
    @act_year = previous_month.year
    @act_month = previous_month.month
    # 上个月的人数统计：大人禮拜、二世禮拜、一日靈修、兩日靈修、三日靈修、七日靈修
    @class_types = ['sunday_service','sunday_service_2g','one_day','two_day','three_day','seven_day']
    @class_types.each {|class_type| eval("@#{class_type}_count, @#{class_type}_note = get_activities_join_names( '#{trans_word_to_num(class_type)}', #{num} )") }
  end

  def get_activities_join_names( class_type, begin_num = 1 )
    begin_date = Date.today-begin_num.month
    end_date = begin_date + 1.month
    begin_date = begin_date.strftime("%Y-%m-01")
    end_date = end_date.strftime("%Y-%m-01")
    histories = History.all( :group => "name", :conditions => [ "class_type = ? and area_id = ? and class_date >= ? and class_date < ?", class_type, session[:default_area_id], begin_date, end_date ] )
    note = ''
    n = 0
    # 男性
    student_count_m = young_count_m = adult_count_m = 0
    # 女性
    student_count_f = young_count_f = adult_count_f = 0
    histories.each do |h| 
      n += 1
      m = Member.find(h.member_id)
      note = note + h.name + " "
      if m.sex_id == 1
        case m.get_age
          when (0..18)
            student_count_m += 1
          when (19..39)
            young_count_m += 1
          when (40..999)
            adult_count_m += 1
        end
      elsif m.sex_id == 0
        case m.get_age
          when (0..18)
            student_count_f += 1
          when (19..39)
            young_count_f += 1
          when (40..999)
            adult_count_f += 1
        end
      end
    end
    note = note + "男学生:#{student_count_m}人，男青年:#{young_count_m}人，男成年:#{adult_count_m}人，女学生:#{student_count_f}人，女青年:#{young_count_f}人，女成年:#{adult_count_f}人"
    return [n,note]
  end

  def trans_word_to_num( word )
    [['one_','1'],['two_','2'],['three_','3'],['seven_','7']].each do |r|
      if word.include?(r[0])
        return word.sub(r[0],r[1])
      else
        return word
      end
    end
  end

  def build_data_for_chart_index
    @max_record_num_for_chart = value_of('max_record_num_for_chart').to_i
    @addition_note = ""
    if @histories.size > @max_record_num_for_chart
      @addition_note = "[共有#{@histories.size}筆，但因效能限制，最多只能顯示#{@max_record_num_for_chart}筆]"
      @histories = @histories[0,@max_record_num_for_chart]      
    end
    @names = []
    @dates = []
    if @histories.size > 0
      @start_date = @histories.last.class_date.at_beginning_of_week
      @start_date.upto(@histories.first.class_date.end_of_week) { |d| @dates << d.to_s(:db) }
    end
  end

  def cal_start_date
    (Time.now-(params[:num_month_ago].to_i).month).strftime("%Y-%m-01")
  end

  def teacher_history_list
    build_teacher_history_list
    render :action => 'index'    
  end

  def chart_teacher_history_list
    build_teacher_history_list
    build_data_for_chart_index
    render :action => 'chart_index'    
  end  

  def build_teacher_history_list
    @histories = History.all( :order => 'class_date desc', :conditions => ["name != ? and class_teacher = ? and class_date >= ?", params[:tname], params[:tname], cal_start_date ])
    calculate_uniq_student_count
    @sub_title = '講師為' + params[:tname] + '且在' + params[:num_month_ago].to_s + '個月內的'
  end

  def calculate_uniq_student_count
    params[:pnum] ||= 1
    prepare_activities_report_data( params[:pnum] )
    @student_count = @histories.map { |h| h.name }.uniq.size
  end

  def member_history_list
    build_member_history_list
    render :action => 'index'
  end

  def chart_member_history_list
    build_member_history_list
    build_data_for_chart_index
    render :action => 'chart_index'
  end

  def build_member_history_list
    # params[:num_month_ago] ||= 9999
    # @histories = History.all( :order => 'class_date desc', :conditions => [ "member_id = ? and area_id = ? and class_date >= ?", params[:mid], session[:default_area_id], cal_start_date ] )
    @histories = History.all( :order => 'class_date desc', :conditions => [ "member_id = ? and area_id = ?", params[:mid], session[:default_area_id] ] )
    @sub_title = Member.find(params[:mid]).name  # + params[:num_month_ago].to_s + '個月內的'
  end

  def index_by_peroid_and_type
    build_index_by_peroid_and_type
    render :action => 'index'    
  end

  def chart_index_by_peroid_and_type
    build_index_by_peroid_and_type
    build_data_for_chart_index
    render :action => 'chart_index'    
  end

  def build_index_by_peroid_and_type
    @histories = History.all( :order => 'class_date desc', :conditions => [ "area_id = ? and class_date >= ? and class_type = ?", session[:default_area_id], cal_start_date, params[:class_type] ] )
    @sub_title = params[:sub_title] + '的' if params[:sub_title]
    calculate_uniq_student_count
  end

  def index_for_class_type_in_this_month
    @histories = History.all( :order => 'class_date desc', :conditions => [ "area_id = ? and class_type = ? and class_date >= ?", session[:default_area_id], params[:class_type], Time.now.strftime("%Y-%m-01") ] )
    @sub_title = Time.now.year.to_s + '年' + Time.now.month.to_s + '月份' + class_type_arr.rassoc(params[:class_type])[0]
    render :action => 'index'
  end  

  # GET /histories/1
  # GET /histories/1.xml
  def show
    @history = History.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @history }
    end
  end

  # GET /histories/new
  # GET /histories/new.xml
  def new
    @history = History.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @history }
    end
  end

  # GET /histories/1/edit
  def edit
    @history = History.find(params[:id])
  end

  # POST /histories
  # POST /histories.xml
  def create
    @history = History.new(params[:history])

    respond_to do |format|
      if @history.save
        # 新增千金難買變化紀錄
        insert_param_change_record('count_of_my_histories',get_linshijie_total_histories_count) 
        flash[:notice] = 'History was successfully created.'
        format.html { redirect_to(@history) }
        format.xml  { render :xml => @history, :status => :created, :location => @history }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @history.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  #根據session值, 快速新增課程資料
  def auto_create  
    if !session[:class_date].nil? and !session[:class_teacher].empty? and !session[:class_title].empty? and !session[:class_type].empty?
      mids = params[:mids].to_a
      count = 0
      mids.each do |mid|
        name = Member.find(mid).name
        History.create(
                        :member_id => mid,
                        :area_id => session[:class_area_id],
                        :class_date => session[:class_date],
                        :class_type => session[:class_type],
                        :class_teacher => session[:class_teacher],
                        :class_title => session[:class_title],
                        :is_public_class => session[:is_public_class],
                        :name => name )
        Trace.find_by_member_id(mid).update_attributes(
                        :aid => session[:class_area_id],
                        :class_type => session[:class_type],
                        :last_class_date => session[:class_date],
                        :last_class_teacher => session[:class_teacher],
                        :last_class_title => session[:class_title],
                        :is_public_class => session[:is_public_class],
                        :class_feel => "" )
        count = count + 1
      end
      # 依照会员在本月参加活动的次数，自动更新会员的所属类别
      update_all_members_classification_by_histories_count_month
      # 更新或新建人员分布报表
      update_or_create_member_report
      flash[:notice] = "#{count}笔課程紀錄新增成功！并已成功新建或更新每月报表"
    else
      flash[:notice] = "ERROR!! 課程紀錄新增失敗!! 參數:  #{session[:class_date]}, #{session[:class_teacher]}, #{session[:class_title]}, #{session[:class_type]}}"
    end
    redirect_to_index
  end

  # PUT /histories/1
  # PUT /histories/1.xml
  def update
    @history = History.find(params[:id])

    respond_to do |format|
      if @history.update_attributes(params[:history])
        flash[:notice] = 'History was successfully updated.'
        format.html { redirect_to :action => :index_by_month_peroid }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @history.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /histories/1
  # DELETE /histories/1.xml
  def destroy
    @history = History.find(params[:id])
    @history.destroy

    respond_to do |format|
      format.html { redirect_to :action => :index_by_month_peroid }
      format.xml  { head :ok }
    end
  end

  def auto_update_class_type
    n = c = 0
    @histories = History.all( :order => 'class_date desc', :limit => 100000)
    @histories.each do |h|
      #主日礼拜
      if h.class_title.include? '主日' or h.class_title.include? '礼拜' or h.class_title.include? '禮拜' or h.class_title.include? '人生必经之路'
        h.update_attribute( :class_type, 'sunday_service')
        n = n + 1       
        #把讲师也加入一笔
        ['林仕傑', '洗敏瑩'].each do |tname|
          if h.class_teacher == tname and !History.find(:first , :conditions => ["class_date = ? and class_title = ? and name = ? and class_teacher = ?", h.class_date, h.class_title, tname, tname ])
            History.create(
              :name => tname,
              :class_teacher => tname,
              :class_date => h.class_date,          
              :class_title => h.class_title,
              :class_type => 'sunday_service'
            )
            c = c + 1
          end
        end
      #一日课程
      elsif h.class_title.include? '家庭灵修会' or h.class_title.include? '家庭修炼会'
        h.update_attribute( :class_type, '1day')
        n = n + 1
      #普通课程    
      else
        h.update_attribute( :class_type, 'normal')
        n = n + 1
      end  
    end
    render :text => "#{c}筆紀錄已创建! #{n}筆紀錄已更新!"    
  end

  def auto_update_member_id
    n_update = n_destroy = 0
    History.all.each do |h|
      if !h.member_id
        begin
          h.update_attribute( :member_id, Member.find_by_name(h.name).id )
          n_update += 1
        rescue
          h.destroy
          n_destroy += 1
        end
      end
    end
    flash[:notice] = "已经更新#{n_update}笔活动记录的会员ID，并删除#{n_destroy}笔活动记录!"
    redirect_to :controller => :members, :action => :index
  end
  
  def auto_delete_empty_title_records
    History.destroy_all(:class_title => nil)
    flash[:notice] = "已经删除完毕!"
    redirect_to :action => :index_for_today
  end

end
