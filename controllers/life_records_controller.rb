class LifeRecordsController < ApplicationController
  # GET /life_records
  # GET /life_records.xml
  def index

    @life_records = []    
    if params[:cid]
      con_arr = use_life_catalog_goal_minutes? ? ["life_items.life_catalog_id  =  ? AND life_records.rec_date >= ?",  params[:cid], life_rec_start_date ] : ["life_items.life_catalog_id  =  ? AND life_items.is_goal = ? AND life_records.rec_date >= ?",  params[:cid], true, life_rec_start_date ]
      LifeItem.all( :include => :life_records, :order => "life_records.rec_date desc, life_records.life_item_id", :conditions => con_arr ).each { |item| item.life_records.each { |r| @life_records << r } }
      @life_records.sort! {|x,y|  y.rec_date  <=>  x.rec_date}
    elsif params[:tid]
      @life_records = LifeRecord.all( :include => :life_item, :order => "rec_date desc, life_item_id", :conditions => ["life_item_id  =  ? AND rec_date >= ?",  params[:tid], life_rec_start_date] )
    elsif params[:rdate]
      @life_records = get_life_records_by_rec_date( params[:rdate] )
    elsif params[:key]
      @life_records = LifeRecord.all( :include => :life_item, :order => "rec_date desc, life_item_id", :conditions => "life_records.memo like '%#{params[:key]}%'" )
      @keyword = params[:key]
    else
      #@life_records = only_goalable_life_records( LifeRecord.all( :include => :life_item, :order => "life_records.rec_date desc,life_records.id desc", :conditions => ["rec_date >= ?",  life_rec_start_date], :limit => 400 ) )
      @life_records = LifeRecord.all( :include => :life_item, :order => "life_records.rec_date desc,life_records.id desc", :conditions => ["rec_date >= ?",  life_rec_start_date], :limit => 400 )
    end
    load_page_params

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @life_records.to_xml.gsub("-","_") }
    end
  end

  # GET /life_records/1
  # GET /life_records/1.xml
  def show
    @life_record = LifeRecord.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @life_record }
    end
  end

  # GET /life_records/new
  # GET /life_records/new.xml
  def new
  	if params[:id]
  		ini_life_record_from_id
  	else			
	    @life_record = LifeRecord.new
	    @life_record.rec_date = Date.today.to_s(:db)
    end
  
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @life_record }
    end
  end

  # GET /life_records/1/edit
  def edit
    @life_record = LifeRecord.find(params[:id])
  end

  def create_by_xhr
    data = params[:create_life_record_str].split("::")
    @life_record = LifeRecord.new()
    @life_record.life_item_id = data[0].to_i
    @life_record.rec_date = Date.today.to_s(:db)
    @life_record.used_minutes = data[1].to_i
    @life_record.memo = data[2]
    @life_record.is_not_goal = false
    if @life_record.save
      if request.xhr? 
        respond_to { |format| format.js } 
      else 
        redirect_to :action => :index
      end   
    end 
    
  end
  
  def create_by_click
	ini_life_record_from_id
    respond_to do |format|
      if @life_record.save
        flash[:notice] = "LifeRecord was successfully created at #{Time.now.to_s(:db)}"
        format.html { redirect_to(life_records_url) }
        format.xml  { render :xml => @life_record, :status => :created, :location => @life_record }
      end
    end
  end
  
  # POST /life_records
  # POST /life_records.xml
  def create  
    @life_record = LifeRecord.new(params[:life_record])

    respond_to do |format|
      if @life_record.save
        flash[:notice] = "LifeRecord was successfully created at #{Time.now.to_s(:db)}"
        format.html { redirect_to(life_records_url) }
        format.xml  { render :xml => @life_record, :status => :created, :location => @life_record }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @life_record.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /life_records/1
  # PUT /life_records/1.xml
  def update
    @life_record = LifeRecord.find(params[:id])

    respond_to do |format|
      if @life_record.update_attributes(params[:life_record])
        flash[:notice] = 'LifeRecord was successfully updated.'
        format.html { redirect_to(life_records_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @life_record.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /life_records/1
  # DELETE /life_records/1.xml
  def destroy
    @life_record = LifeRecord.find(params[:id])
    @life_record.destroy

    respond_to do |format|
      format.html { redirect_to(life_records_url) }
      format.xml  { head :ok }
    end
  end

  def xml_list
    respond_to do |format|
        format.html do
          redirect_to :action => :index
        end
        format.xml  do 
          xml_result = ""
          last_record_catalog_id = get_last_record_catalog_id
          min_item_catalog_id = get_min_item_catalog_id
          LifeCatalog.all( :include => :life_items, :conditions => ["life_catalogs.chartable = ?", true] ).each do |c|
            xml_result += "<record>\n"
            sum_of_used_minutes = c.total_minutes.to_f
            if c.id == min_item_catalog_id
              star_mark = "☆"
            elsif c.id == last_record_catalog_id
              star_mark = "★"
            else
              star_mark = ""
            end
            xml_result += "<name>#{star_mark}#{c.name}</name>\n"
            xml_result += "<order_num>#{c.order_num}</order_num>\n"
            xml_result += "<note>#{get_sum_note(sum_of_used_minutes)}#{get_last_life_record_memo(c.id)}</note>\n"
            xml_result += "<score>#{sprintf('%.2f', sum_of_used_minutes*c.weight)}</score>\n"
            xml_result += "</record>\n"
          end
          xml_result = '<?xml version="1.0" encoding="utf-8"?><data>' + xml_result + '</data>'
        	render :text => xml_result
     	end
    end  	    
  end
  
  def get_sum_note( sum_of_used_minutes )
    sum_of_used_minutes >= 60 ? sprintf('%.2f', sum_of_used_minutes/60)+"小時" : "#{sum_of_used_minutes}分鐘"
  end
      
  def update_used_minutes
    @life_record = LifeRecord.find(params[:id])
    if @life_record.update_attribute(:used_minutes,params[:used_minutes])
      if request.xhr? 
        respond_to { |format| format.js } 
      else 
        redirect_to :action => :index
      end   
    end 
  end    

  def update_life_rec_start_date
    @param = Param.find_by_name('life_rec_start_date')
    if @param.update_attribute(:value,params[:life_rec_start_date])
      LifeItem.update_all_total_minutes
      if request.xhr? 
        respond_to { |format| format.js } 
      else 
        redirect_to :action => :index
      end   
    end     
  end   

  def update_life_rec_goal_minutes
    @param = Param.find_by_name('life_rec_goal_minutes')
    if @param.update_attribute(:value,params[:life_rec_goal_minutes])
      if request.xhr? 
        respond_to { |format| format.js } 
      else 
        redirect_to :action => :index
      end   
    end     
  end
  
  def update_all_rec_date
      LifeRecord.all.each do |r|
          r.update_attribute( :rec_date, r.rec_date.to_date.to_s(:db).slice(0..9) )
      end
      render :text => "update_all_rec_date ok!"
  end
  
  def force_complete_today
  	add_date_to_all_goal_of_today_completed_data( Date.today.to_s(:db) )
  	flash[:notice] = "今日的目標已全部完成!"
  	redirect_to :action => :index
  end
  
  def switch_goal_minutes_mode
  	if use_life_catalog_goal_minutes?
  		Param.find_by_name('use_life_catalog_goal_minutes').update_attribute( :value, "false")
  	else
  		Param.find_by_name('use_life_catalog_goal_minutes').update_attribute( :value, "true")
  	end
  	flash[:notice] = "目標顯示模式已切換完成!"
  	redirect_to :action => :index  	
  end
  
  private

  def get_life_records_by_rec_date( rec_date, show_all = true )
        life_records = LifeRecord.all( :include => :life_item, :order => "life_records.life_item_id", :conditions => ["life_records.rec_date = ?",  rec_date] )
        if not show_all
            life_records = only_chartable_life_records(life_records)
        end
        return life_records
  end
    
  def only_chartable_life_records( life_records )
    find_life_catalog_records( life_records, "chartable", true )    
  end

  def only_goalable_life_records( life_records )
    find_life_catalog_records( life_records, "goalable", true )    
  end
  
  def find_life_catalog_records( ori_life_records, catalog_field_name, catalog_field_value )
    result = []
    ori_life_records.each do |r|
      result << r if r.life_item.life_catalog.attributes[catalog_field_name] == catalog_field_value
    end  
    return result    
  end
  
  def diff_goal_minutes_of_today
      life_records = only_goalable_life_records( LifeRecord.all( :include => :life_item, :conditions => ["rec_date = ? AND is_not_goal != ?",  Date.today.to_s(:db), true] ) )
      if not life_records.empty?
          total_used_minutes = 0
          life_records.each { |r| total_used_minutes += r.used_minutes }
          return life_rec_goal_minutes.to_i - total_used_minutes
      else
          return life_rec_goal_minutes.to_i
      end      
  end
  
  def get_last_record_catalog_id
      life_records = only_chartable_life_records( LifeRecord.all( :order => "id desc", :limit => 10 ) )      
      life_records[0].life_item.life_catalog_id
  end

  def load_page_params
    @life_rec_start_date = life_rec_start_date
    @life_rec_goal_minutes = life_rec_goal_minutes
    @goal_completed_days = Param.find_by_name('all_goal_of_today_completed_data').value
    @use_life_catalog_goal_minutes = Param.find_by_name('use_life_catalog_goal_minutes').value
  end

  def load_diff_goal_minutes_str
    frame_width = 150
    diff_goal_minutes = diff_goal_minutes_of_today
    diff_goal_minutes_percent = diff_goal_minutes.to_f / life_rec_goal_minutes.to_i
    bar_width = frame_width*diff_goal_minutes_percent
    icon_file = "g_bar.png"
    icon_file = "y_bar.png" if diff_goal_minutes_percent*100 < 50
    icon_file = "r_bar.png" if diff_goal_minutes_percent*100 < 20
    @diff_goal_minutes_str = diff_goal_minutes > 0 ? "<div style='margin-left:-15px;width:#{frame_width}px;height:7px;border:1px solid #000000;background-color:#FFFFFF'><img src='/images/icon/#{icon_file}' style='width:#{bar_width}px;height:7px;' title='享受生活還有#{diff_goal_minutes.to_s}分鐘'/></div>" : ""
  end

  def get_last_life_record_memo( life_catalog_id )
    result="\n"
    life_items = LifeCatalog.find(life_catalog_id).life_items
    if !life_items.empty?
      life_records = life_items.sort { |y,x| x.updated_at <=> y.updated_at }[0].life_records.sort { |y,x| x.id <=> y.id }
      result += life_records[0].memo.slice(0..36) if !life_records.empty?
    end
    result
  end

  def ini_life_record_from_id
  	if params[:id]
		life_record_ref = LifeRecord.find(params[:id])
		@life_record = LifeRecord.new
		@life_record.life_item_id = life_record_ref.life_item_id
		@life_record.rec_date = Date.today.to_s(:db)
		@life_record.used_minutes = life_record_ref.used_minutes
		@life_record.memo = life_record_ref.memo   
		@life_record.is_not_goal = false
	end
  end
       
end
