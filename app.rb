require 'sinatra'
require 'sinatra/multi_route'
require 'open-uri'
require 'json'
require 'library_stdnums'

#Settings for development. Comment out on deploy
set :port, 3000
set :bind, '0.0.0.0'

route :get, :post, '/' do
	content_type :json
	if params[:isbn]
		isbns  = ''
		params[:isbn].split(',').each do |i|
			isbn = StdNum::ISBN.normalize(i) rescue nil
			if isbn
				isbns = isbns + ',' + isbn
			end
		end
		request_url = 'https://www.goodreads.com/book/review_counts.json?isbns=' + params[:isbn]
		reviews =  JSON.parse(open(request_url).read) rescue nil
		if reviews
			raw = reviews["books"][0]["average_rating"]
			rounded = (raw.to_f * 2).round / 2.0
			stars = rating_to_stars(rounded)
			gr_id = reviews["books"][0]["id"]
			gr_link = 'https://www.goodreads.com/book/show/' + gr_id.to_s
			message = {:gr_id => gr_id, :raw => raw, :rounded => rounded, :stars_html => stars, :gr_link => gr_link}
		else
			message = {:message => "no reviews found"}
		end
	else
	   message = {:message => "error"}
	end
	return message.to_json
end

def rating_to_stars(rounded)
	base = '&#9733;' * rounded.to_i
	remainder = rounded.to_i - rounded
	if remainder != 0
		stars = base + '&frac12;'
	else
		stars = base
	end
	return stars
end