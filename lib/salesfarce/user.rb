module Salesfarce
  class User
    include DataMapper::Resource

    property :id,             Serial  # auto-increment integer PK
    property :username,       String, :required => true, :unique => true
    property :first_name,     String
    property :last_name,      String, :required => true
    property :company,        String
    property :title,          String
    property :phone,          String
    property :mobile_phone,   String
    property :bio,            Text
    property :large_photo,    FilePath
    property :small_photo,    FilePath
    property :salesforce_id,  String
    property :created_at,     DateTime

    def name
      first_name + ' ' + last_name
    end
  end
end

