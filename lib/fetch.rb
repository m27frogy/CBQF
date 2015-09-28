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
#++

require "selenium-webdriver"
require "date"

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

module CBQF
	module Fetch
		# :category: Fetch Pages
		# Fetch singlular page contents
		def self.page(driver,page)
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

		# Fetch each page individually (and process that if block given) and return contents
		def self.pages(pages)
			# Check that pages are a compatible object
			pages.must_support :each
			
			# Initialize returned array
			npages = []
			
			# Initialize Selenium::WebDriver::Driver object
			driver = Selenium::WebDriver.for :firefox
			
			# Iterate through pages
			pages.each { |page|
				if block_given? then
					npages << (yield CBQF::Fetch.page(driver,page))
				else
					npages << CBQF::Fetch.page(driver,page)
				end
			}
			
			# Cleanup
			driver.close
			driver.quit
			
			# Out of habit and charity, I leave the mostly useless return call here.
			return npages
		end
		
		# Creates a table filled with dates between today and a date
		def self.generate_pages(date,final=Date.today)
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
	end
end
