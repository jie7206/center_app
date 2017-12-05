class SimCharactersController < ApplicationController
  
  def index
    @sim_characters = SimCharacter.all( :order => "sex desc" )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sim_characters }
    end
  end

  def new
    @sim_character = SimCharacter.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @sim_character }
    end
  end

  def create
    @sim_character = SimCharacter.new(params[:sim_character])

    respond_to do |format|
      if @sim_character.save
        flash[:notice] = '模擬人物已新增成功！'
        format.html { redirect_to(sim_characters_url) }
        format.xml  { render :xml => @sim_character, :status => :created, :location => @sim_character }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sim_character.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit  
    @sim_character = SimCharacter.find( params[:id] )
  end

  def update
    @sim_character = SimCharacter.find(params[:id])

    respond_to do |format|
      if @sim_character.update_attributes(params[:sim_character])
        flash[:notice] = '模擬人物資料已更新！'
        format.html { redirect_to(sim_characters_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sim_character.errors, :status => :unprocessable_entity }
      end
    end    
  end

  def destroy
    @sim_character = SimCharacter.find(params[:id])
    @sim_character.destroy

    respond_to do |format|
      format.html { redirect_to(sim_characters_url) }
      format.xml  { head :ok }
    end
  end

end
