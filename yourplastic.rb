#/usr/bin/ruby
 
require 'mongo'
require 'sinatra'
require 'json'
require 'uuidtools'
 
 
 
configure do
	db = Mongo::Client.new(['127.0.0.1:27017'], :database => 'profiles')
	set :mongo_db, db[:profiles]
end
 
 
get '/collections/?' do
	content_type :json
	settings.mongo_db.database.collection_names.to_json
end
 
def set_uuid()
	uuid = UUIDTools::UUID.random_create
	return uuid.to_s
end
 
helpers do	
	def profile_query id 
		if params.nil?
			{}.to_json
		else
			document = settings.mongo_db.find(:_id => id).to_a.first
			(document || {}).to_json
		end
	end
 
	def search_query params
		results = Array.new
		if params.nil?
			{}.to_json
		else
			puts params 
			puts "\n\n"
			params.keys.each do |k|
				document = settings.mongo_db.find({ "#{k}" => /#{params[k]}/}).to_a
				puts document
				results.push(document)
			end
			results.to_json	
		end
	end
end
 
get '/profiles/?' do
        content_type :json
        settings.mongo_db.find.to_a.to_json
end
 
get '/profiles/:_id/?' do
	profile_query(params[:_id])
end
 
get '/search/?' do
	content_type :json
	search_query(params)
end
 
post '/new_profile/?' do
	#uuid = set_uuid()
	content_type :json
	db = settings.mongo_db
	params[:_id] = set_uuid()
	result = db.insert_one(params) 
	db.find(:_id => params[:_id]).to_a.first.to_json
end
 
put '/update/:_id/?' do
	content_type :json
	id = params[:_id]
	#params.delete("splat")
	puts request.params
	puts "\n\n"
	request.params.keys.each do |k|
		settings.mongo_db.find(:_id => id).update_one("$set" => { "#{k}" => "#{request.params[k]}"})
	end
	profile_query(id)
end
 
delete '/remove/:_id/?' do
	content_type :json
	db = settings.mongo_db
	id = params[:_id]
	documents = db.find(:_id => id)
	if !documents.to_a.first.nil?
		documents.find_one_and_delete
		{:success => true}.to_json
	else
		{:success => false}.to_json
	end
end
