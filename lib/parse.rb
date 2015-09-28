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

require "nokogiri"

module CBQF
	module Parse
		# :category: Page Parsing
		WRAP_MATCH = "\\1\n".freeze
		
		public
		
		#  Word-wraps strings
		def self.wrap(s,width=78)
			s.gsub(/(.{1,#{width}})(\s+|\Z)/, CBQF::Parse::WRAP_MATCH).strip
		end
		
		# Uses Nokogiri to parse the provided page and divide it into questions and answers
		def self.page(source)
			#--
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
			
			#++
			return [topic,question,answer,total,correct,wrong]
		end
	end
end
