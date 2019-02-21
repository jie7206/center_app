class BooksController < ApplicationController
  
  def index
    @books = Book.all
  end

  def new
    @book = Book.new
    @book.is_default = true
    @book.bg_filename = 'ucbg_w.jpg'

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @book }
    end    
  end

  def edit
    @book = Book.find(params[:id])
  end

  def create
    @book = Book.new(params[:book])

    if @book.save
      flash[:notice] = '书籍资料已成功设定！'
      redirect_to :controller => 'main', :action => 'show_golden_verse', :rand_collect => true
    else
      render :action => "new"
    end    
  end

  def update
    @book = Book.find(params[:id])
    if @book.update_attributes(params[:book])
      flash[:notice] = '书籍资料已成功更新！.'
      redirect_to :action => 'index'
    else
      render :action => "edit"
    end
  end

  def destroy
    @book = Book.find(params[:id])
    if @book.destroy
      flash[:notice] = "#{@book.name}的书籍资料已成功删除！"
      redirect_to :action => 'index'
    end
  end

  # 设置为预设书籍并转到金句阅读页面
  def set_default_then_read
    Book.find(params[:id]).update_attribute(:is_default,true)
    redirect_to :controller => 'main', :action => 'show_golden_verse', :rand_collect => true
  end

end
