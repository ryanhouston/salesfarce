module Salesfarce
  class SObjectImporter

    # Returns a Salesfarce::User created from given the Databasedotcom::Sobject
    # User representation
    def self.import(sobject_user)
      user = Salesfarce::User.new(
        :username => sobject_user.Username,
        :first_name => sobject_user.FirstName,
        :last_name => sobject_user.LastName,
        :company => sobject_user.CompanyName,
        :title => sobject_user.Title,
        :phone => sobject_user.Phone,
        :mobile_phone => sobject_user.MobilePhone,
        :bio => sobject_user.AboutMe,
        :large_photo => sobject_user.FullPhotoUrl,
        :small_photo => sobject_user.SmallPhotoUrl,
        :created_at => Time.now,
        :salesforce_id => sobject_user.Id
      )
    end
  end
end

