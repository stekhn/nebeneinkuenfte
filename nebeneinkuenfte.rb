=begin

Scraper to collect information about the outside earnings of
German Members of Parliament (18. Deutscher Bundestag).

All data is retrieved from the parliament's offical website
http://bundestag.de/bundestag/abgeordnete18/ using the scraping
library Nokogiri.

This scraper is open domain: http://unlicense.org/

=end


# Import the necessary libraries
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'

# Get the URL for all the A-Z pages
alphabeticalList = []
# Exclude the Q and X pages, because they don't exist
(('A'..'Z').to_a-['Q','X']).each do |b|
	alphabeticalList << "http://www.bundestag.de/bundestag/abgeordnete18/biografien/#{b}/"
end

# Get the individual profile URLs of all members of the parliament (MPs).
profileUrls = []
alphabeticalList.each do |url|
	# Uses the Nokogiri scraping library
	currentDoc = Nokogiri::HTML(open(url))
	linkList = currentDoc.css('ul.linkList')
	linkList.css('li a').each do |l|
		profileUrls << url+l['href']
	end
	sleep 1
	# Log the number of found profiles
	puts "Getting URLs from ..."+url[-3,2]+" ...found #{profileUrls.length}"
end

# Get all outside income declaration from all MPs
allMembers = []
profileUrls.each do |url|
	# Uses the Nokogiri scraping library
	currentDoc = Nokogiri::HTML(open(url).read)
	# UTF-8 preserves German umlaut
	currentDoc.encoding = 'UTF-8'

	# Split the title tag up and retrieve name and party
	nameAndParty = currentDoc.css('div.biografie h1').inner_html
	name, party = nameAndParty.split(',').map {|w| w.strip}
	
	# Establish the data model. There are ten annual and/or monthly income steps
	# For further information refer to http://bundestag.de/bundestag/abgeordnete18/nebentaetigkeit/Hinweise_zur_Veroeffentlichung.pdf  
	member = {
    	:name => name,
    	:party => party,
    	:s1m => 0,
    	:s2m => 0,
    	:s3m => 0,
    	:s4m => 0,
    	:s5m => 0,
    	:s6m => 0,
    	:s7m => 0,
    	:s8m => 0,
    	:s9m => 0,
    	:s10m => 0,
		:s1j => 0,
    	:s2j => 0,
    	:s3j => 0,
    	:s4j => 0,
    	:s5j => 0,
    	:s6j => 0,
    	:s7j => 0,
    	:s8j => 0,
    	:s9j => 0,
    	:s10j => 0
  	}

  	# Checks if a declaration of outside income matches a certain pattern
	currentDeclaration = currentDoc.css('p.voa_tab1')
	currentDeclaration.each do |a|
		str = a.inner_html

		#Checks if the declaration contains "step x" and "monthly"
		for i in 1..10
			if str =~ /Stufe #{i}/ && str =~ /monatlich/
				member[:"s#{i}m"] += 1
			end
		end

		#Checks if the declaration contains "step x" and "annual" or "year"
 		for j in 1..10
			if str =~ /Stufe #{j}/ && (str =~ /jährlich/ || str =~ /2009/ || str =~ /2010/ || str =~ /2011/ || str =~ /2012/ || str =~ /2013/ || str =~ /2014/)
				member[:"s#{j}j"] += 1
			end
		end
	end

	# Log current member to the console.
  	puts "Name: #{member[:name].ljust(30)} Party: #{member[:party].ljust(10)}"
  	
  	# Exclude fictional "Jakob Maria Mierscheid"
  	# Write MP to array
  	unless name == "Jakob Maria Mierscheid"
  		allMembers << member
  	end
end

# Write the array of MPs to JSON 
File.open("outsideIncome.json","w") do |f|
  f.write(allMembers.to_json)
end
