require 'date'
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone_number)
  phone_number.gsub!(/[()\-,. ]/, '')

  if phone_number.length == 11 && phone_number[0] == '1'
    phone_number.slice!(0)
  elsif phone_number.length > 10 || phone_number.length < 10
    phone_number = nil
  else
    phone_number
  end

  puts phone_number
end

puts 'EventManager initialized.'

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours = Array.new
days = Array.new

day_symbols = { 0 => "sunday", 1 => "monday", 2 => "tuesday",
                3 => "wednesday", 4 => "thursday", 5 => "friday", 
                6 => "saturday"}

contents.each do |row|
  regDate = DateTime.strptime(row[:regdate],"%m/%d/%y %H:%M")

  id = row[0]
  name = row[:first_name]
  hours.push(regDate.hour)
  days.push(regDate.wday)
  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  
  save_thank_you_letter(id,form_letter)
end

puts "\nThe most common hour of registration is: #{hours.max_by {|a| hours.count(a)}}:00"
puts "\nThe most common registration day is: #{day_symbols[days.max_by {|a| days.count(a)}]}"