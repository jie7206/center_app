# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper
  
    def nav_bar
        result = []
        separated_mark = "￤"
        separated_mark2 = "｜"
        result << separated_mark2
        result << link_to( '书籍管理', :controller => 'main', :action => 'show_golden_verse', :rand_collect => true ) << separated_mark
        result << link_to( '人员管理', :controller => 'members', :aid => '2', :cid => 'local_all', :order_desc => 1, :order_method => 'histories_count_3month' ) << separated_mark
        result << link_to( '財務管理', :controller => 'asset_items', :action => 'index' ) << separated_mark2
        result << link_to( '活动紀錄', :controller => 'histories', :action => 'index_by_month_peroid', :num_month_ago => 3, :sub_title => '本季') << separated_mark
        result << link_to( '每月報表', :controller => 'member_reports', :action => 'month_report', :year => 2018) << separated_mark
        result << link_to( '登出系统', :controller => 'main', :action => 'logout' ) << separated_mark
        result << book_search_input << member_search_input
        return "<div id='nav_bar' style='text-align: center;'>#{result.join(' ').to_s}</div>"
    end

    def build_search_input( model_name, action_name, default_text )
      "<form name='#{model_name}_search_form' action='/#{action_name}/' method='get' style='display:inline;'><input type='text' name='#{model_name}_keywords_for_search' value='#{default_text}' style='width:50px;height:50%;margin-bottom:3px;font-size:0.1em;background:#FFFFEE;' onclick='this.select()'/>#{image_submit_tag('icon/empty.gif', :width=> 1)}</form>"
    end

    def member_search_input
      build_search_input 'member', 'members', '会员搜索'
    end

    def life_search_input
      build_search_input 'life', 'param_changes', '每日感悟'
    end

    def book_search_input
      build_search_input 'main', 'main/show_golden_verse', '字句搜索'
    end
     
    def work_turn_start
      d = Param.find_by_name('work_turn_start').value.split('-')
      { :year => d[0].to_i, :month => d[1].to_i, :day => d[2].to_i }
    end
    
    def get_param_arr( name )
      Param.find_by_name(name).value.split(',')
    end

    def get_param_value( name )
      Param.find_by_name(name).value
    end

    def get_trace_id( member_id )
      Trace.find_by_member_id( member_id ).id
    end
      
    def area_and_career_bar
      area_id ||= session[:default_area_id]
      result = []
      separated_mark = "|"
      result << separated_mark

      # 依地区显示
      area_arr.each do |a|
          result << link_to( a[0], :controller => 'members', :set_aid => 1, :cid => 'local_all', :aid => a[1] ) + "(#{Member.total_local_count(a[1].to_i)})" << separated_mark
      end
      result << link_to( @all_title, :controller => 'members',  :cid => 'all' )  + "(#{Member.db_total_count})" << separated_mark

      result << "<br/>" << separated_mark

      # 显示核心
      result << link_to( '核心', :controller => 'members', :cid => 'local_core_members_all', :aid => area_id ) + "(#{Member.total_core_members_count(area_id)})" << separated_mark

      # 显示重点名单
      result << link_to( '重點', :controller => 'members',  :action => 'pray_list' )  + "(#{Member.is_on_table_count})" << separated_mark
      #result << link_to( '弟弟', :controller => 'members',  :cid => 'is_brother_count', :aid => area_id, :order_method => 'last_class_date' )  + "(#{Member.is_brother_count(area_id)})" << separated_mark

      # 依报表第一分类显示
      @mr_titles.sort{|a,b| a.to_s <=> b.to_s}.each do |key,title|
        if key.to_s.index('_count')
          result << link_to( title, :controller => 'members', :cid => key.to_s, :aid => area_id ) + "(#{MemberReport.get_count(key, area_id)})" << separated_mark
        end
      end


      # 显示新人
      result << link_to( '新人', :controller => 'members', :cid => 'local_new_all', :aid => area_id ) + "(#{Member.total_new_count(area_id)})" << separated_mark
      # 显示單身會員(包含孩子)
      result << link_to( '單身', :controller => 'members', :cid => 'local_single_members_all', :aid => area_id ) + "(#{Member.total_single_members_count(area_id)})" << separated_mark

      # 显示 ['祝福會員','0'],['孩子子女','5'],['群眾','99']...
      career_arr[0..2].each do |c|
          result << link_to( c[0][0..5], :controller => 'members', :cid => c[1], :aid => area_id ) + "(#{Member.sum_by_cid_and_aid(c[1].to_s, area_id)})" << separated_mark
      end

      # 显示讲师、司会与侍奉组名单
      result << link_to( '講師組', :controller => 'members', :cid => 'local_single_members_all', :aid => area_id ) + "(0)" << separated_mark
      result << link_to( '司會組', :controller => 'members', :cid => 'local_single_members_all', :aid => area_id ) + "(0)" << separated_mark
      result << link_to( '服侍組', :controller => 'members', :cid => 'local_single_members_all', :aid => area_id ) + "(0)" << separated_mark

      # 显示疏離
      # result << link_to( '疏離', :controller => 'members', :cid => 'local_disconnect_all', :aid => area_id ) + "(#{Member.total_disconnect_members_count(area_id)})" << separated_mark
=begin
      # 显示地区总计
      result << link_to( @local_sum_title, :controller => 'members',  :cid => 'local_all', :aid => area_id )  + "(#{Member.total_local_count(area_id)})" << separated_mark 
      result << "<br/>" << separated_mark

      # 依报表第二分类显示
      n = 0
      @mr_titles.sort{|a,b| a.to_s <=> b.to_s}.each do |key,title|
        if key.to_s.index('_count') == nil
          n += 1
          result << link_to( title, :controller => 'members', :cid => key.to_s, :aid => area_id ) + "(#{add_zero(MemberReport.get_count(key, area_id))})" << separated_mark
          result << "<br/>" << separated_mark if n == 12
        end
      end
      result << link_to( @local_effect_title, :controller => 'members',  :cid => 'local_effect_all', :aid => area_id )  + "(#{Member.total_local_effect_count(area_id)})" << separated_mark 
