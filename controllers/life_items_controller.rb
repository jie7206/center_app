class LifeItemsController < ApplicationController
  # GET /life_items
  # GET /life_items.xml
  def index
  	order_str = "life_items.order_num"
  	#order_str = use_life_catalog_goal_minutes? ? "life_catalogs.line_order_num" : "life_items.is_goal desc,life_items.order_num"
    #today_db_str = Date.today.to_s(:db)
  	#@life_items = LifeItem.all( :conditions  => [ "begin_date <= ? and end_date >= ?", today_db_str, today_db_str ], :include => [ :life_catalog, :life_records ], :order => order_str )
  	@life_items = LifeItem.all( :include => [ :life_catalog, :life_records ], :order => order_str )
    order_index_field @life_items
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @life_items }
    end
  end

  # GET /life_items/1
  # GET /life_items/1.xml
  def show
    @life_item = LifeItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @life_item }
    end
  end

  # GET /life_items/new
  # GET /life_items/new.xml
  def new
    @life_item = LifeItem.new( :total_minutes => 0 )

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @life_item }
    end
  end

  # GET /life_items/1/edit
  def edit
    @life_item = LifeItem.find(params[:id])
  end

  # POST /life_items
  # POST /life_items.xml
  def create
    @life_item = LifeItem.new(params[:life_item])

    respond_to do |format|
      if @life_item.save
        flash[:notice] = 'LifeItem was successfully created.'
        format.html { redirect_to(life_items_url) }
        format.xml  { render :xml => @life_item, :status => :created, :location => @life_item }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @life_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /life_items/1
  # PUT /life_items/1.xml
  def update
    @life_item = LifeItem.find(params[:id])
    ori_life_catalog_id = @life_item.life_catalog_id

    respond_to do |format|
      if @life_item.update_attributes(params[:life_item])
      	exe_update_life_catalog_total_minutes [ ori_life_catalog_id ]
        flash[:notice] = 'LifeItem was successfully updated.'
        format.html { redirect_to(life_items_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @life_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /life_items/1
  # DELETE /life_items/1.xml
  def destroy
    @life_item = LifeItem.find(params[:id])
    @life_item.destroy

    respond_to do |format|
      format.html { redirect_to(life_items_url) }
      format.xml  { head :ok }
    end
  end

  def xml_list
    color_arr = ['','0xFF0F00','0xFF6600','0xFF9E01','0xFCD202','0xF8FF01','0xB0DE09','0x04D215','0x0D8ECF','0x0D52D1','0x2A0CD0','0x8A0CCF','0xCD0D74','0x754DEB','0xDDDDDD','0x999999','0x333333','0x000000','0x57032A','0xCA9726','0x990000','0x4B0C25']
    respond_to do |format|
        format.html do
          redirect_to :action => :index
        end
        format.xml  do 
          xml_result = ""
          LifeItem.all( :include => [ :life_catalog, :life_records ], :conditions => ["life_catalogs.chartable = ? AND life_records.rec_date >= ? AND life_items.is_not_chart != ?", true, life_rec_start_date, true ], :order => "life_items.total_minutes desc", :limit  =>  15  ).each do |life_item|
            last_life_record = life_item.life_records.sort { |y,x| x.rec_date <=> y.rec_date }[0]
            xml_result += "<record>\n"
            xml_result += "<name>#{life_item.name}</name>\n"
            xml_result += "<total_minutes>#{life_item.total_minutes}</total_minutes>\n"
            xml_result += "<color>#{color_arr[life_item.life_catalog.order_num]}</color>\n"            
            xml_result += "<note>#{life_item.name} 共#{life_item.total_minutes}分#{life_item.life_records.size}次\n#{diff_days_note(last_life_record.rec_date)}：#{last_life_record.memo.slice(0..20)}</note>\n"
            xml_result += "</record>\n"
          end
          xml_result = '<?xml version="1.0" encoding="utf-8"?><data>' + xml_result + '</data>'
        	render :text => xml_result
     	end
    end  	    
  end

  def diff_days_note( rec_date )
    count = day_diff( rec_date, Date.today.to_s(:db) )
    case count
      when 0 : return "今天"
      when 1 : return "昨天"
      when 2 : return "前天"
      else
        return "#{count}天前"
    end    
  end
  
  def update_all_is_not_chart
    LifeItem.update_all( "is_not_chart = 0" )
    render :text => "update_all_is_not_chart ok!"
  end

  def update_table_field_value
    exe_update_table_field_value( LifeItem )
    if request.xhr? 
        respond_to { |format| format.js } 
    else 
        redirect_to :action => :index
    end      
  end
  
  def cancel_all_is_goal
  	LifeItem.update_all( "is_goal = 'f'" )
  	flash[:notice] = "已取消所有目標"
  	redirect_to :action => :index
  end

  def order_up
    exe_order_up LifeItem, params[:id]
    redirect_to :action => 'index'
  end
  
  def order_down
    exe_order_down LifeItem, params[:id]
    redirect_to :action => 'index'
  end
  
  private
    
end
