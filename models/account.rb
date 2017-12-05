class Account < ActiveRecord::Base
  belongs_to :member

  def self.range_rand(min,max)
    min + rand(max-min)
  end  	
  
  def self.check_account_exist( email, username )
  	if acc = find_by_username( username )	
  		acc.member.email == email ? acc.id : false
	else
		false
  	end
  end
  
  def self.create_hash_key( username )
  	if acc = find_by_username( username )	
  		hash_key_arr = []
  		10.times { hash_key_arr << self.range_rand( 10, 99 ).to_s }
  		hash_key = hash_key_arr.join
  		acc.update_attribute( :hash_key, hash_key )
  		return hash_key
  	else	
  		""
  	end
  end
  
  def self.check_hash_key( acc_id, hash_key )
    if acc = find_by_id_and_hash_key( acc_id, hash_key )
      return acc
    else
      false
    end
  end

  def self.renew_password( acc_id, new_password )
    if acc = find_by_id( acc_id )
      acc.update_attributes( :password => new_password, :hash_key => "" )
      true
    else
      false
    end    
  end
  
end