=end
      return "<div id='status_bar'>#{result.join(' ').to_s}</div>"      
    end

    def leaders_and_peroid_and_types_bar
      result = []
      separated_mark = "|"
      result << separated_mark
    
      chart_prefix = session[:show_histories_chart] ? 'chart_' : ''
      activity_peroid_arr.each do |peroid|
        case @list_type
          when 'plan'
            result << link_to( peroid[0], :controller => 'activities', :action => 'plan_list', :num_month_ago => peroid[1], :sub_title => peroid[0] ) << separated_mark
          when 'rec'
            result << link_to( peroid[0], :controller => 'histories', :action => chart_prefix + 'index_by_month_peroid', :num_month_ago => peroid[1], :sub_title => peroid[0] ) << separated_mark
        end
      end
    
      result << link_to( '全部', :controller => 'histories', :action => 'index', :num_month_ago => 'all' ) << separated_mark
      result << link_to( '計畫圖表', :controller => 'activities', :action => 'plan_chart' ) << separated_mark
      result << link_to( '活動報告', :controller => 'activities', :action => 'index' ) << separated_mark
      result << link_to( '活動計畫', :controller => 'activities', :action => 'plan_list' ) << separated_mark
      result << link_to( '課程紀錄', :controller => 'histories', :action => 'index_by_month_peroid' ) << separated_mark      
      result << link_to( '課程圖表', :controller => 'histories', :action => 'chart_index_by_month_peroid' ) << separated_mark
      result << link_to( '新增計畫', :controller => 'activities', :action => 'new' ) << separated_mark
      
      return "<div id='status_bar'>#{result.join(' ').to_s}</div>" 

    end

    def life_interests_bar
      result = []
      separated_mark = "|"
      result << separated_mark

      # 显示生活類目各得多少总分
      Param.all( :conditions => "name like 'life_catalog_%'", :order => "order_num" ).each do |p|
        days = sprintf("%0.1f", p.value.to_f/60/24)
        result << link_to( p.title+'('+p.value+')', {:controller => 'main', :action => 'life_chart', :life_catalog_id => p.id, :query_data => true}, {:title => "共計#{p.value}分鐘(约#{days}天)，包含：#{p.get_life_interests_str}"} ) << separated_mark
      end
      result << "<br/>"

      # 显示生活項目的名称与连接
      result << life_catalogs_link

      return "<div id='status_bar'>#{result.join(' ').to_s}</div>"
    end

    # 组成生活項目的名称与连接
    def life_catalogs_link
      result = []
      separated_mark = "|"
      result << separated_mark

      
      params = Param.all( :conditions => life_interest_select, :order => "order_num" )
      params.sort! { |x,y| y.value.to_i <=> x.value.to_i } if value_of('if_life_interest_sort_by_minutes').to_i > 0
      params.each do |p|
        days = sprintf("%0.1f", p.value.to_f/60/24)
        result << link_to( p.title.sub('【','').sub('】',''), {:controller => 'param_changes', :action => 'new', :param_id => p.id}, {:title => "共計#{p.value}分鐘(约#{days}天)"} ) << separated_mark
      end

      return result
    end

    # 显示生活項目的名称与连接
    def life_catalogs_link_bar
      return "<div id='status_bar'>#{life_catalogs_link.join(' ').to_s}</div>"
    end

    def show_total_mins_and_days_of_life_interests
      total_mins = value_of('count_mins_of_life_interest')
      total_days = sprintf("%0.2f", total_mins.to_f/60/24)
      "共計#{total_mins}分，約#{total_days}天"
    end

    def show_total_mins_and_days_of_life_interests_record( record )
      total_mins = record.to_a.sum { |r| r.change_value }
      total_days = sprintf("%0.2f", total_mins.to_f/60/24)
      "总共#{record.size}笔，合計#{total_mins.to_i}分，約#{total_days}天"
    end

    def get_linshijie_total_histories_count
      History.count(:conditions => linshijie_total_histories_select )
    end

    def count_of_linshijie_histories( chart_prefix = '' )
      # 取出最近几笔活动记录作为辅助说明
      href_note = ''
      History.all( :conditions => linshijie_total_histories_select, :limit => 30, :group => "class_date", :order => "class_date desc" ).each do |h|
        num = History.all( :conditions => "class_teacher = '林仕傑' and name != '林仕傑' and class_date = '#{h.class_date}'", :group => "name" ).size
        href_note += "#{h.class_date}: 共#{add_zero(num,2)}人: #{h.name}: #{h.class_title}\n"
      end
      link_to( get_linshijie_total_histories_count, { :controller => 'histories', :action => chart_prefix + 'teacher_history_list', :tname => '林仕傑', :num_month_ago => 1000 }, { :target => '_blank', :title => href_note } )           
    end

    def donation_catalog_bar
        result = []
        separated_mark = "｜"
        result << separated_mark
        donation_catalog_arr.each do |c|
            result << link_to( c[0], :controller => 'donations', :action => "index", :data_field => 'catalog_id', :data_value => c[1] ) << separated_mark
        end        
        return "<div id='status_bar'>#{result.join(' ').to_s}</div>"      
    end

    # 情绪管理的子链接
    def golden_verse_bar
        result = []
        separated_mark = "｜"
        result << separated_mark
        result << link_to( "随机金句", :action => "show_golden_verse" ) << separated_mark
        # result << link_to( @verse_collect_for_me_title, :action => "show_golden_verse_collection" ) << separated_mark
        # result << link_to( @verse_collect_for_ppt_title, :action => "show_golden_verse_collection", :for_ppt => true ) << separated_mark
        result << link_to( "书籍目录", :controller => "books" ) << separated_mark
        result << link_to( "新增书籍", :controller => "books", :action => "new" ) << separated_mark
        result << link_to( "字幕处理", :controller => "main", :action => "auto_add_str_start_time_form" ) << separated_mark << "<p/>"        
        return "<div id='status_bar'>#{result.join(' ').to_s}</div>"      
    end    

    def life_catalog_bar_for_goal
      @total_remain_minutes = 0
      result = []
      if use_life_catalog_goal_minutes?
          life_catalogs = LifeCatalog.all( :conditions => [ "goalable = ?", true], :order => :line_order_num )
          frame_width = (860/life_catalogs.size-55).to_i
          frame_width = 100 if frame_width > 100
          case life_catalogs.size
            when (0..9)
              font_size = "1.0"
            when  (10..12)
              font_size = "0.9"
            else
              font_size = "0.7"
          end  
          life_catalogs.each do |c|
              remain_data = remain_minutes_of_life_catalog( c.id )
              catalog_name = remain_data[:catalog_name]
              remain_minutes = remain_data[:remain_minutes]
              remain_minutes_percent = remain_data[:remain_minutes_percent]
              if remain_minutes > 0
                result << link_to( strong_select_link( params[:cid], c.id.to_s, c.name  ), :controller => 'life_records', :action => 'index', :cid => c.id ) << time_uesd_bar( catalog_name, remain_minutes, remain_minutes_percent, frame_width )
                @total_remain_minutes += remain_minutes
              end
          end
          return "<table style='background-color:transparent;font-size:#{font_size}em'><tr><td>#{result.join('</td><td width="10"></td><td>')}</td></tr></table>"
        else
          first_remain_item_name = nil
          today_db_str = Date.today.to_s(:db)
          life_items = LifeItem.all( :conditions => [ "is_goal = ? and begin_date <= ? and end_date >= ?", true, today_db_str, today_db_str ], :order => :order_num )
          if life_items.size > 0
            frame_width = (860/life_items.size-11).to_i
            frame_width = 100 if frame_width > 100
            case life_items.size
              when (0..9)
                font_size = "1.0"
              when  (10..12)
                font_size = "0.9"
              else
                font_size = "0.7"
            end
            life_items.each do |i|
              remain_data = remain_minutes_of_life_item( i.id )
                item_name = remain_data[:item_name]
                remain_minutes = remain_data[:remain_minutes]
                remain_minutes_percent = remain_data[:remain_minutes_percent]
                if remain_minutes > 0
                  first_remain_item_name ||= item_name
                  result << link_to( time_uesd_bar( item_name, remain_minutes, remain_minutes_percent, frame_width ), :controller => :life_records, :action => :index, :tid => i )
                  @total_remain_minutes += remain_minutes
                end
            end
            result.unshift "<div style=\"font-size:#{font_size}em\">#{first_remain_item_name}</div>"
            return "<table style='background-color:transparent;'><tr><td>#{result.join('</td><td width="10"></td><td>')}</td></tr></table>"         
        end
      end
    end     

    def time_uesd_bar( name, remain_minutes, remain_minutes_percent, frame_width = 65 )
        bar_width = frame_width*remain_minutes_percent
        icon_file = "g_bar.png"
        icon_file = "y_bar.png" if remain_minutes_percent*100 < 40
        icon_file = "r_bar.png" if remain_minutes_percent*100 < 20
        "<div style='margin-left:-12px;width:#{frame_width}px;height:7px;border:1px solid #000000;background-color:#FFFFFF'><img src='/images/icon/#{icon_file}' border='0' style='width:#{bar_width}px;height:7px;' title=' #{name}還剩#{remain_minutes}分鐘 '/></div>" 
    end

    def life_catalog_bar
        result = []
        separated_mark = "｜"
        result << separated_mark
        min_item_catalog_id = get_min_item_catalog_id
        LifeCatalog.all( :order => :line_order_num ).each do |c|
            result << link_to( strong_select_link( params[:cid], c.id.to_s, c.name, min_item_catalog_id  ), :controller => 'life_records', :action => 'index', :cid => c.id ) << separated_mark
        end        
        result << link_to( strong_select_link( params[:cid], "all", "全部" ), :controller => 'life_records', :action => 'index', :cid => "all" ) << separated_mark
        return "#{result.join(' ').to_s}"      
    end

    def previous_month_bar
        result = []
        separated_mark = "｜"
        result << separated_mark
        (1..12).each do |n|
            result << link_to( n, :controller => 'histories', :action => "index_by_month_peroid", :pnum => n ) << separated_mark
        end        
        return "<div>查詢前 #{result.join(' ').to_s} 個月</div>"      
    end    

    # 顯示北京或台北的時間
    def bj_time( db_time )
      (db_time+8.hours).to_s(:db)
    end

    # 显示一般时间
    def show_time( db_time )
      db_time ? "#{add_zero(db_time.hour,2)}:#{add_zero(db_time.min,2)}" : "00:00"
    end
    
    def strong_select_link( target_value, current_value, show_text, min_goal_cid = 0 )
      show_text = "☆" + show_text if current_value == min_goal_cid.to_s
      target_value == current_value ? "<strong>#{show_text}</strong>" : "#{show_text}"
    end 
    
    #兩個total_minutes最少的類別之間的差
    def diff_minutes
      life_catalogs = LifeCatalog.all( :conditions => ["goalable = ?",true], :order => "total_minutes", :limit => 2 )
      life_catalogs[1].total_minutes - life_catalogs[0].total_minutes
    end
    
    def compose_select_tag( tag_name, dataset, object_id, extend_js ='', selected_id = 0 )
        select_tag "#{tag_name}_select#{rand(10000)}", options_for_select(['']+dataset, selected_id), :onchange => "document.getElementById('#{object_id}').value=this.value;" + extend_js
    end
    
    def member_list( object_id )
        @members_set ||= Member.all(:order => "name").map {|m| m.name}
        compose_select_tag( 'member', @members_set, object_id )
    end

    def member_id_list( object_id, selected_id )
        @members_set ||= Member.all(:order => "name").map { |m| [m.name, m.id] }
        compose_select_tag( 'member', @members_set, object_id, '', selected_id )
    end
    
    def blessed_member_id_list( object_id, selected_id )
        @blessed_members_set ||= Member.all(:conditions => [ "career = '0'"], :order => "name").map { |m| [m.name, m.id] }
        compose_select_tag( 'member', @blessed_members_set, object_id, '', selected_id )
    end
    
    def show_spouse_name( spouse_id )
      if spouse_id and spouse_id > 0
        "<a href=\"/members/#{spouse_id}/edit\"><span style=\"font-size:0.1em;color:#999999\">#{Member.find(spouse_id).name}</span></a>"
      end
    end

    def show_eng_name( ename )
      "<span style=\"font-size:0.1em;color:#999999\">#{ename}</span>"
    end

    def show_if_donated( is_donated )
      image_submit_tag('icon/pass_ok.png', :width => 10, :height => 8, :title => "本季有做奉献") if is_donated
    end

    def show_if_on_table( is_on_table )
      image_submit_tag('icon/important.png', :width => 15, :height => 14, :align => "absmiddle", :title => "已列为重点培养") if is_on_table
    end

    def show_if_college( is_college )
      image_submit_tag('icon/blue_hat.png', :width => 15, :height => 14, :align => "absmiddle", :title => "此人是大学生") if is_college
    end

    def life_rec_date_list
      LifeRecord.find_by_sql("SELECT DISTINCT rec_date FROM life_records WHERE rec_date >= '#{Param.find_by_name('life_rec_start_date').value}'").map {|d| [d.rec_date]}.reverse
    end

    def member_ids
        Member.all(:order => "name").map {|a| [a.name, a.id]}
    end

    def asset_ids
        Asset.all.map {|a| [a.title+'('+a.code+')', a.id]}
    end

    def life_catalog_ids
        LifeCatalog.all( :order => :line_order_num ).map {|a| [a.name, a.id]}
    end

    def life_item_ids
      today_db_str = Date.today.to_s(:db)
        LifeItem.all( :conditions  => [ "begin_date <= ? and end_date >= ?", today_db_str, today_db_str ], :include => :life_catalog, :order => "life_catalogs.line_order_num" ).map {|a| [a.life_catalog.name + " : " + a.name, a.id]}
    end

    def school_list( object_id )
        @schools_set ||= school_arr.map {|s| s[0]}
        compose_select_tag( 'school', @schools_set, object_id )
    end
    
    def teacher_list( object_id )
        @teachers_set ||= Member.all( :conditions => [ "is_core_leader = ?", true ] ).map {|m| m.name}
        compose_select_tag( 'teacher', @teachers_set, object_id )
    end

    def course_list( object_id, options = {} )
        if options[:include_points]
          @courses_set ||= Course.all( :order => :order_num ).map {|c| c.title + ' -- ' + c.points.to_s}
          extend_js = options[:include_points] ? "document.getElementById('points').innerHTML=' (' + this.value.split(' -- ')[1]+'學分)';document.getElementById('trace_points').value=this.value.split(' -- ')[1];" : ''
          select_tag "course_select#{rand(10000)}", options_for_select(['']+@courses_set), :onchange => "document.getElementById('#{object_id}').value=this.value.split(' -- ')[0];" + extend_js
        else
          @courses_set ||= Course.all( :order => :order_num ).map {|c| c.title}
          select_tag "course_select#{rand(10000)}", options_for_select(['']+@courses_set), :onchange => "document.getElementById('#{object_id}').value=this.value.split(' -- ')[0];" 
        end
    end
    
    def leader_list( object_id )
        @leaders_set ||= Member.all( :conditions =>  ["is_team_leader =?", true] ).map {|m| m.name}
        compose_select_tag( 'leader', @leaders_set, object_id )      
    end
    
    def check_how_to_show_next_class_date( member )
      if member.classification < '3' && Date.today > member.trace.next_class_date
        link_to( '<span class="next_class_date_already_expired">已過期</span>', edit_trace_path(member.trace) )
      elsif Date.today > member.trace.next_class_date
        ''
      else
        link_to( member.trace.next_class_date, edit_trace_path(member.trace) ) + ' ' + show_appointment_promised(member.trace.appointment_promise)
      end
    end
      
    def picture_list_style( member )
      if member.classification.to_i >= 3
        case member.career.to_i
          when 0 : return ' class="picture_list_for_full_time"'
          when 1 : return ' class="picture_list_for_core_student"'
          when 2 : return ' class="picture_list_for_core_home"'
        end
      else
        ''
      end
    end

    def show_chinese_week( num )
        case num
            when 0 : return "日"
            when 1 : return "一"
            when 2 : return "二"
            when 3 : return "三"
            when 4 : return "四"
            when 5 : return "五"
            when 6 : return "六"
        end
    end

    def show_class_title( class_title, max_length = 20 )
        class_title = class_title.split('--')[0]
        if class_title.split(' - ').size > 1
            truncate( class_title.split(' - ')[1], max_length )
        else
            truncate( class_title, max_length )
        end
    end

    def show_class_feel( class_feel, max_length = 40 )
        if class_feel && class_feel.size > 1
            '：<span class="class_feel">' + truncate( class_feel, max_length ) + '</span'
        else
            ''
        end
    end
        
    def show_student_count
      if @student_count && @student_count > 0
        ' (' + @student_count.to_s + '名不同的學生)'
      end
    end
    
    def show_star_level( member )
      if member.classification.to_i < 10
        image_tag( "icon/star_#{member.trace.star_level}.gif", :align => 'absmiddle', :title => "#{star_arr.rassoc(member.trace.star_level)[0]}", :style => 'cursor: pointer;', :onclick => "javascript:document.location.href='#{edit_trace_path(member.trace)}';" )
      elsif member.career.to_i == 0 && member.is_team_leader
        image_tag( "icon/medal.png", :align => 'absmiddle', :height => 20, :title => '我們的榮譽小組長' )
      end
    end

    def show_sex( member_sex_id )
      if member_sex_id == 1
        "男"
      else
        "女"
      end
    end

    def show_check_mark( true_or_false )
      image_tag( 'icon/pass_ok.png', :width => 25 ) if true_or_false
    end
    
    def show_student_names( activity )
        "<hr class='dashed_line'/>主要參與者：#{activity.students}" if !activity.students.empty?
    end
    
    def show_member_career( member )
      member.career ? career_arr.rassoc(member.career)[0] : ''
    end
    
    def show_member_conductor_info( member )
      member.conductor_id ? "由 [#{Member.find(member.conductor_id).name}] 負責聯繫" : '還沒指定聯繫人'
    end
    
    def show_last_class_icon( last_class_title, member_id )
      if not last_class_title.empty?
         image_tag_str = image_tag( 'icon/doc.png', :title => last_class_title, :align => 'absmiddle', :border => 0 )
      else
         image_tag_str = image_tag( 'icon/doc_blank.gif', :align => 'absmiddle' )
      end
      link_to( image_tag_str, { :controller => "histories", :action => "auto_create", :mid => member_id } )
    end

    def show_appointment_promised( appointment_promise )
      appointment_promise ?  "<img src='/images/icon/handshake.png' align='absmiddle' title='對方已承諾赴約' />" : ''
    end
    
    def show_is_on_table( t_or_f )
      # ex: <td <%= show_is_on_table(member.is_on_table) %>>
      t_or_f ? "bgcolor=\"#FFFFCC\"" : ""
    end
    
    def show_life_item_id_select
      select_tag :life_item_id, "<option value=''></option>\n"+options_for_select( life_item_ids ), :onchange => "document.location.href='/life_records?tid='+this.value;"
    end

    def show_life_rec_date_select
      select_tag :life_rec_date, "<option value=''>　　　　</option>\n"+options_for_select( life_rec_date_list ), :onchange => "document.location.href='/life_records?rdate='+this.value;"
    end

    def show_life_rec_date_text
      value = params[:rdate] ? params[:rdate] : Date.today.to_s(:db)
      text_field_tag :rdate, value, :size => 8, :style => "text-align:center"
    end

    def sub_title_base( text )
      "&nbsp;<span class='link_to_history'>#{text}</span>"
    end

    def compose_small_link( text, controller, action = 'index' )
      sub_title_base link_to( text, :controller => controller, :action => action ) 
    end
    
    def life_links_bar
      compose_small_link('[類別表]', 'life_catalogs' ) +
      compose_small_link('[內容表]', 'life_items' ) +
      compose_small_link('[紀錄表]', 'life_records' )
    end

    def asset_item_detail_catalogs_bar
      compose_small_link('[類別總表]', 'asset_item_detail_catalogs' ) + 
      add_new_asset_item_detail_catalog_link
    end

    def add_new_asset_item_detail_catalog_link
      compose_small_link('[新增類別]', 'asset_item_detail_catalogs', 'new' )
    end

    def param_changes_link
      compose_small_link('[參數變化表]', 'param_changes' )
    end

    def param_link_bar
      compose_small_link('[新增參數]', 'params', 'new' ) +
      compose_small_link('[參數變化表]', 'param_changes' ) 
    end

    def asset_item_details_link
      compose_small_link('[資產明細]', 'asset_item_details' )
    end

    def asset_item_details_catalogs_link
      compose_small_link('[明細類別]', 'asset_item_detail_catalogs' )
    end

    def buy_house_plan_link
      compose_small_link('[購屋試算]', 'main', 'buy_house_plan' )
    end

    def cal_retire_day_link
      compose_small_link('[收支試算]', 'main', 'retire_plan_form' )
    end    

    def life_interest_link
      compose_small_link('[生活圖表]', 'main', 'life_chart' ) +
      compose_small_link('[生活列表]', 'main', 'life_list' ) +
      compose_small_link("[#{value_of('enjoy_life_title')}]", 'main', 'enjoy_life_list' ) +
      compose_small_link('[目標設定]', 'life_goals' ) +
      compose_small_link('[待辦事項]', 'life_goals', 'todo_list' )
    end

    def life_goals_link_bar
      compose_small_link('[新增目標或待辦]', 'life_goals', 'new' ) +
      compose_small_link('[重設目標]', 'life_goals', 'reset_life_goals' ) +
      compose_small_link('[全不显示]', 'life_goals', 'unshow_all_life_goals' ) +
      compose_small_link('[清空目標]', 'life_goals', 'destroy_all_life_goals' ) +
      compose_small_link('[待辦事項]', 'life_goals', 'todo_list' ) +
      compose_small_link('[完成待辦]', 'life_goals', 'completed_todo_list' ) +
      compose_small_link('[清空待辦]', 'life_goals', 'destroy_all_life_todos' )
    end

    # 图书总览功能导览 /books/index
    def books_func_bar
      compose_small_link('[图书总览]', 'books', 'index' ) +
      compose_small_link('[新增图书]', 'books', 'new' )
    end

    # 每月報表 /member_reports/month_report
    def month_report_bar
      compose_small_link('[產生報表]', 'member_reports', 'auto_create' ) +
      compose_small_link('[活動報表]', 'activities' )
    end    
    
    def asset_belongs_to_link
      result = ''
      asset_belongs_to_arr.each do |a|
        result += "&nbsp;<span class=\"link_to_history\">" + link_to( "[#{a[0]}]", :controller => 'asset_items', :asset_belongs_to_id => a[1]) +"</span>"
      end
      return result
    end    

    def highlight_keyword( text , keyword = '' )
      result = h(text)
      result.gsub!(/\n/,'<br/>') if result.index("\n")
      result.gsub!(/\s/,'&nbsp;'*2) if result.index("\s")
      result.gsub!(keyword,"<span class='highlight_keyword'>#{keyword}</span>") if result.index(keyword)
      return result
    end
          
    def if_truncate( text )
      @keyword ? highlight_keyword( text, @keyword ) : truncate( text, 40 )
    end
    
    def split_line( text, char_num )
      if text && text.size > 1
        text_arr = text.split("")
        if text_arr.size > char_num
          return text_arr.slice(0..char_num).join("") + "<br/>" + text_arr.slice(char_num+1..-1).join("")
        else
          return text
        end
      end
    end
    
    def line_to_br( text )
      return text.gsub(/\n/, "<br/>")
    end

    def show_goal_of_life_interest_remain
      result = ''
      remain_items = []
      # 显示每日尚需完成的项目
      Param.all( :conditions => "name like 'goal_of_life_interest_%'", :order => "order_num" ).each do |p|
        # A.计算今天已完成的分钟数
          # 1) 取出该生活项目的ID Ex: goal_of_life_interest_19
            life_interest_name = p.name[8..-1]
            item = Param.find_by_name(life_interest_name)
            life_interest_id = item.id
          # 2) 取出该生活项目今天的总分
            today_total_mins = 0
            ParamChange.all(:conditions=>["param_id=? and rec_date=?",life_interest_id,Date.today]).each do |pc|
              today_total_mins += pc.change_value.to_i
            end
        # B.计算该生活项目尚需几分钟才能完成
          # 1) 取出该生活项目的目标总分
            today_goal_mins = p.value.to_i
          # 2) 计算该生活项目尚需几分钟才能完成
            today_remain_mins = today_goal_mins - today_total_mins
        # C.显示尚未完成的生活项目
          if today_remain_mins > 0
            result += link_to( trip_title(item.title) + ' ' + add_zero(today_remain_mins) + '分<br/>', {:controller => 'param_changes', :action => 'new', :param_id => life_interest_id}, {:class => "goal_warn", :title => p.content} )
            remain_items << { :title => trip_title(item.title), :remain_mins => today_remain_mins, :param_id => life_interest_id, :content => p.content, :change_value => today_goal_mins }
          end
      end

      # 显示每周在当日尚需完成的项目
      Param.all( :conditions => "name like 'wgoal_of_life_interest_%'", :order => "order_num" ).each do |p|
          # 1) 取出该生活项目的ID Ex: wgoal_of_life_interest_06_on_246
            p_arr = p.name.split('_on_')
            life_interest_name = p_arr[0][9..-1] # Ex: life_interest_06
            life_interest_on_week = p_arr[1] # Ex: 246 代表每周的二四六
          # 2) 如果今天的星期恰好是预定的星期
            today = Date.today
            today_week = today.strftime('%w').to_s
            ##################################################################################################
            if life_interest_on_week.include?(today_week)
              item = Param.find_by_name(life_interest_name)
              life_interest_id = item.id
            # 3) 取出该生活项目今天的总分
              today_total_mins = 0
              ParamChange.all(:conditions=>["param_id=? and rec_date=?",life_interest_id,today]).each do |pc|
                today_total_mins += pc.change_value.to_i
              end
            # 4) 取出该生活项目的目标总分
              today_goal_mins = p.value.to_i
            # 5) 计算该生活项目尚需几分钟才能完成
              today_remain_mins = today_goal_mins - today_total_mins
            # 6) 显示尚未完成的生活项目
              if today_remain_mins > 0
                result += link_to( trip_title(item.title) + ' ' + add_zero(today_remain_mins) + '分<br/>', {:controller => 'param_changes', :action => 'new', :param_id => life_interest_id}, {:class => "goal_warn", :title => p.content } )
                remain_items << { :title => trip_title(item.title), :remain_mins => today_remain_mins, :param_id => life_interest_id, :content => p.content, :change_value => today_goal_mins }
              end
            end
            ##################################################################################################
      end      
      return result, remain_items
    end

    # 显示千金难买的天数辅助说明(<a title属性>)
    def show_my_recent_enjoy_life_note_old( record = @histories, limit = 100, only_zhizu = true )
      result = ''
      record[0,limit].each do |h|
        # 只显示最主要的知足生活类别
        if only_zhizu
          ids = content_of('life_catalog_10').split(',')
          if ids.include?(h.param.name.sub('life_interest_',''))
            result += "#{h.rec_date}: #{h.title} #{h.change_value.to_i}分\n"
          end
        # 显示所有的生活类别
        else
          result += "#{h.rec_date}: #{h.title} #{h.change_value.to_i}分\n"
        end
      end
      return result
    end

    # 显示千金难买的天数辅助说明(<a title属性>)
    def show_my_recent_enjoy_life_note( extra_note = "", limit = 100 )
      conditions = [ "is_enjoy = ?", true ]
      first_rec = ParamChange.first( :conditions => conditions, :order => "rec_date" )
      result = "自#{first_rec.rec_date}起#{extra_note}：\n"
      ParamChange.all( :limit => limit, :conditions => conditions, :order => "rec_date desc, title" ).each do |pc|
        result += "#{pc.rec_date}: #{pc.title} #{pc.change_value.to_i}分\n"
      end
      return result
    end    

    # 显示流动资产的内容(大于新台币多少钱即显示)
    def total_assets_note( asset_code = 'flow_assets', min_ntd_amount = 300 )
      assets = []
      AssetItem.all( :include => :asset, :conditions => ["assets.code = ? and asset_belongs_to_id = 1", asset_code] ).each do |item|
        ntd_amount = item.to_ntd.to_i
        assets << { :title => item.title, :amount => ntd_amount } if ntd_amount >= min_ntd_amount
      end
      total_amount = assets.sum {|a| a[:amount]}
      result = ''
      assets.sort{ |a,b| b[:amount] <=> a[:amount] }.each do |a|
        persent = sprintf("%0.1f", (a[:amount].to_f/total_amount.to_f*100))
        result += "#{a[:title]}：#{a[:amount]} (#{persent}%)\n"
      end      
      return result += "共计 #{total_amount} 元新台币"
    end

    # 显示流动资产的内容(大于人民币多少钱即显示)
    def total_emer_assets_note
      assets = []
      AssetItem.all( :include => :asset, :conditions => ["assets.code = ? and asset_belongs_to_id = 1 and is_emergency = ?", 'flow_assets', true] ).each do |item|
        mcy_amount = item.to_mcy
        assets << { :title => item.title, :amount => mcy_amount }
      end
      total_amount = assets.sum {|a| a[:amount]}
      result = ''
      assets.sort{ |a,b| b[:amount] <=> a[:amount] }.each do |a|
        persent = sprintf("%0.1f", (a[:amount].to_f/total_amount.to_f*100))
        result += "#{a[:title]}：#{sprintf("%0.1f", a[:amount])} (#{persent}%)\n"
      end      
      return result += "共计 #{total_amount.to_i} 元人民币"
    end

    # 显示流动资产的内容(以新台币显示)
    def total_emer_assets_note_ntd
      show_assets_note_ntd( ["asset_belongs_to_id = 1 and is_emergency = ?", true] )
    end

    # 显示可列为定存目标资产的内容(以新台币显示)
    def total_save_goal_assets_note_ntd
      show_assets_note_ntd( ["asset_belongs_to_id = 1 and is_save_for_goal = ?", true] )
    end    

    # 显示任意资产的内容(以新台币显示) 
    def show_assets_note_ntd( conditions_arr )
      assets = []
      AssetItem.all( :include => :asset, :conditions => conditions_arr ).each do |item|
        assets << { :title => item.title, :amount => item.to_ntd }
      end
      total_amount = assets.sum {|a| a[:amount]}
      result = ''
      assets.sort{ |a,b| b[:amount] <=> a[:amount] }.each do |a|
        persent = sprintf("%0.1f", (a[:amount].to_f/total_amount.to_f*100))
        result += "#{a[:title]}：#{sprintf("%0.1f", a[:amount])} (#{persent}%)\n"
      end      
      return result += "共计 #{total_amount.to_i} 元新台币"
    end    

    def life_goals_summary
      @total_show_minutes = show_item_num = 0
      @life_goals.each do |goal|
        if goal.is_show
          @total_show_minutes += goal.minutes
          show_item_num += 1
        end
      end
      sub_title_base "共 #{show_item_num} 項在管理表中显示，合計 #{@total_show_minutes} 分鐘，約 #{sprintf('%0.1f',@total_show_minutes/60.0)} 小時"
    end

    # 如果資產收支明細有note说明，则显示图标与:title属性
    def show_asset_item_detail_note_icon( asset_item_detail )
      if asset_item_detail.note and !asset_item_detail.note.empty?
        image_tag( 'icon/doc.png', :title => asset_item_detail.note, :align => 'absmiddle', :border => 0 ) 
      end
    end

    def show_percent( minutes, total_minutes, n = 0 )
      sprintf( "%0.#{n}f" ,minutes.to_f / total_minutes.to_f * 100 ) + "%"
    end

    # 加总所有千金难买的总分数
    def total_minutes_of_enjoy_time
      return ParamChange.find_by_sql("select change_value from param_changes where is_enjoy='t'").sum {|pc| pc.change_value.to_i}
    end

    # 显示人员报表的表头
    def member_report_table_th_row
      "<tr class='th_row' align='center'><td>資料日期</td><td>祝福家庭</td><td>学生会员</td><td>职工会员</td><td>小学孩子</td><td>中学孩子</td><td>学生学员</td><td>职工学员</td><td>可受祝福</td><td>献身领导</td><td>献身会员</td><td>男核學生</td><td>男核青年</td><td>男核成人</td><td>男核大学</td><td>女核學生</td><td>女核青年</td><td>女核成人</td><td>女核大学</td><td>男新學生</td><td>男新青年</td><td>男新成人</td><td>男新大学</td><td>女新學生</td><td>女新青年</td><td>女新成人</td><td>女新大学</td><td>男普學生</td><td>男普青年</td><td>男普成人</td><td>男普大学</td><td>女普學生</td><td>女普青年</td><td>女普成人</td><td>女普大学</td><td>有效總計</td></tr>"
    end

    # 回传人员报表中有效的人员总数
    def sum_of_effect_people(mr)
      if mr.m_core_student and mr.m_core_young and mr.m_core_adult and mr.f_core_student and mr.f_core_young and mr.f_core_adult and mr.m_new_student and mr.m_new_young and mr.m_new_adult and mr.f_new_student and mr.f_new_young and mr.f_new_adult and mr.m_normal_student and mr.m_normal_young and mr.m_normal_adult and mr.f_normal_student and mr.f_normal_young and mr.f_normal_adult
        return mr.m_core_student + mr.m_core_young + mr.m_core_adult + mr.f_core_student + mr.f_core_young + mr.f_core_adult + mr.m_new_student + mr.m_new_young + mr.m_new_adult + mr.f_new_student + mr.f_new_young + mr.f_new_adult + mr.m_normal_student + mr.m_normal_young + mr.m_normal_adult + mr.f_normal_student + mr.f_normal_young + mr.f_normal_adult
      else
        return 0
      end
    end

    # 显示年龄层
    def show_agelevel( member_age )
      case member_age
        when (0..18) : return '0-18'     
        when (19..39) : return '19-39' 
        when (40..999) : return '40以上'
      end
      return ''
    end

    # 依据2015年月報表(新版).xlsx 是大學生填(Y)
    def show_if_college_text( is_college )
      if is_college
        return 'Y'
      else
        return ' '
      end  
    end

    # 依据2015年月報表(新版).xlsx 備註(孩子、祝福候選人)
    def build_member_note( member )
      result = []
      result << '孩子' if member.career == '5' or member.is_2g
      result << '祝福候選人' if member.blessedable
      if result.size > 0
        return result.join('、')
      else
        return ' '
      end
    end

    # 为了方便批量输入用(Word, Excel)建立变数(搭配render :partial => 'member_report_input_data'显示内容)
    def prepare_member_report_input_data
      @name_list_arr = []
      @sex_list_arr = []
      @birthday_list_arr = []
      @classification_list_arr = []
      @agelevel_list_arr = []
      @college_list_arr = []
      @note_list_arr = []
    end  

    # 计算明年可得到的保险金
    def next_year_add_money_from_insurance( next_year )
      year = next_year.to_s
      str = value_of('year_add_money_from_insurance')
      if str.index(year+":")
        return str.split(year)[1].split(",")[0][1..-1].to_i
      else
        return 0
      end
    end

    # 计算明年可得到的定存利息(目前只限定台新银行定期存款(AssetItem.id=15)&华夏银行定期存款(AssetItem.id=87))
    def get_next_interest
      ( AssetItem.find(15).amount * value_of('taixin_year_rate').to_f ).to_i + ( AssetItem.find(87).amount * value_of('huaxia_year_rate').to_f * value_of('exchange_rates_MCY').to_f ).to_i
    end

    # 显示这几天内寿星的名字与生日
    def show_birthday_names
      birthday_near_days = value_of('birthday_near_days').to_i
      birth_members = []
      Member.all( :conditions => ["birthday_still_unknow = ?", false] ).each do |m|
        birth_month = m.birthday.month.to_s
        birth_day = m.birthday.day.to_s
        today = Date.today
        birthday = (today.year.to_s + '-' + birth_month + '-' + birth_day).to_date
        birth_members << m if birthday >= today and birthday <= today + birthday_near_days
      end
      birth_members.sort! {|x,y|  x.get_birthday_short  <=>  y.get_birthday_short}

      if birth_members.size > 0
        result = "近#{birthday_near_days}日生日名單："
        birth_members.each do |m|
          result += link_to(m.name+'('+m.get_birthday_short+')',edit_trace_path(m.trace),:title => m.birthday) + '&nbsp;&nbsp;'
        end
        return result
      else
        return ''
      end
    end

    # 显示前几名最需要联系的重点名单
    def show_is_on_table_names( num = value_of('max_num_of_show_on_table').to_i  )
      max_num_of_show_on_table = num
      members = Member.all(:include => "trace", :conditions => is_on_table_count_select) .sort! {|x,y|  x.get_last_class.class_date  <=>  y.get_last_class.class_date}
      if members.size > 0
        result = "前#{max_num_of_show_on_table.to_i}名重點名單："
        members[0..(max_num_of_show_on_table-1)].each do |m|
          if m.get_last_class
            #result += link_to(m.name+'('+add_zero(m.get_last_class.class_date.month,2)+'-'+add_zero(m.get_last_class.class_date.day,2)+')',{ :controller => 'members', :action => 'edit', :id => m.id }, { :target => '_blank', :title => "手機號碼: "+m.mobile+"\n最近連結: "+m.trace.last_class_date.to_s(:db)+"\n最近內容: "+m.trace.last_class_title+"\n帶領計畫: \n"+m.pray_note } ) + '&nbsp;&nbsp;'
            result += link_to(m.name+'('+day_diff( m.get_last_class.class_date, Time.now ).to_s+')',{ :controller => 'members', :action => 'edit', :id => m.id }, { :target => '_blank', :title => "手機號碼: "+m.mobile+"\n最近連結: "+m.trace.last_class_date.to_s(:db)+"\n最近內容: "+m.trace.last_class_title+"\n帶領計畫: \n"+m.pray_note } ) + '&nbsp;&nbsp;'
          end
        end
        return result
      else
        return ''
      end
    end

    # 显示FusionCharts的div(placeholder)和javascript代码
    def show_fusionCharts_div_and_js_code

      # Fusioncharts属性大全_百度文库
      # http://wenku.baidu.com/link?url=JUwX7IJwCbYMnaagerDtahulirJSr5ASDToWeehAqjQPfmRqFmm8wb5qeaS6BsS7w2_hb6rCPmeig2DBl8wzwb2cD1O0TCMfCpwalnoEDWa
      # http://xustar.iteye.com/blog/1204347

      min_and_max_value = "yAxisMinValue='#{@fusion_charts_yAxisMinValue}' yAxisMaxvalue='#{@fusion_charts_yAxisMaxValue}'"

      "<div id=\"chartContainer\"></div><p/>
      <script type=\"text/javascript\">
      FusionCharts.ready(function () {
          var myChart = new FusionCharts({
            \"type\": \"line\",
            \"renderAt\": \"chartContainer\",
            \"width\": \"#{value_of('life_chart_table_width')}\",
            \"height\": \"600\",
            \"dataFormat\": \"xml\",
            \"dataSource\": \"<chart #{min_and_max_value} animation='0' caption='' xaxisname='　' yaxisname='' formatNumberScale='0' formatNumber ='0' palettecolors='#007700' bgColor='#EFEEB1' canvasBgColor='#EFEEB1' valuefontcolor='#EFEEB1' showValues='0' borderalpha='0' canvasborderalpha='0' theme='fint' useplotgradientcolor='0' plotborderalpha='10' placevaluesinside='0' rotatevalues='1'  captionpadding='0' showaxislines='1' axislinealpha='0' divlinealpha='0' lineThickness='4'>#{@fusion_charts_data}</chart>\"
          });

        myChart.render();
      });
      </script>"

    end

    # 显示照片用frame(DIV)
    def show_ori_image_frame( position_str )
      result = %Q{
        <div id="ori_image" style="display:block;position:fixed;#{position_str}z-index:1;"></div>
      }
      return result
    end

    # 将档名转成日期时间格式
    def show_photo_time( file_name )
      y = file_name[0,4]
      mo = file_name[5,2]
      d = file_name[7,2]
      h = file_name[10,2]
      mi = file_name[12,2]
      s = file_name[14,2]
      return "#{y}-#{mo}-#{d} #{h}:#{mi}:#{s}"
    end

    # 取得某个月份的流动资产目标
    def get_current_assets_goal( input_time )
      goal_arr = value_of('goal_of_monthly_current_assets').split(',')
      month_arr = content_of('goal_of_monthly_current_assets').split(',')
      i = month_arr.index("#{input_time.year}-#{input_time.month}")
      i ? goal_arr[i].to_i : 0
    end

    # 若为正数则在数字前面加上"+"
    def add_plus( num )
      num > 0 ? "+#{num}" : "#{num}"
    end

    # 取得本月份的流动资产目标
    def get_this_month_current_assets_goal
      get_current_assets_goal( Time.now )
    end

    # 取得下个月份的流动资产目标
    def get_next_month_current_assets_goal
      get_current_assets_goal( Time.now + 1.month )
    end

    # 取得下个季度的流动资产目标
    def get_multi_months_current_assets_goal( num )
      result = "" ; now = Time.now
      (1..num).each do |i|
        next_time = now + i.month
        goal = get_current_assets_goal(next_time)
        # 计算当前的值与目标差多少
        diff_goal = @total_current_assets-goal
        # 如果没达目标，则显示每月需存款多少
        month_ave_str = diff_goal < 0 ? "  月存：#{((diff_goal*-1)/month_diff(now,next_time)/value_of("exchange_rates_MCY").to_f).to_i} RMB" : ''
        result += "#{next_time.year}年#{next_time.month}月目标：#{goal}(#{add_plus(@total_current_assets-goal)})#{month_ave_str}\n"
      end
      result
    end

    # 取得下个季度的流动资产目标
    def get_next_season_current_assets_goal
      return get_multi_months_current_assets_goal 3
    end

    # 取得下半年的流动资产目标
    def get_next_half_year_current_assets_goal
      return get_multi_months_current_assets_goal 6
    end

    # 取得下一年的流动资产目标
    def get_next_year_current_assets_goal
      return get_multi_months_current_assets_goal 26
    end       

    #显示流動資產达标或未达标图示
    def show_current_assets_icon(this_month_current_assets_goal,this_month_current_assets_value,append_str = '')
      result = "&nbsp;"
      excess_value = this_month_current_assets_value-this_month_current_assets_goal
      excess_or_less_value_ntd = excess_value.abs
      excess_or_less_value_mcy = (excess_or_less_value_ntd.to_f/value_of('exchange_rates_MCY').to_f).to_i
      prename_str = "本月目标：#{this_month_current_assets_goal} NT，"
      express_str = " #{excess_or_less_value_ntd} NT(#{excess_or_less_value_mcy} RMB) "
      icon_width =  icon_height = 16 ; icon_align = "top"
      if excess_value >= 0
        result << image_tag('icon/victory.bmp', :width => icon_width, :height => icon_height, :align => icon_align, :title => "#{prename_str}已超標#{express_str}" + append_str )
      else
        result << image_tag('icon/cry.bmp', :width => icon_width, :height => icon_height, :align => icon_align, :title => "#{prename_str}尚欠#{express_str}" + append_str )
      end
      return result
    end

    # 显示包含中文星期的日期
    def show_chinese_full_date( date )
      "#{date.strftime('%Y-%m-%d')} (#{show_chinese_week(date.strftime('%w').to_i)})"
    end

    # 显示活动内容的说明
    def activity_description( act )
      result = %Q{名称：#{act.title}\n日期：#{act.begin_date}\n时间：#{show_time(act.begin_time)}\n地点：#{act.place}\n講師：#{act.teachers}\n司会：#{act.manager}\n服侍：#{act.cleaner}
      }
    end

    # 显示流动资产链接
    def link_to_current_assets
      ca = get_last_current_assets_changes
      if ca.rec_date == Date.today
        # 如果今天已有资料，则直接显示change_value的值就好
        show_value = ca.change_value > 0 ? "+#{ca.change_value.to_i}" : "#{ca.change_value.to_i}"
        link_to @total_current_assets, {:controller => 'param_changes', :action => 'new', :param_id => '124'}, {:title => "与昨日相比：#{show_value} 元", :target => '_blank'}
      elsif ca
        # 如果已有资料(但不是今天)，则显示计算后的值
        cal_value = (@total_current_assets-ca.value).to_i
        show_value = cal_value > 0 ? "+#{cal_value}" : "#{cal_value}"
        link_to @total_current_assets, {:controller => 'param_changes', :action => 'new', :param_id => '124'}, {:title => "比较最近记录(#{ca.rec_date})：#{show_value} 元", :target => '_blank'}
      else
        # 如果连一笔资料都没有，则不显示说明
        link_to @total_current_assets, {:controller => 'param_changes', :action => 'new', :param_id => '124'}, {:target => '_blank'}
      end
    end

    # 显示现金資產链接
    def link_to_total_flow_assets
      link_to @total_flow_assets.to_i, {:controller => 'param_changes', :action => 'new', :param_id => '52'}, {:target => '_blank'}
    end

    # 显示固定資產链接
    def link_to_total_fixed_assets
      @today_house_price_str = '' if !@today_house_price_str
      link_to @total_fixed_assets.to_i, {:controller => :asset_item_details, :action => :new, :asset_item_id => 93}, {:title => @today_house_price_str, :target => '_blank'}
    end

    # 显示資產淨值链接
    def link_to_net_asset_value
      link_to @net_asset_value.to_i, {:controller => 'param_changes', :action => 'new', :param_id => '129'}, {:title => "#{(@net_asset_value/value_of('exchange_rates_MCY').to_f).to_i} 人民币", :target => '_blank'}
    end

    def get_last_current_assets_changes
      rs = ParamChange.all(:conditions => "param_id=124", :order => "rec_date desc", :limit => 2) 
      rs ? rs.first : nil
    end

    # 显示将金句加入收藏链接
    def show_collect_golden_verse_link( index, redirect_to_action = nil )
      "<span class='golden_verse_link'>#{link_to('加入收藏', {:action => :collect_golden_verse, :i => index, :rta => redirect_to_action,:for_ppt => params[:for_ppt]})}</span>" # if !@collect_arr.include?(index)
    end

    # 显示将金句加入教材链接
    def show_collect_for_ppt_link( index, redirect_to_action = nil )
      "<span class='golden_verse_link'>#{link_to('加入教材', {:action => :collect_golden_verse, :i => index, :rta => redirect_to_action, :for_ppt => true})}</span>" # if !@collect_arr.include?(index)
    end

    # 显示将金句取消收藏链接
    def show_delete_golden_verse_link( index, redirect_to_action = nil )
      if @list_collect
        "<span class='golden_verse_link'>#{link_to('取消收藏', {:action => :delete_collect, :i => index, :rta => redirect_to_action, :for_ppt => params[:for_ppt]})}&nbsp;#{link_to('清空'+@verse_collect_for_me_title, :action => :delete_all_verse_collection)}&nbsp;#{link_to('清空'+@verse_collect_for_ppt_title, :action => :delete_all_verse_collection,:for_ppt => true)}</span>"
      end
    end  

    # 显示将金句的总字数
    def show_verse_length( verse )
      verse_length = verse ? verse.length : 0
      "<span class='white_words'>[#{verse_length}]</span>"
    end     

    # 显示金句上一句和下一句的链接
    def show_pre_next_verse_link(index)
      "<span class='golden_verse_link'>#{link_to("上一句",:action => "show_golden_verse", :i => index-1,:for_ppt => params[:for_ppt])}&nbsp;#{link_to("抽一句",:action => "show_golden_verse",:for_ppt => params[:for_ppt])}&nbsp;#{link_to("下一句",:action => "show_golden_verse", :i => index+1,:for_ppt => params[:for_ppt])}</span>"
    end    

    # 显示由此阅读以及全屏阅读链接(金句在独立的背景里显示)
    def show_read_start_here_link( index, list_collect = false, keywords = nil )
      "<span class='golden_verse_link'>#{link_to('由此阅读', :action => :show_golden_verse, :i => index)}&nbsp;#{link_to('全屏阅读', :action => :show_golden_verse_with_fix_bg, :i => index, :keywords => keywords, :list_collect => list_collect,:for_ppt => params[:for_ppt])}</span>"
    end

    # 显示返回前页(亦即show_golden_verse)
    def back_to_show_golden_verse( i = nil )
      "<span class='golden_verse_link'>#{link_to('返回前页', :action => :show_golden_verse, :i => i, :main_keywords_for_search => @keywords, :list_collect => @list_collect,:for_ppt => params[:for_ppt])}</span>"    
    end

    # 显示金句的排序链接
    def verse_order_link( index )
      "<span class='golden_verse_link'>#{link_to('↑',{:action => 'verse_collect_order_up',:i => index,:for_ppt => params[:for_ppt]},{:title => '上移'})} #{link_to('↓',{:action => 'verse_collect_order_down',:i => index,:for_ppt => params[:for_ppt]},{:title => '下移'})} #{link_to('△',{:action => 'verse_collect_order_top',:i => index,:for_ppt => params[:for_ppt]},{:title => '移到最顶'})} #{link_to('▽',{:action => 'verse_collect_order_bottom',:i => index,:for_ppt => params[:for_ppt]},{:title => '移到最底'})}</span>"
    end

    # 显示我的座右铭
    def show_my_motto
      my_motto = value_of("my_motto")
      style = content_of("my_motto")
      "<div width='100%' style='#{style}'>#{my_motto}</div>" if !my_motto.empty?
    end

    # 显示档案系统里的图片
    def show_folder_images( files, photo_path = '', image_height = 15 )
      result = ""
      files.each do |filename|
        result += image_tag("#{photo_path}#{filename}.jpg", {:height => image_height, :align => 'absmiddle', :border => 1, :title => filename, :onmouseout => "hiddenPic();", :onmousemove => "showPic('/images/#{photo_path}#{filename}.jpg');"}) + "&nbsp;"
      end
      return result
    end

    # 以表格显示档案系统里的图片
    def show_folder_images_in_table( files, photo_path, image_width = 100, float_left = true, max_num_in_row = 5, table_border = 0 )
      
      result = "<table border='#{table_border}' cellpadding='5' cellspacing='5' style='border-collapse: collapse' bordercolor='#999999' align='left'>"
      n = 0
      if float_left # 浮动显示，不必设定每行显示几张
        result += "<tr><td align='left' style='float:left'>"
        files.each do |file_name|
          result += link_to(image_tag("#{photo_path}#{file_name}.jpg", :width => image_width, :style => "margin:0.3em"),"/images/#{photo_path}#{file_name}.jpg",:target => '_blank')
        end
        result += "</td></tr>"      
      else
        files.each do |file_name|
          if n % max_num_in_row == 0
            result += "<tr>"
          end
          result += "<td align='left'>" + link_to(image_tag("#{photo_path}#{file_name}.jpg", :width => image_width),"/images/#{photo_path}#{file_name}.jpg",:target => '_blank') + "</td>"
          n += 1
          if n % max_num_in_row == 0
            result += "</tr>"
          end      
        end
      end
      result += "</table>"

    end

    # 显示近期奉献资料
    def get_recent_donation_data( catalog_id = 1, num_month_ago = 12 )
      recent_donation = Donation.find_by_sql("SELECT accounting_date, SUM (amount) as total FROM donations WHERE catalog_id = #{catalog_id} and accounting_date >= '#{(Time.now-num_month_ago.month).strftime("%Y-%m-01")}' and accounting_date < '#{(Time.now).strftime("%Y-%m-01")}' GROUP BY accounting_date")
      month_data_str = ""
      sum_of_total = 0.0
      recent_donation.each do |d|
        month_data_str += link_to( d.total.to_i, '#', :title => d.accounting_date) + "&nbsp;&nbsp;"
        sum_of_total += d.total.to_f
      end
      month_ave = (sum_of_total/recent_donation.size).to_i # 近期每月平均
      return {:month_data => month_data_str, :month_ave => month_ave}
    end

    # 距离财务自由还差多少钱
    def remain_money_for_financial_freedom( from_date = Date.today )
      should_prepare = fee = 0
      @remain_money_for_financial_freedom_note = "明細如下:\n"
      #1.还清所有貸款項目(包含新光人寿保单贷款和中国太平人寿保单贷款)
          should_prepare += @total_loan_value.to_i
          @remain_money_for_financial_freedom_note += "所有貸款本利和: #{@total_loan_value.to_i}\n"
      #2.缴清所有保费
          all_insurance_remain = cal_all_insurance_remain(from_date)
          should_prepare += all_insurance_remain[:fee]
          @remain_money_for_financial_freedom_note += all_insurance_remain[:note]
      #3.直到领生存年金前需准备的生活费
              # 没有收入后，每日需多少新台币以维持生活
              @retire_daily_money = value_of("retire_daily_money").to_i
              # 金如意年金保险每日可补贴的金额
              jry_insurance_daily_back = 300000/3/365
              # 房租的收入每日可补贴的金额(暂时不计算，因为房子可能自住)
               real_rent_income_daily_back = ((value_of("real_rent_income").to_i)*(@rmb_rate)/365).to_i
              # 如果现在马上没有收入，则到开始能靠保险金养老的日期，还需要存多少钱
                @get_insurance_date = value_of("begin_insurance_back")
                fee = (@retire_daily_money-jry_insurance_daily_back)*(@get_insurance_date.to_date - value_of("retire_date_for_real_cal").to_date).to_i
                should_prepare += fee
                @remain_money_for_financial_freedom_note += "直到领生存年金前需准备的生活费: #{fee}\n" if fee != 0
      #4.目前可用的現金资产总值
              current_money = (@total_flow_assets - @total_plan_use).to_i
              @remain_money_for_financial_freedom_note += "目前可用的現金资产总值: #{current_money}\n" if fee > 0
      # 加总：所有应该准备的钱 - 目前手上已有的钱
              return should_prepare - current_money
    end

    # 计算所有未缴保费的总值
    def cal_all_insurance_remain( from_date, max_until_date = nil )
      result_fee = 0
      note = ""
      # 1) 太平一諾千金終身壽險20萬(001003495896008) : 9020 RMB : 12/9交费~2029年
            fee = cal_insurance_remain_fee_nt(9020,'MCY','2029/12/9',from_date,max_until_date)
            result_fee += fee
            note += "一諾千金: #{fee}\n" if fee > 0
      # 2) 太平福禄双至终身寿险8萬 : 1936 RMB : 10/15交费~2039年
            fee = cal_insurance_remain_fee_nt(1936,'MCY','2039/10/15',from_date,max_until_date)
            result_fee += fee
            note += "福禄双至: #{fee}\n" if fee > 0
      # 3) 太平附加真爱提前给付重大疾病保险 : 672 RMB : 10/15交费~2039年
            fee = cal_insurance_remain_fee_nt(672,'MCY','2039/10/15',from_date,max_until_date)
            result_fee += fee
            note += "提前给付: #{fee}\n" if fee > 0
      # 4) 太平狀元附加大學教育年金保險 : 2123 RMB : 12/9交费~2024年
            fee = cal_insurance_remain_fee_nt(2123,'MCY','2024/12/9',from_date,max_until_date)
            result_fee += fee
            note += "大學年金: #{fee}\n" if fee > 0
      # 5) 太平陽光天使少兒兩全保險(001003495906008) : 512 RMB : 12/9交费~2024年
            fee = cal_insurance_remain_fee_nt(512,'MCY','2024/12/9',from_date,max_until_date)
            result_fee += fee
            note += "陽光天使兩全: #{fee}\n" if fee > 0
      # 6) 太平附加陽光天使少兒重大疾病保險 : 67 RMB : 12/9交费~2024年
            fee = cal_insurance_remain_fee_nt(67,'MCY','2024/12/9',from_date,max_until_date)
            result_fee += fee
            note += "陽光天使重病: #{fee}\n" if fee > 0
      # 7) 太平真愛附加豁免保險費定期壽險 : 68.6 RMB : 12/9交费~2024年
            fee = cal_insurance_remain_fee_nt(68.6,'MCY','2024/12/9',from_date,max_until_date)
            result_fee += fee
            note += "豁免保費: #{fee}\n" if fee > 0
      # 8) 新光人壽健康久久終身醫療健康保險(1001032926) : 23412 NT : 3/11交费~2018年
            fee = cal_insurance_remain_fee_nt(23412,'NTD','2018/3/11',from_date,max_until_date)
            result_fee += fee
            note += "新光終身醫療: #{fee}\n" if fee > 0
      # 9) 金如意年繳附約保費 : 1039 NT：12/18交费~2039年
            fee = cal_insurance_remain_fee_nt(1039,'NTD','2039/12/18',from_date,max_until_date)
            result_fee += fee
            note += "金如意附約: #{fee}\n" if fee > 0
      # 10) 新防癌終身年繳附約保費 : 1928 NT：12/28交费~2039年
            fee = cal_insurance_remain_fee_nt(1928,'NTD','2039/12/28',from_date,max_until_date)        
            result_fee += fee
            note += "新防癌附約: #{fee}\n" if fee > 0
      # 11) 孟丽的社保退休年金：850 RMB：每月缴费~2029年
            #fee = cal_insurance_remain_fee_nt(850*12,'MCY','2029/12/31',from_date,max_until_date)
            #result_fee += fee
            #note += "孟丽的社保退休年金: #{fee}\n" if fee > 0            
      return { :fee => result_fee, :note => note }
    end

    # 计算尚需缴交的保费总值(输出结果的货币单位为新台币)
    def cal_insurance_remain_fee_nt( year_fee, currency, until_date, from_date = Date.today, max_until_date = nil )
      if max_until_date and until_date.to_date > max_until_date.to_date
        until_date = max_until_date.to_date
      else
        until_date = until_date.to_date
      end
      day_diff = (until_date - from_date).to_i
      if day_diff > 0 
        return (year_fee * (day_diff/365.to_i+1) * value_of("exchange_rates_#{currency}").to_f).to_i
      else
        return 0
      end
    end

    # 根据距离财务自由还差多少钱及每月最多可存款的钱来计算实际可以退休的日期
    def actual_retire_date(remain_money_for_free, month_save_money)
      days_for_save_money = ((remain_money_for_free.to_f/month_save_money)*30).to_i #一个月以30天来计算
      return (Date.today + days_for_save_money).to_s(:db)
    end

    # 取出接案收入的参数列表
    def build_params_from_pname( pname = 'params_of_retire_default' )
      value_of(pname).split("&").each do |item|
          k = item.split("=")[0] ; v = item.split("=")[1]
          params[k.intern] = v
      end
      # 设定开始日期为今天
      today = Date.today
      params[:t15_y] = today.year
      params[:t15_m] = today.month
      params[:t15_d] = today.day
    end

    # 我的帐户中以NTD计算的流动资产总值
    def sum_of_ntd_flow_assets
      sum_money_of 'flow_assets', 'NTD', 1, '', false, 'NTD'
    end

    # 我的帐户中以MCY计算的流动资产总值
    def sum_of_mcy_flow_assets
      sum_money_of 'flow_assets', 'MCY', 1, '', false, 'MCY'
    end

    #准备收支试算表需要的参数
    def set_cal_retire_table_params( options = { :end_date => Date.today+6.months, :show_everyday => false } )
      # 取出接案收入的参数列表
      build_params_from_pname
      # 设定最终日
      params[:t16_y] = options[:end_date].year
      params[:t16_m] = options[:end_date].month
      params[:t16_d] = options[:end_date].day
      # 设定不显示标题
      params[:show_retire_table_title] = nil
      # 顯示每天的計算結果
      params[:o8] = options[:show_everyday]
    end    

    ######################### 以下由模擬系統專用 #########################    

    def main_function_bar
      result = []
      separated_mark = "|"
      result << separated_mark
      result << link_to( '模擬人物總覽', :controller => 'sim_characters' ) << separated_mark
      result << link_to( '新增模擬人物', :controller => 'sim_characters', :action => 'new' )
      result << separated_mark
      return "<div style='text-align:center;margin-bottom:1em'>#{result.join(' ').to_s}</div>"
    end

    # 随机取得模拟人物头像 ( 头像总数, 头像文档名最大数, 文档名前缀 )
    def get_rand_portrait_array( total_num, filename_max, filename_prefix )
      already_exist_icons = []
      SimCharacter.find_by_sql("select photo from sim_characters").each {|sc| already_exist_icons << sc.photo}
      result = []
      n = 0
      (1..total_num).each do
        while file_name = "#{filename_prefix}#{add_zero(rand(filename_max-1)+1)}" do     
          if not result.index(file_name) and not already_exist_icons.index(file_name) 
            result << file_name
            break
          elsif n > 100
            break
          end
          n += 1
        end
      end
      return result
    end

    # 显示头像图片 ( 头像档名阵列, 路径名前缀, 图档宽度, 图档高度, 每一行放几张 )
    def show_rand_portraits( rand_portrait_array, url_prefix, width, height, num_in_row )
      result = ""
      n = 1
      rand_portrait_array.each do |icon|
        result << image_tag("#{url_prefix}/#{icon}.jpg",:border=>0,:height => height,:width => width)
        result << "<br/>" if n % num_in_row == 0
        n += 1
      end
      return result
    end

    # 随机显示新建人物的名字
    def get_rand_character_name
      members = Member.find_by_sql("select name from members order by id desc limit 500")
      family_names = []
      last_names = []
      members.each do |m|
        family_word = m.name.split("")[0]
        last_word = m.name.split("")[1]
        family_names << family_word if not family_word =~ /[a-z]|[A-Z]/
        last_names << last_word if not last_word =~ /[a-z]|[A-Z]/
      end
      if family_names.size < 2
        return "无随机名可显示"
      else
        family_names.sort!
        temp_word = family_names[0]
        temp_words = []
        family_names[1..-1].each do |word|
          temp_words << word if word == temp_word
          temp_word = word
        end
        uniq_family_names = temp_words.uniq
        return uniq_family_names[rand(uniq_family_names.size-1)] + last_names[rand(members.size-1)] + last_names[rand(members.size-1)]
      end
    end

end
