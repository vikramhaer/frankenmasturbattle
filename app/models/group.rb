class Group < ActiveRecord::Base
  has_many :memberships,:dependent => :destroy
  has_many :users, :through => :memberships

  def name_and_size
    self.name + ' (' + self.users.size.to_s + ')'
  end
end
