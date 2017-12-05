class MembersController < ApplicationController
  
  after_filter :update_spouse_id, :only => [ :create, :update ]
  after_filter :update_or_create_member_report, :only => [ :create, :update, :destroy ]

  def index
    index_core   
  end
  
  def index_simple
    index_core
  end

  def index_core
    session[:last_url] = self.request.url
    prepare_for_index

    respond_to do |format|
      format.html { render :action => member_index_render_action }
      format.xml  { render :xml => @members }
    end
  end

  def family_report
    session[:last_url] = self.request.url
    area_id = session[:default_area_id].to_i
    @members = Member.find( :all, :order => 'blessing_number,birthday', :conditions => [ "sex_id = ? and career = '0' and area_id = ?", 1, area_id ], :include => :trace )

    Member.find( :all, :order => 'blessing_number,birthday', :conditions => [ "sex_id = ? and career = '0' and area_id = ? ", 0, area_id ], :include => :trace ).each do |m|
      # 如果是女性已祝福会员而主体不在本地的
      if m.spouse_id and Member.find(m.spouse_id).area_id != area_id
        @members << m
      end
    end
  
    @members.sort! {|a,b| a.blessing_number <=> b.blessing_number}

    @sub_title = @local_family_title + '成员'
  end
  
  def pray_list
    session[:last_url] = self.request.url
    @members = Member.all( :conditions => is_on_table_count_select, :include => :trace, :order => "traces.last_class_date,order_num" )
    @sub_title = @pray_list_title
    order_index_field( @members )
  end
        
  def prepare_for_index
    params[:cid] ||= 'local_all'  #类别預設值 local_disconnect_all
    params[:cid] = 'search_by_name' if params[:member_keywords_for_search] and !params[:member_keywords_for_search].empty?
    params[:aid] ||= session[:default_area_id]
    aid = params[:aid].to_i
    cid = params[:cid]
    set_new_area_id(aid) if params[:set_aid]
    order_str = 'members.birthday,members.sex_id,members.classification' # default_order_for_member_list
    classification_member_select_conditions = "sex_id = ? and classification = ? and area_id=#{session[:default_area_id]}"
    case params[:cid]
      when 'all'
        @members = Member.all( :order => order_str, :include => :trace, :conditions => db_total_count_select )
        @sub_title = @all_title
        @center_name = "管理系統"
      when 'local_all'
        @members = Member.all( :order => order_str, :include => :trace, :conditions => total_local_count_select( aid ) )
        @sub_title = @local_sum_title
      when 'local_effect_all'
        @members = Member.all( :order => order_str, :include => :trace, :conditions => total_local_effect_count_select( aid ) )
        @sub_title = '有效'
      when 'local_core_family_all'
        @members = Member.find_core_blessed_family( aid )        
        @sub_title = '核心家庭'
      when 'local_core_members_all'
        @members = Member.find_core_members( aid )        
        @sub_title = '核心會員' 
      when 'local_single_members_all'
        @members = Member.find_single_members( aid )   
        @sub_title = '單身會員'
      when 'local_new_all'
        @members = Member.find_new( aid )   
        @sub_title = '新人' 
      when 'local_disconnect_all'
        @members = Member.find_disconnect_members( aid )        
        @sub_title = '疏離'                     
      when 'leader_count'
        @members = Member.all( :order => order_str, :include => :trace, :conditions => total_local_leader_count_select( aid ) )
        @sub_title = @mr_titles[:leader_count]
      when 'staff_count'
        @members = Member.all( :order => order_str, :include => :trace, :conditions => total_local_staff_count_select( aid ) )
        @sub_title = @mr_titles[:staff_count]
      when 'family_count'
        @members = Member.find_blessed_family( aid, order_str )        
        @sub_title = @mr_titles[:family_count]
      when 'student_member_count'
        @members = Member.all( :order => order_str, :include => :trace, :conditions => sum_by_cid_and_aid_select( '1', aid ) )        
        @sub_title = @mr_titles[:student_member_count]
      when 'worker_member_count'
        @members = Member.all( :order => order_str, :include => :trace, :conditions => sum_by_cid_and_aid_select( '2', aid ) )        
        @sub_title = @mr_titles[:worker_member_count]              
      when 'generation2_1_count'
        @members = Member.get_local_g21_records( aid )        
        @sub_title = @mr_titles[:generation2_1_count]
      when 'generation2_2_count'
        @members = Member.get_local_g22_records( aid )        
        @sub_title = @mr_titles[:generation2_2_count]
      when 'generation2_3_count'
        @members = Member.get_local_g23_records( aid )        
        @sub_title = @mr_titles[:generation2_3_count]
      when 'supporter_count'
        @members = Member.get_local_supporter_records( aid )
        @sub_title = "所有學員"        
      when 'student_new_count'
        @members = Member.all( :order => order_str, :include => :trace, :conditions => sum_by_cid_and_aid_select( '6', aid ) )       
        @sub_title = @mr_titles[:student_new_count]
      when 'worker_new_count'
        @members = Member.all( :order => order_str, :include => :trace, :conditions => sum_by_cid_and_aid_select( '7', aid ) )        
        @sub_title = @mr_titles[:worker_new_count]                
      when 'blessedable_count'
        @members = Member.all( :order => order_str, :include => :trace, :conditions => total_local_blessedable_count_select( aid ) )       
        @sub_title = @mr_titles[:blessedable_count]
      when 'is_brother_count'
        @members = Member.all( :order => order_str, :include => :trace, :conditions => is_brother_count_select( aid ) )       
        @sub_title = "我的弟弟"
      when 'm_core_student'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 1, '1' ] ), 0, 18 )        
        @sub_title = @mr_titles[:m_core_student]    
      when 'm_core_young'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 1, '1' ] ), 19, 39 )
        @sub_title = @mr_titles[:m_core_young]
      when 'm_core_adult'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 1, '1' ] ), 40, 999 )
        @sub_title = @mr_titles[:m_core_adult]
      when 'm_core_college'
        @members = find_college_members( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 1, '1' ] ) )
        @sub_title = @mr_titles[:m_core_college]
      when 'f_core_student'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 0, '1' ] ), 0, 18 )
        @sub_title = @mr_titles[:f_core_student]
      when 'f_core_young'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 0, '1' ] ), 19, 39 )
        @sub_title = @mr_titles[:f_core_young]
      when 'f_core_adult'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 0, '1' ] ), 40, 999 )
        @sub_title = @mr_titles[:f_core_student]
      when 'f_core_college'
        @members = find_college_members( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 0, '1' ] ))
        @sub_title = @mr_titles[:f_core_college]
      when 'm_new_student'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 1, '2' ] ), 0, 18 )
        @sub_title = @mr_titles[:m_new_student]
      when 'm_new_young'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 1, '2' ] ), 19, 39 )
        @sub_title = @mr_titles[:m_new_young]
      when 'm_new_adult'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 1, '2' ] ), 40, 999 )
        @sub_title = @mr_titles[:m_new_adult]
      when 'm_new_college'
        @members = find_college_members( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 1, '2' ] ))
        @sub_title = @mr_titles[:m_new_college]
      when 'f_new_student'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 0, '2' ] ), 0, 18 )
        @sub_title = @mr_titles[:f_new_student]
      when 'f_new_young'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 0, '2' ] ), 19, 39 )
        @sub_title = @mr_titles[:f_new_young]
      when 'f_new_adult'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 0, '2' ] ), 40, 999 )
        @sub_title = @mr_titles[:f_new_adult]
      when 'f_new_college'
        @members = find_college_members( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 0, '2' ] ))
        @sub_title = @mr_titles[:f_new_college]
      when 'm_normal_student'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 1, '3' ] ), 0, 18 )
        @sub_title = @mr_titles[:m_normal_student]
      when 'm_normal_young'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 1, '3' ] ), 19, 39 )
        @sub_title = @mr_titles[:m_normal_young]
      when 'm_normal_adult'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 1, '3' ] ), 40, 999 )
        @sub_title = @mr_titles[:m_normal_adult]
      when 'm_normal_college'
        @members = find_college_members( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 1, '3' ] ))
        @sub_title = @mr_titles[:m_core_student]
      when 'f_normal_student'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 0, '3' ] ), 0, 18 )
        @sub_title = @mr_titles[:f_normal_student]
      when 'f_normal_young'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 0, '3' ] ), 19, 39 )
        @sub_title = @mr_titles[:f_normal_young]
      when 'f_normal_adult'
        @members = find_members_by_age( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 0, '3' ] ), 40, 999 )
        @sub_title = @mr_titles[:f_normal_adult]
      when 'f_normal_college'
        @members = find_college_members( Member.all( :order => order_str, :include => :trace, :conditions => [ classification_member_select_conditions, 0, '3' ] ))
        @sub_title = @mr_titles[:f_normal_college]
      when 'search_by_name'
        @members = Member.all( :conditions => "name like '%" + params[:member_keywords_for_search] + "%'" )
        @sub_title = "搜寻结果"
      else
        @members = Member.all( :order => order_str, :include => :trace, :conditions => sum_by_cid_and_aid_select( cid, aid ) )
        @sub_title = career_arr.rassoc(cid)[0].split('(')[0]
    end
    # 接受人员报表传过来的参数以便显示会员名单资料
    if params[:mids]
      mids = params[:mids].split(",").join(",")
      @members = Member.find_by_sql("select * from members where id in (#{mids})") if not mids.empty?
    end
    order_index_field( @members )
  end

  def find_members_by_age( members, begin_age, end_age )
    result = []
    members.each do |m|
      if m.get_age >= begin_age and m.get_age <= end_age
        result << m
      end
    end
    return result
  end

  def find_college_members( members )
    result = []
    members.each do |m|
      if m.is_college
        result << m
      end
    end
    return result
  end
    
  def set_new_area_id( area_id )
    session[:default_area_id] = area_id.to_i
    set_center_name
  end

  # GET /members/1
  # GET /members/1.xml
  def show
    @member = Member.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @member }
    end
  end

  # GET /members/new
  # GET /members/new.xml
  def new
    @member = Member.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @member }
    end
  end

  # GET /members/1/edit
  def edit  
    @member = Member.find( params[:id], :include => :trace )
  end

  # POST /members
  # POST /members.xml
  def create
    @member = Member.new(params[:member])
    respond_to do |format|
      if @member.save
        flash[:notice] = 'Member was successfully created.'
        format.html { redirect_to_index }
        format.xml  { render :xml => @member, :status => :created, :location => @member }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @member.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /members/1
  # PUT /members/1.xml
  def update
    @member = Member.find(params[:id])

    respond_to do |format|
      if @member.update_attributes(params[:member])
        flash[:notice] = 'Member was successfully updated.'
        format.html { redirect_to_index }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @member.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /members/1
  # DELETE /members/1.xml
  def destroy
    @member = Member.find(params[:id])
    @member.destroy

    respond_to do |format|
      format.html { redirect_to_index }
      format.xml  { head :ok }
    end
  end
  
  def select_status
    session[:last_url] = self.request.url
    mids = Trace.all( :include => :member, :order => "traces.star_level desc", :conditions => [ "traces.status_num = ? and members.classification != '0'", params[:s] ]).map {|t| t.member_id}
    @members = []
    for mid in mids
      @members << Member.find(mid)
    end
    @sub_title = status_arr.rassoc(params[:s].to_i)[0] if params[:s]
    order_index_field( @members )
    render :action => member_index_render_action
  end
  
  def member_index_render_action
    if params[:render_action]
      session[:member_index_render_action] = params[:render_action]
    elsif !session[:member_index_render_action]
      session[:member_index_render_action] = 'index_simple'
    end
    return session[:member_index_render_action]
  end

  def select_steps
    session[:last_url] = self.request.url
    @members = Member.find_by_step( params[:sid] )
    @sub_title = Step.find(params[:sid]).name
    order_index_field( @members )
    render :action => 'index_simple'
  end

  def select_next_steps
    session[:last_url] = self.request.url
    @members = Member.find_by_next_step( params[:sid] )
    @sub_title = "即將" + Step.find(params[:sid]).name.sub("已","")
    order_index_field( @members )
    render :action => 'index_simple'    
  end
  
  def select_all_pass_steps
    session[:last_url] = self.request.url
    @members = Member.all_pass_steps( params[:sid] )
    @members.sort! {|x,y|  x.trace.last_step_id  <=>  y.trace.last_step_id}
    @sub_title = "所有" + Step.find(params[:sid]).name
    order_index_field( @members )
    render :action => 'index_simple'
  end

  def select_children
    #session[:last_url] = self.request.url
    if params["m"] == "c"
      condition_str = "members.conductor_id = ?"
      title_words = "照顧對象"
    else
      condition_str = "members.introducer_id = ?"
      title_words = "靈子女"
    end
    @members = Member.all( :include => :trace, :conditions => [condition_str, params[:p]], :order => "traces.status_num" )
    @sub_title = Member.find(params[:p]).name + title_words
    order_index_field( @members )
    render :action => 'index_simple'
  end
    
  def picture_list
  	  session[:last_url] = self.request.url
      @members = Member.all( :conditions => "classification > '0'", :order => 'classification desc')
  end
  
  def conductor_list
    session[:last_url] = self.request.url
    @html = '<table width="100%" style="background-color: transparent;"><tr><td>'
    @image_height = 200
    @img_onclick_action = 'javascript:document.location.href="/traces/appointment";'
    member_data_order = "traces.appointment_made desc, traces.appointment_promise desc, traces.last_class_date desc, traces.star_level desc"

    if session[:login_role] != 'admin'
      conditions_str = [ "id = ?", session[:login_mid] ]
    else
      conditions_str = [ "is_team_leader =? and classification > '0'", true ]
    end
    
    conductors = Member.all( :conditions => conditions_str, :include => :trace, :order => 'members.career, members.id' )
    conductors.each do |conductor|

        conditions_for_members = [ "conductor_id = ? and classification > '0'", conductor.id ]
        conditions_for_childrens = [ "introducer_id = ? and classification > '0'", conductor.id ]

        conductor_header = "<div class='conductor_desr'><img src='/images/icon/medal.png' align='absmiddle' height='20' /> <a href='/members/#{conductor.id}/edit'>愛心小組長：#{conductor.name}</a></div>"
        conductor_footer = "<div class='conductor_next_class_date'><a href='/traces/#{conductor.id}/edit'>#{conductor.mobile}</a></div>"
        @html += "<table border='1' cellpadding='7' cellspacing='0' style='border-collapse: collapse' bordercolor='#444444'><tr><td>#{conductor_header}<img src='/images/portrait/#{conductor.get_picture}' height='#{@image_height}' class='conductor_img' title='#{get_next_class_desr(conductor.trace)}' onclick='#{@img_onclick_action}' /><br/>#{conductor_footer}</td>"

        members = Member.all( :conditions => conditions_for_members, :include => :trace, :order => member_data_order )
        childrens = Member.all( :conditions => conditions_for_childrens, :include => :trace, :order => member_data_order )
        members -= childrens
        @html += space_line( '#95C7F2' )  if members.size > 0
        members.each {|m| compose_member_data(m)}
        @html += space_line( '#EF909E' )  if childrens.size > 0
        childrens.each { |c| compose_member_data(c) }

        @html += '</tr></table><hr class="dashed_line"/><br/>'
    end
    @html += '</td></tr></table>'
  end
  
  def compose_member_data( member )
    member_header = "<div class='conductor_member_header'><a href='/members/#{member.id}/edit'>#{member.name} #{member.mobile.slice(0,13)}</a></div>"
    member_footer = "<div class='conductor_next_class_date'><img src='/images/icon/star_#{member.trace.star_level}.gif' title = '#{star_arr.rassoc(member.trace.star_level)[0]}' align='absmiddle' border='0'/> #{show_appointment_info(member)}</div>"
    @html += "<td>#{member_header}<img src='/images/portrait/#{member.get_picture}' height='#{@image_height}' class='conductor_img' title='#{get_next_class_desr(member.trace)}' onclick='javascript:document.location.href=\"/traces/#{member.id}/edit\";' /><br/>#{member_footer}</td>"
  end
  

  def work_turn_list
    @output_html = Param.find_by_name('work_turn_html').content
  end
  
  def work_turn_edit
  end
  
  def update_work_turn_html
    if params[:work_turn_html].size >= 10
      Param.find_by_name('work_turn_html').update_attribute( :content, params[:work_turn_html] )
      redirect_to :action => 'work_turn_list'
    end    
  end

  def update_conductor_id
    Member.all.each do |m|
      if !m.conductor.empty?
        conductor = Member.first( :conditions => ["name = ?", m.conductor] )
        m.update_attribute( :conductor_id, conductor.id ) if conductor
      end
    end
    render :text => "更新完成!"
  end
  
  def update_introducer_id
    Member.all.each do |m|
      if !m.introducer.empty?
        introducer = Member.first( :conditions => ["name = ?", m.introducer] )
        if introducer
          m.update_attribute( :introducer_id, introducer.id )
        else
          member = Member.create( :name => m.introducer, :classification => '0', :birthday_still_unknow => true )
          m.update_attribute( :introducer_id, member.id )
        end
      end
    end
    render :text => "更新完成!"
  end

  def update_null_introducer_id_to_0
    Member.all.each do |m|
      if !m.introducer_id or m.introducer_id == 55
          m.update_attribute( :introducer_id, 0 )
      end
    end
    render :text => "更新完成!"
  end

  def clear_all_step_ids
    Member.all.each do |m|
      m.trace.update_attribute( :step_ids, "" )
    end
    render :text => "更新完成!"
  end
     
  def xml_list
    respond_to do |format|
        format.html do
          render :text => "HTML Format!", :layout => false
        end
        format.xml  do 
          xml_result = ""
          default_max_contact_days = 40
          Member.all_on_table.each do |m|
            xml_result += "<item tid=\"#{Trace.find_by_member_id(m.id).id}\" name=\"#{m.name}\" mobile=\"#{m.mobile}\" birthday=\"#{m.birthday}\" max_contact_days=\"#{default_max_contact_days}\" class_title=\"#{m.trace.last_class_title}\" contact=\"#{m.trace.last_class_date}\" think=\"#{m.trace.class_feel}\" interest=\"#{m.interest}\" teacher=\"#{m.trace.last_class_teacher}\"/>"
          end
          xml_result = '<?xml version="1.0" encoding="utf-8"?><data><heart_children>' + xml_result + '</heart_children></data>'
        	render :text => xml_result
     	end
    end  	
  end  
  
  def order_up
    exe_order_up Member, params[:id]
    redirect_to :action => 'pray_list'
  end
  
  def order_down
    exe_order_down Member, params[:id]
    redirect_to :action => 'pray_list'
  end  

  def update_table_field_value
    exe_update_table_field_value( Member )
    if request.xhr? 
        respond_to { |format| format.js } 
    else 
        redirect_to :action => :pray_list
    end      
  end  
  
  #自動變更classification (群眾)
  def auto_change_to_QunZhong
      mids = params[:mids].to_a
      count = 0
      mids.each do |mid|
        @member = Member.find(mid)
        @member.update_attribute( :classification , '4' )  # [ ['核心會員','1'],['新進人員','2'],['一般會員','3'],['群眾基台','4']]
        count = count + 1
      end
      flash[:notice] = "#{count}笔紀錄更新成功！"
      redirect_to_index    
  end

  #自動更新所有人员的sex_id
  def auto_update_sex_id
      count = 0
      Member.all.each do |m|
        sex_id = m.sex == '男' ? 1 : 0
        m.update_attribute( :sex_id , sex_id )
        count = count + 1
      end
      flash[:notice] = "#{count}笔紀錄更新成功！"
      redirect_to_index    
  end  
  
  #變更類別為家庭
  def career_change_to_family
      mids = params[:mids].to_a
      count = 0
      mids.each do |mid|
        @member = Member.find(mid)
        @member.update_attribute( :career , 0 )  #...['家庭','0']
        count = count + 1
      end
      flash[:notice] = "#{count}笔紀錄更新成功！"
      redirect_to_index    
  end

  #變更類別為群众
  def career_change_to_QunZhong
      mids = params[:mids].to_a
      count = 0
      mids.each do |mid|
        @member = Member.find(mid)
        @member.update_attribute( :career , 99 )  #...['家庭','0']
        count = count + 1
      end
      flash[:notice] = "#{count}笔紀錄更新成功！"
      redirect_to_index    
  end  
  
  #批量删除所选取的人员
  def delete_select_members
  	mids = params[:mids].to_a
      count = 0
      mids.each do |mid|
        @member = Member.find(mid)
        @member.destroy
        count = count + 1
      end
      flash[:notice] = "#{count}笔紀錄删除成功！"
      redirect_to_index
	end
  
  #變更地區為北京
  def area_change_to_BeiJing
      mids = params[:mids].to_a
      count = 0
      mids.each do |mid|
        @member = Member.find(mid)
        @member.update_attribute( :area , 6 )  #[ ['大中華圈',0],['中國大陸',1],['北京',2],['上海',3],['廣州',4],['武漢',5],['大連',6],['天津',7],['廈門',8],['首爾',9],['官校',10]]
        count = count + 1
      end
      flash[:notice] = "#{count}笔紀錄更新成功！"
      redirect_to_index    
  end  

  #地區全部变為北京
  def all_area_change_to_BeiJing
      count = 0
      Member.all.each do |m|
        m.update_attribute( :area , 2 )  #...['北京','2']
        count = count + 1
      end
      flash[:notice] = "#{count}笔紀錄更新成功！"
      redirect_to_index    
  end
  
  #自動更新群眾基台的career值
  def update_QunZhong_value
      count = 0
      Member.all( :conditions => "classification = '0'" ).each do |m|
        m.update_attribute( :career , '99' )  #...['群眾基台','99']
        count = count + 1
      end
      flash[:notice] = "#{count}笔紀錄更新成功！"
      redirect_to_index    
  end    	
       
  #批量设为admin_only
  def auto_set_admin_only
    mids = params[:mids].to_a
    count = 0
    mids.each do |mid|
      @member = Member.find(mid)
      @member.update_attribute( :admin_only , true )
      count = count + 1
    end
    flash[:notice] = "#{count}笔紀錄更新成功！"
    redirect_to_index
  end

  private
    
  def space_line( bgcolor )
    "<td width='5' bgcolor='#{bgcolor}' />"
  end

  def update_spouse_id
		if params[:member][:spouse_id] and params[:member][:spouse_id].to_i > 0
  		m = Member.find(params[:member][:spouse_id].to_i)
  		if m.spouse_id.nil?
  			m.update_attribute( :spouse_id, @member.id )
			end
		end
	end
  
  def set_default_if_none
    #params[:member][:classification] = '1' if params[:member][:classification].empty?
    #params[:member][:introducer_id] = session[:login_mid] if params[:member][:introducer_id].empty?
    #params[:member][:conductor_id] = session[:login_mid] if params[:member][:classification].empty?    
  end

  def auto_update_admin_only
    Member.all( :conditions => [ "career = '0' or career = '5'"] ).each do |m|
      m.update_attribute( :admin_only, true )
    end
  end  
  
end