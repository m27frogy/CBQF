#!/usr/bin/env ruby
# encoding: utf-8
#######################################################################
# CollegeBoard QotD Fetcher
#
# CollegeBoard, SAT, and PSAT/NMSQT are registered trademarks of
# The College Board and National Merit Corporation and do not
# endorse this software.
#
#
#
# = Modifications to Core Object Class
#######################################################################

class Object
	# Allows code to easily ask for certain instance variables
	def must_have_instance_variables(*args)
		vars = instance_variables.inject({}) { |h,mvar| h[var] = true; h}
		args.each do |var|
			unless vars[var]
				raise ArgumentError, %{Instance variable @#{var} not defined}
			end
		end
	end
	
	# Simplifies checks for compatible objects
	def must_support(*args)
		args.each do |method|
			unless respond_to? method
				raise ArgumentError, %{Must support "#{method}"}
			end
		end
	end
end

# Thanks, miister Ivan Black.
class String
	def black;          "\e[30m#{self}\e[0m" end
	def red;            "\e[31m#{self}\e[0m" end
	def green;          "\e[32m#{self}\e[0m" end
	def brown;          "\e[33m#{self}\e[0m" end
	def blue;           "\e[34m#{self}\e[0m" end
	def magenta;        "\e[35m#{self}\e[0m" end
	def cyan;           "\e[36m#{self}\e[0m" end
	def gray;           "\e[37m#{self}\e[0m" end

	def bg_black;       "\e[40m#{self}\e[0m" end
	def bg_red;         "\e[41m#{self}\e[0m" end
	def bg_green;       "\e[42m#{self}\e[0m" end
	def bg_brown;       "\e[43m#{self}\e[0m" end
	def bg_blue;        "\e[44m#{self}\e[0m" end
	def bg_magenta;     "\e[45m#{self}\e[0m" end
	def bg_cyan;        "\e[46m#{self}\e[0m" end
	def bg_gray;        "\e[47m#{self}\e[0m" end

	def bold;           "\e[1m#{self}\e[21m" end
	def italic;         "\e[3m#{self}\e[23m" end
	def underline;      "\e[4m#{self}\e[24m" end
	def blink;			"\e[5m#{self}\e[25m" end
	def reverse_color;	"\e[7m#{self}\e[27m" end
	def no_colors;	self.gsub /\e\[\d+m/, ""; end
end

# Required software
require "selenium-webdriver"
require "nokogiri"
require "pdfkit"
# Required internal libraries
require "date"
require "tmpdir"
require "open-uri"
require "fileutils"
require "pathname"
require "net/http"
require "openssl"

# Constants
STARTING_XHTML = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n\t\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">\n\t<head>\n\t\t<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"/>\n\t\t<title>title</title>\n\t</head>\n\t<body>" \
	.encode("utf-8").freeze
ENDING_XHTML = "\n\t</body>\n</html>".encode("utf-8").freeze
IMG_DIR = File.expand_path "#{Dir.tmpdir}/CBQF/".freeze
IMAGE_REGEX = /img.*?src="(.*?)"/i.freeze
WRAP_MATCH = "\\1\n".freeze
IMG_REGEX, IMG_MATCH = /<img(.+?)>/.freeze,"<img\\1 />".freeze
INPUT_REGEX, INPUT_MATCH = /<input(.+?)>/.freeze, "<input\\1 />".freeze
CHECKED_REGEX, CHECKED_MATCH = / checked /.freeze," checked=\"checked\" ".freeze
WEBSITE_URI = "https://sat.collegeboard.org".freeze
BASE_PAGE_URI = "#{WEBSITE_URI}/practice/sat-question-of-the-day?questionId=".freeze


# Creates the dir, if necessary
FileUtils.mkdir_p IMG_DIR

#  Word-wraps strings
def wrap(s,width=78)
	s.gsub(/(.{1,#{width}})(\s+|\Z)/, WRAP_MATCH).strip
end

# Fix img tags in XHTML
def fix_tags(s)
	s.gsub(IMG_REGEX, IMG_MATCH).gsub(INPUT_REGEX, INPUT_MATCH).gsub(CHECKED_REGEX, CHECKED_MATCH)
end

# Fetch IMG file and download it into a temp file
def create_img_file(path)
	# Parse out the path properly
	file_name = File.basename path
	end_path = IMG_DIR + "/" + file_name
	
	#File.open(end_path, "wb") do |file|
	#	file.write( open( (WEBSITE_URI + path).encode("ISO-8859-1") ).read )
	#end

	uri = URI.parse(WEBSITE_URI)
	http = Net::HTTP.new(uri.host,uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	resp = http.get(path)
	open(end_path,"wb") { |file|
		file.write(resp.body)
	}
	
	# Again, Lua habits. :P
	return end_path
end

# Parse out URIs and handle them nicely
def parse_img_uri(html_doc)
	finished = html_doc.clone
	parsed = []
	html_doc.scan(IMAGE_REGEX).each do |match|
		raise("Match should be a length of 1") if match.length != 1
		if not parsed.include? match[0] then
			file = create_img_file(match[0])
			parsed << file
			finished.gsub!(match[0],file)
		end
	end
	
	# This is Ruby style for ya. ;)
	html_doc = finished.encode("utf-8")
end

# Uses Nokogiri to parse the provided page and divide it into questions and answers
def handle_page(source)
	# Initialize parsing object
	page = Nokogiri::HTML(source)
	# Enables me to get over the relative slowness of recreating strings
	match = "id"
	
	
	# Handle statistics
	correct,wrong = "",""
	total,percentage = 0,0
	begin
		stat_table = page.css("table#qotdPercentCorrectTable")
		stat_table.children.each do |c|
			if c.name == "tbody" then
				c.children.each do |ch|
					if ch.name == "tr" then
						entry = ""
						ch.children.each do |chd|
							if chd.name == "td" then
								case entry
								when "Correct"
									correct = td.text.trim.gsub(",","")
								when "Incorrect"
									wrong = td.text.trim.gsub(",","")
								end
								break
							elsif chd.name == "th" then
								if chd.include? "Correct" then
									entry = "Correct"
								elsif chd.include? "Incorrect" then
									entry = "Incorrect"
								end
							end
						end
						break if not (correct.empty? or wrong.empty?)
					end
				end
				break if not (correct.empty? or wrong.empty?)
			end
			break if not (correct.empty? or wrong.empty?)
		end
		correct = correct.to_i
		wrong = wrong.to_i
	rescue
	end
	if correct == 0 or wrong == 0 then
		correct = ""
		wrong = ""
	end
	if (correct == "" and wrong == "") then
		total_num = page.css("div#questionMetaTotalNum")
		total_num.children.each do |c|
			if c.name == "strong" then
				total = c.text.strip.gsub(",", "").to_i
				break
			end
		end
		if total.kind_of? Integer then
			meta_stats = page.css("div.qotdMetaStats")
			meta_stats.children.each do |c|
				if c.name == "div" and c.text.match "%" then
					percentage = c.text.to_i * 0.01
					if percentage != 0 then
						correct = (total * percentage).floor
						wrong = (total * (1 - percentage)).floor
						break
					end
				end
			end
		else
			raise "Unable to fetch statistics (call 1)"
		end
	elsif (correct.kind_of? Integer and wrong.kind_of? Integer) then
		raise "Strange typing of correct/wrong"
	end
	if (correct == "" and wrong == "") then
		raise "Unable to fetch statistics (call 2)"
	end
	total = correct + wrong if total == 0
	
	
	
	# Handle topic
	topic = ""
	topics = page.css("p.qotdBreadcrumb")
	topics.each do |element|
		topic << element.text.strip.encode("utf-8")
		break
	end
	
	# Handle question
	question = ""
	main_body = page.css("div#mainBody")
	main_body.each do |element|
		element.css("div#qotd").children.each do |ele|
			ele.remove if ele[match] == "questionMetaContainer" or ele[match] == "qotdQuestionFooter"
		end
		question << element.inner_html.encode("utf-8")
		break
	end
	
	# Handle answer
	answer = ""
	main_body2 = page.css("div#mainBody2")
	main_body2.each do |element|
		element.css("div#qotd2").children.each do |ele|
			ele.remove if ele[match] == "questionMetaContainer2"
		end
		answer << element.inner_html.encode("utf-8")
		break
	end
	
	return [topic,question,answer,total,correct,wrong]
end

# Create XHMTL 1 Strict pages from fetched pages
def create_xhtml(pages)
	xhtml_doc_q = "".encode("utf-8")
	xhtml_doc_a = "".encode("utf-8")
	
	xhtml_doc_q += STARTING_XHTML
	xhtml_doc_a += STARTING_XHTML
	count = 1
	pages.each do |page_data|
		# Declare basic values
		section = "".encode("utf-8")
		topic,question,answer,total,correct,wrong = *page_data
		
		################################################
		# Add title
		section += "<h2>Question ##{count}</h2>\n<h4>#{topic}</h4>\n<p><br /></p>".encode("utf-8")
		# Add question
		section += fix_tags(question.encode("utf-8"))
		# Add line
		section += "\n<p><br /></p>\n<hr />\n"
		
		# Push to question document
		xhtml_doc_q += section
		################################################
		# Re-declare section
		section = "".encode("utf-8")
		
		# Add title
		section += "<h2>Question ##{count}</h2>\n<h4>#{topic}</h4>\n<p><br /></p>".encode("utf-8")
		# Add statistics
		section += "<p>Out of #{total} people, #{correct} (#{(correct/total*100).to_i}%) guessed this question correctly.</p>\n<p><br /></p>"
		# Add answer
		section += fix_tags(answer.encode("utf-8"))
		# Add line
		section += "\n<p><br /></p>\n<hr />\n"
		
		# Push to answer document
		xhtml_doc_a += parse_img_uri(section)
		################################################
		
		# Iterate count
		puts "Parsed ##{count}"
		count += 1
	end
	xhtml_doc_q += ENDING_XHTML
	xhtml_doc_a += ENDING_XHTML
	
	return xhtml_doc_q,xhtml_doc_a
end

# Fetch singlular page contents
def fetch_page(driver,page)
	# Make positive that the page is actually a string
	unless page.kind_of? String
		raise ArgumentError, "Page must be a string"
	end
	
	# Go to page
	driver.navigate.to(page)
	
=begin
		# Find and click on qotdChoicesA
		qotdChoicesA = driver.find_element(:id, "qotdChoicesA")
		qotdChoicesA.click
		
		# Find and click on submit button
		qotdSubmit = driver.find_element(:id, "qotdSubmit")
		qotdSubmit.click
=end
	
=begin
	begin
		#Find and click on the qotdShowAnswer button
		qotdShowAnswer = driver.find_element(:id,"qotdShowAnswer")
		qotdShowAnswer.click
	rescue
	end
=end
	
	begin
		printQuestionId = driver.find_element(:id,"printQuestionIdExists")
		printQuestionId.click
	rescue
		printQuestionId = driver.find_element(:id,"printQuestionIdDoesntExist")
		printQuestionId.click
	end
	
	# Out of habit and charity, I leave the mostly useless return call here.
	return driver.page_source
end

# Fetch each page individually and return contents
def fetch_pages(pages)
	# Check that pages are a compatible object
	pages.must_support :each
	
	# Initialize returned array
	npages = []
	
	# Initialize Selenium::WebDriver::Driver object
	driver = Selenium::WebDriver.for :firefox
	
	# Iterate through pages
	pages.each { |page|
		npages << handle_page(fetch_page(driver,page))
	}
	
	# Cleanup
	driver.close
	driver.quit
	
	# Out of habit and charity, I leave the mostly useless return call here.
	return npages
end

# Creates a table filled with dates between today and a date
def generate_pages(date,final=Date.today)
	# Parse dates
	date = Date.parse(date)
	days = [date]
	# Verify data integrity
	unless final - date >= 1
		raise ArgumentError, %{Date "#{date}" incorrect}
	end
	# Loop through dates
	while not (days.last.year >= final.year and days.last.month >= final.month and days.last.day >= final.day)
		days << days.last.succ
	end
	
	# Append URL
	days.each_with_index do |data,index|
		days[index] = %{#{BASE_PAGE_URI}#{DateTime.parse(data.to_s).strftime("%Y%m%d")}}
	end
	
	return days
end

# Opens a file and loads it with Marshal
def fetch_database()
	obj = nil
	open("data.db","r") do |file|
		obj = Marshal.load(file.read)
	end
	return obj
end

# Write to file with Marshal
def generate_database(obj)
	open("data.db","w+") do |file|
		file.write(Marshal.dump(obj))
	end
end

# Export pdf
def export_pdf(xhtml_q, qpath, xhtml_a, apath)
	# Export question pdf
	puts "Preping questions..."
	kit = PDFKit.new(xhtml_q, :page_size => "Letter",
		:disable_smart_shrinking => true, :no_pdf_compression => true)
	puts kit.options
	puts "Writing questions..."
	kit.to_pdf qpath
	
	puts "Preping answers..."
	kit = PDFKit.new(xhtml_a, :page_size => "Letter",
		:disable_smart_shrinking => true, :no_pdf_compression => true)
	puts "Writing answers..."
	kit.to_pdf apath
	
	return nil
end

puts "#########################################".green
puts "#       CollegeBoard QotD Fetcher       #".green
puts "#########################################".green
persist = false
if File.file? "data.db"
	print "Load previous database (T/F): "
	persist = gets.chomp
	if persist.downcase[0,1] == "t"
		persist = true
		puts "Loading database..."
	else
		persist = false
	end
end
if not persist
	print "Start time: "
	start = gets.chomp
	print "End time (leave blank for today): "
	stop = gets.chomp
	if stop.empty?
		stop = Date.today
		puts "Setting to today..."
	else
		stop = Date.parse(stop)
	end
end
print "Output prefix: "
prefix = gets.chomp
print "Sort by section (T/F): "
sortt = gets.chomp
if sortt.downcase[0,1] == "t"
	sortt = true
	puts "Sorting..."
else
	sortt = false
end
print "Shuffle questions (T/F): "
shuffle = gets.chomp
if shuffle.downcase[0,1] == "t"
	shuffle = true
	puts "Shuffling..."
else
	shuffle = false
end
print "Filter by topic (leave blank for false): "
filter = gets.chomp
if filter.empty?
	filter = false
end
print "Restrict problems to n (leave blank for false): "
restrict = gets.chomp
restrict = restrict.to_i

# Fetches questions from database or the Internet
if not persist
	puts "Fetching..."
	questions = fetch_pages(generate_pages(start,stop))
			
	if File.file? "data.db"
		print "Overwrite pre-existing database (T/F): "
		overwrite = gets.chomp
		if overwrite.downcase[0,1] == "t"
			puts "Writing database..."
			generate_database(questions)
		else
			puts "Skipping overwrite..."
		end
	else	
		puts "Writing database..."
		generate_database(questions)
	end
else
	questions = fetch_database()
end

# Eliminate deviant topics
if filter
	questions = questions.select { |data| data[0].match(filter) }
end

# Shuffle questions
if shuffle
	questions.shuffle!
end

# Grab only a selection
if restrict != 0
	if restrict <= questions.length
		questions = questions.slice(0,restrict)
	else
		puts "Too few questions to restrict!"
	end
end

# Sort questions by type
if sortt
	questions = questions.sort_by {|k| k[0]}
end

puts "Exporting..."
# Export as PDF
puts "Parsing HTML"
xhtml_q,xhtml_a = create_xhtml(questions)
export_pdf(xhtml_q, prefix + ".pdf", xhtml_a, prefix + "-answers.pdf")
		
puts "Export complete!"
puts %{Exported #{questions.length} questions!}
