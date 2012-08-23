class User
  include DataMapper::Resource

  property :id,             Serial  # auto-increment integer PK
  property :username,       String, :required => true
  property :first_name,     String
  property :last_name,      String, :required => true
  property :company,        String
  property :title,          String
  property :phone,          String
  property :mobile_phone,   String
  property :bio,            Text
  property :large_photo,    FilePath
  property :small_photo,    FilePath
  property :created_at,     DateTime, :writer => :protected
end

