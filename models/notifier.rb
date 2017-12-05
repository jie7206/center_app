class Notifier < ActionMailer::Base

  AdminEMailAddress = 'jie7206@linshijie.com'
  DefaultHost = 'center.linshijie.com'  

  def renew_password_confirm( email, username, acc_id, hash_key )
    subject    '您在'+DefaultHost+'申請新的密碼'
    recipients AdminEMailAddress + ',' + email
    from       "admin@linshijie.com"    
    body      :email => email, :username => username, :acc_id => acc_id, :hash_key => hash_key
  end

end
