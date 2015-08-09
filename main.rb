# encoding: utf-8

# CollegeBoard QotD Fetcher
#
# CollegeBoard, SAT, and PSAT/NMSQT are registered trademarks of
# The College Board and National Merit Corporation and do not
# endorse this software.
#
#
#
# = Modifications to Core Object Class

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

# Required software
require "selenium-webdriver"
require "nokogiri"
require "date"
require "tmpdir"
require "open-uri"
require "pdfkit"

def tmpdir
  path = File.expand_path "#{Dir.tmpdir}/#{Time.now.to_i}#{rand(1000)}/"
  FileUtils.mkdir_p path
  yield path
ensure
  FileUtils.rm_rf( path ) if File.exists?( path )
end

def create_file()
end

#  Word-wraps strings
def wrap(s,width=78)
	s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n").strip
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
			c.children.each do |c|
				if c.name == "tbody" then
					c.children.each do |ch|
						if ch.name == "tr" then
							ch.children.each do |chd|
								if chd.name == "td" then
									if correct.empty?
										correct = chd.text
									else
										wrong = chd.text
									end
									break
								end
							end
							break if not (correct.empty? or wrong.empty?)
						end
					end
					break if not (correct.empty? or wrong.empty?)
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
	puts "|",total,correct,wrong,"|"
	
	
	
	# Handle topic
	topic = ""
	topics = page.css("p.qotdBreadcrumb")
	topics.each do |element|
		topic << element.text.strip
		break
	end
	
	# Handle question
	question = ""
	main_body = page.css("div#mainBody")
	main_body.each do |element|
		element.css("div#qotd").children.each do |ele|
			ele.remove if ele[match] == "questionMetaContainer" or ele[match] == "qotdQuestionFooter"
		end
		question << element.inner_html
		break
	end
	
	# Handle answer
	answer = ""
	main_body2 = page.css("div#mainBody2")
	main_body2.each do |element|
		element.css("div#qotd2").children.each do |ele|
			ele.remove if ele[match] == "questionMetaContainer2"
		end
		answer << element.inner_html
		break
	end
	
	return [topic,question,answer]
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
		days[index] = %{https://sat.collegeboard.org/practice/sat-question-of-the-day?questionId=#{DateTime.parse(data.to_s).strftime("%Y%m%d")}}
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

=begin
puts "#########################################"
puts "#       CollegeBoard QotD Fetcher       #"
puts "#########################################"
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
count = 1

# Open relevant files
open(prefix + ".txt","w+") do |output|
	open(prefix + "-answers.txt","w+") do |output2|
		# Fetches questions from database or the Internet
		if not persist
			puts "Fetching..."
			questions = fetch_pages(generate_pages(start,stop))
			# Reject Mathematics questions, since they contain pictures.
			questions = questions.reject { |data| data[0].match("Mathematics") }
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
		# Parse questions into text
		questions.each_with_index do |data,index|
			output.puts(%{:-- Question #{count} / #{data[0]}\n})
			output.puts data[1] + "\n\n" + data[2] + "\n---"
			output.puts data[3],data[4],data[5],data[6],data[7],"---","\n"
			output2.puts(%{:-- Question #{count}})
			output2.puts(%{Answer: \n#{data[8]}},"\n")
			count += 1
		end
		output2.flush
	end
	output.flush
end
puts "Export complete!"
puts %{Exported #{count-1} questions!}
=end
driver = Selenium::WebDriver.for :firefox
topic,question,answer = *handle_page(fetch_page(driver,"https://sat.collegeboard.org/practice/sat-question-of-the-day"))
print %{<head><meta charset="UTF-8"></head>}
print topic
print question.encode("utf-8")
print answer.encode("utf-8")
driver.close
driver.quit
