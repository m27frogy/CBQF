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

require "pdfkit"

module CBQF
	module Export
		# :category: Page Exporting
		STARTING_XHTML = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n\t\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">\n\t<head>\n\t\t<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"/>\n\t\t<title>title</title>\n\t</head>\n\t<body>" \
		.encode("utf-8").freeze
		ENDING_XHTML = "\n\t</body>\n</html>".encode("utf-8").freeze
		
		IMG_REGEX, IMG_MATCH = /<img(.+?)>/.freeze,"<img\\1 />".freeze
		INPUT_REGEX, INPUT_MATCH = /<input(.+?)>/.freeze, "<input\\1 />".freeze
		CHECKED_REGEX, CHECKED_MATCH = / checked /.freeze," checked=\"checked\" ".freeze
		
		# Fix img tags in XHTML
		private_class_method
		def self.fix_tags(s)
			s.gsub(CBQF::Export::IMG_REGEX, CBQF::Export::IMG_MATCH)
			.gsub(CBQF::Export::INPUT_REGEX, CBQF::Export::INPUT_MATCH)
			.gsub(CBQF::Export::CHECKED_REGEX, CBQF::Export::CHECKED_MATCH)
		end
		
		public
		# Create XHMTL 1 Strict pages from fetched pages
		def self.xhtml(pages)
			#--
			xhtml_doc_q = "".encode("utf-8")
			xhtml_doc_a = "".encode("utf-8")
			
			xhtml_doc_q += CBQF::Export::STARTING_XHTML
			xhtml_doc_a += CBQF::Export::STARTING_XHTML
			count = 1
			pages.each do |page_data|
				# Declare basic values
				section = "".encode("utf-8")
				topic,question,answer,total,correct,wrong = *page_data
				
				################################################
				# Add title
				section += "<h2>Question ##{count}</h2>\n<h4>#{topic}</h4>\n<p><br /></p>".encode("utf-8")
				# Add question
				section += self.fix_tags(question.encode("utf-8"))
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
				section += self.fix_tags(answer.encode("utf-8"))
				# Add line
				section += "\n<p><br /></p>\n<hr />\n"
				
				# Push to answer document
				#xhtml_doc_a += parse_img_uri(section)
				if block_given? then
					xhtml_doc_a += (yield(section))
				else
					xhtml_doc_a += section
				end
				################################################
				
				# Iterate count
				puts "Parsed ##{count}"
				count += 1
			end
			xhtml_doc_q += CBQF::Export::ENDING_XHTML
			xhtml_doc_a += CBQF::Export::ENDING_XHTML
			
			#++
			return xhtml_doc_q,xhtml_doc_a
		end
		
		# Export XHTML sheets into paths.
		def self.pdf(xhtml_q, qpath, xhtml_a, apath)
			# Export question pdf
			kit = PDFKit.new(xhtml_q, :page_size => "Letter",
				:disable_smart_shrinking => true, :no_pdf_compression => true)
			puts kit.options
			kit.to_pdf qpath
			
			kit = PDFKit.new(xhtml_a, :page_size => "Letter",
				:disable_smart_shrinking => true, :no_pdf_compression => true)
			kit.to_pdf apath
			
			nil
		end
	end
end
