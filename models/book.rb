class Book < ActiveRecord::Base

	validates_presence_of :name, :title, :filename, :bg_filename, :message => '书名、标题、文档名和背景图档不能空白!'

	after_save :set_uniq_default_book # 预设的书籍只能有一本
	before_destroy :dont_destroy_auto_insert

  def set_uniq_default_book
    if self.is_default
      Book.update_all(["is_default = ?",false],["id != ?",self.id])
    end
  end

end
