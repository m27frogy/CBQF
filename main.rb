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
				raise ArgumentError, %{Instance variable "@#{var} not defined"}
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

#  Word-wraps strings
def wrap(s,width=78)
	s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n").strip
end

# Uses Nokogiri to parse the provided page into the information needed
def handle_page(source)
	# Initialize parsing object
	page = Nokogiri::HTML(source)
	
	# I apologize for this extremely ugly code here, but the docs are rather obtuse
	# about how exactly the css function handles singular objects.  So I decided
	# to be on the safe side.
	
	# Handle topic
	topic = ""
	elementsTopic = page.css("div.floatLeft.qotdLeftCol>p")
	if elementsTopic.kind_of?(Nokogiri::XML::NodeSet) or elementsTopic.kind_of?(Array)
		elementsTopic.each do |element|
			topic << element.text.strip
			break
		end
	elsif elementsTopic.kind_of? Nokogiri::XML::Element
		topic << elementsTopic.text
	end
	topic.chomp!
	
	# Handle question
	questionInstructions,question = "",""
	
	elementsQuestion = page.css("div.questionStem>p")
	if elementsQuestion.kind_of?(Nokogiri::XML::NodeSet) or elementsQuestion.kind_of?(Array)
		elementsQuestion.each do |element|
			if questionInstructions == ""
				questionInstructions = wrap(element.text.gsub("\n",""))
			else
				question = wrap(element.text.gsub("\n","") + "\n\n")
			end
		end
	end
	
	# Handle Choices
	choiceA,choiceB,choiceC,choiceD,choiceE = ""
	# Fetch the choices with some help
	elementsChoices = page.css("label").select {|element| element["for"][0,11] == "qotdChoices"}
	if elementsChoices.kind_of?(Nokogiri::XML::NodeSet) or elementsChoices.kind_of?(Array)
		elementsChoices.each do |element|
			# Handle each element accordingly
			case element["for"][11,1]
			when "A"
				choiceA = wrap element.text.strip
			when "B"
				choiceB = wrap element.text.strip
			when "C"
				choiceC = wrap element.text.strip
			when "D"
				choiceD = wrap element.text.strip
			when "E"
				choiceE = wrap element.text.strip
			end
		end
	end
	
	# Handle answer
	answer = ""
	
	elementsAnswer = page.css("div#qotdExplDesc>p")
	if elementsAnswer.kind_of?(Nokogiri::XML::NodeSet) or elementsAnswer.kind_of?(Array)
		elementsAnswer.each do |element|
			if element["id"] != "qotdExplDescP1" then
				answer << element.text
			end
		end
	elsif elementsAnswer.kind_of? Nokogiri::XML::Element
		answer << elementsAnswer.text
	end
	answer = wrap answer
	
	return [topic,questionInstructions,question,choiceA,choiceB,choiceC,choiceD,choiceE,answer]
end

# Fetch singlular page contents
def fetch_page(driver,page)
	# Make positive that the page is actually a string
	unless page.kind_of? String
		raise ArgumentError, "Page must be a string"
	end
	
	# Go to page
	driver.navigate.to(page)
	
	# Find and click on qotdChoicesA
	qotdChoicesA = driver.find_element(:id, "qotdChoicesA")
	qotdChoicesA.click
	
	# Find and click on submit button
	qotdSubmit = driver.find_element(:id, "qotdSubmit")
	qotdSubmit.click
	
	begin
		# Find and click on the qotdShowAnswer button
		qotdShowAnswer = driver.find_element(:id,"qotdShowAnswer")
		qotdShowAnswer.click
	rescue
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
			questions = questions.reject { |data| data[0].match("Mathematics") }
			puts "Writing database..."
			generate_database(questions)
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
