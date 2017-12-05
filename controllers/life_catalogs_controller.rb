class LifeCatalogsController < ApplicationController
  # GET /life_catalogs
  # GET /life_catalogs.xml
  def index
    @life_catalogs = LifeCatalog.all( :order => "line_order_num" )
    order_index_field @life_catalogs

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @life_catalogs }
    end
  end

  # GET /life_catalogs/1
  # GET /life_catalogs/1.xml
  def show
    @life_catalog = LifeCatalog.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @life_catalog }
    end
  end

  # GET /life_catalogs/new
  # GET /life_catalogs/new.xml
  def new
    @life_catalog = LifeCatalog.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @life_catalog }
    end
  end

  # GET /life_catalogs/1/edit
  def edit
    @life_catalog = LifeCatalog.find(params[:id])
  end

  # POST /life_catalogs
  # POST /life_catalogs.xml
  def create
    @life_catalog = LifeCatalog.new(params[:life_catalog])

    respond_to do |format|
      if @life_catalog.save
        flash[:notice] = 'LifeCatalog was successfully created.'
        format.html { redirect_to(life_catalogs_url) }
        format.xml  { render :xml => @life_catalog, :status => :created, :location => @life_catalog }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @life_catalog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /life_catalogs/1
  # PUT /life_catalogs/1.xml
  def update
    @life_catalog = LifeCatalog.find(params[:id])

    respond_to do |format|
      if @life_catalog.update_attributes(params[:life_catalog])
      	update_all_goal_minutes
        flash[:notice] = 'LifeCatalog was successfully updated.'
        format.html { redirect_to(life_catalogs_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @life_catalog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /life_catalogs/1
  # DELETE /life_catalogs/1.xml
  def destroy
    @life_catalog = LifeCatalog.find(params[:id])
    @life_catalog.destroy

    respond_to do |format|
      format.html { redirect_to(life_catalogs_url) }
      format.xml  { head :ok }
    end
  end
  
  def order_up
    exe_order_up LifeCatalog, params[:id]
    redirect_to :action => 'index'
  end
  
  def order_down
    exe_order_down LifeCatalog, params[:id]
    redirect_to :action => 'index'
  end

  def line_order_up
    exe_order_up LifeCatalog, params[:id], "line_order_num"
    redirect_to :action => 'index'
  end
  
  def line_order_down
    exe_order_down LifeCatalog, params[:id], "line_order_num"
    redirect_to :action => 'index'
  end

  def update_weight
    if params[:weight] == 'reset'
        LifeCatalog.update_all( "weight = 1.0" )
        @msg = "已重設所有權重為1"
    else
        LifeCatalog.find(params[:id]).update_attribute(:weight,params[:weight])
        @msg = "已於#{Time.now.to_s(:db)}將權重更新為#{params[:weight]}"
    end
    if request.xhr? 
        respond_to { |format| format.js } 
    else 
        redirect_to :action => :index
    end   
  end    
  
  def clean_items
    LifeItem.all( :conditions => ["life_catalog_id = ?", params[:id]] ).each { |life_item| life_item.destroy }
    flash[:notice] = "所屬項目已經清空! (#{Time.now.to_s(:db)})"
    redirect_to :action => :index
  end  
  
  def update_table_field_value
    exe_update_table_field_value( LifeCatalog )
    update_all_goal_minutes

    if request.xhr? 
        respond_to { |format| format.js } 
    else 
        redirect_to :action => :index
    end      
  end
  
  private
  
  def update_all_goal_minutes
  	source_input = params[:life_catalog] ? params[:life_catalog][:goal_minutes] : params[:field_value]
	if source_input.slice(0,1) == "a"
		LifeCatalog.update_all( "goal_minutes = #{source_input.split("a")[1]}", "goalable  =    't'" )
		@msg = "已將所有目標更新為#{source_input.split("a")[1]}分鐘 (#{Time.now.to_s(:db)})"
	end
  end
      
end
