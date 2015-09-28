#!/usr/bin/env ruby
# encoding: utf-8

#--
########################################################################
# CollegeBoard QotD Fetcher
#
# CollegeBoard, SAT, and PSAT/NMSQT are registered trademarks of
# The College Board and National Merit Corporation and do not
# endorse this software.
#
#
# Copyright (c) 2015, m27frogy <m27frogy.roblox@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
########################################################################


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

module CBQF
	WEBSITE_URI = "https://sat.collegeboard.org".freeze
	BASE_PAGE_URI = "#{WEBSITE_URI}/practice/sat-question-of-the-day?questionId=".freeze
end

# Required internal libraries
require "date"
# Required personal libraries
require_relative "./lib/parse"
require_relative "./lib/export"
require_relative "./lib/img"
require_relative "./lib/fetch"
require_relative "./lib/db"


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
	questions = CBQF::Fetch.pages(CBQF::Fetch.generate_pages(start,stop)) { |page|
		CBQF::Parse.page page
	}
			
	if File.file? "data.db"
		print "Overwrite pre-existing database (T/F): "
		overwrite = gets.chomp
		if overwrite.downcase[0,1] == "t"
			puts "Writing database..."
			CBQF::DB.export questions
		else
			puts "Skipping overwrite..."
		end
	else	
		puts "Writing database..."
		CBQF::DB.export questions
	end
else
	questions = CBQF::DB.import
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
xhtml_q,xhtml_a = CBQF::Export.xhtml(questions)
CBQF::Export.pdf(xhtml_q, prefix + ".pdf", xhtml_a, prefix + "-answers.pdf")
		
puts "Export complete!"
puts %{Exported #{questions.length} questions!}
