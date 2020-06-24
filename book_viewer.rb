require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "sinatra/reloader" if development?

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  # map with index and add index to each paragraph as an id to set the link element
  def in_paragraph(text)
    text.split("\n\n").map.with_index { |para, index| "<p id=#{index}>#{para}</p>" }.join
  end

  def bold(paragraph, query)
    # takes a given string of text and returns the string with <strong> attribute around the query
    paragraph.gsub(query, "<strong>#{query}</strong>")
  end
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]
  
  redirect "/" unless (1..@contents.size).cover? number
  
  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read "data/chp#{number}.txt"

  erb :chapter  
end

# Calls the block for each chapter, passing that chapter's number, name, and
# contents.
def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read "data/chp#{number}.txt"
    yield number, name, contents
  end
end

# This method returns an Array of Hashes representing chapters that match the
# specified query. Each Hash contain values for its :name and :number keys.
def chapters_matching(query)
  results = []

  return results unless query

  each_chapter do |number, name, contents|
    matches = {}
    contents.split("\n\n").each_with_index do |para, index|
      matches[index] = para if para.include? query
    end
    results << { number: number, name: name, paragraphs: matches } if matches.any?
  end

  results
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end

not_found do
  redirect "/"
end

