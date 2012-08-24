module Salesfarce
  class User
    include DataMapper::Resource

    property :id,             Serial  # auto-increment integer PK
    property :username,       String, :required => true, :unique => true, :length => 0..255
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

    def first_name
      super || ''
    end

    def last_name
      super || ''
    end
  end
end

